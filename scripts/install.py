#!/usr/bin/env python3
"""Single installer engine. Python 3.9+, standard library only; never runs at login."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SYSTEM = platform.system()
MIN_YAZI = (26, 9, 1)


def run(args, timeout=1800, capture=False):
    """Bounded processes; Ctrl+C/timeout terminates the whole installer child tree."""
    print('+ ' + ' '.join(map(str, args)), flush=True)
    options = dict(text=True, encoding='utf-8', errors='replace')
    if capture:
        options.update(stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if os.name == 'nt':
        options['creationflags'] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        options['start_new_session'] = True
    proc = subprocess.Popen(list(map(str, args)), **options)
    try:
        out, _ = proc.communicate(timeout=timeout)
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        if os.name == 'nt':
            subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True)
        else:
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        proc.wait()
        raise
    if proc.returncode:
        raise RuntimeError('Command failed (%s): %s\n%s' % (proc.returncode, args, out or ''))
    return out or ''


def config_dir(system=SYSTEM, home=None, environ=None):
    env = os.environ if environ is None else environ
    base = Path.home() if home is None else Path(home)
    if env.get('YAZI_CONFIG_HOME'):
        return Path(env['YAZI_CONFIG_HOME']).expanduser()
    if system == 'Windows':
        if not env.get('APPDATA'):
            raise RuntimeError('APPDATA is missing.')
        return Path(env['APPDATA']) / 'yazi' / 'config'
    return Path(env.get('XDG_CONFIG_HOME', str(base / '.config'))) / 'yazi'


def refresh_path():
    paths = []
    if SYSTEM == 'Windows':
        import winreg
        for key, sub in [(winreg.HKEY_LOCAL_MACHINE, r'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'),
                         (winreg.HKEY_CURRENT_USER, r'Environment')]:
            try:
                with winreg.OpenKey(key, sub) as handle:
                    paths.extend(winreg.QueryValueEx(handle, 'Path')[0].split(';'))
            except OSError:
                pass
        for variable in ('ProgramFiles', 'LOCALAPPDATA'):
            base = Path(os.environ.get(variable, 'C:/'))
            paths.extend(str(p) for pattern in ('LibreOffice/program', '7-Zip', 'Programs/Python/Python*/', 'ImageMagick*')
                         for p in base.glob(pattern))
        paths.append(str(Path(os.environ['LOCALAPPDATA']) / 'Microsoft/WinGet/Links'))
    else:
        paths.extend([str(Path.home() / '.local/bin'), '/opt/homebrew/bin', '/usr/local/bin'])
    # Prefer persistent system/user PATH to app-bundled tools.
    os.environ['PATH'] = os.pathsep.join(dict.fromkeys(os.path.expandvars(p) for p in paths + os.environ.get('PATH', '').split(os.pathsep) if p))


def find_tool(tool):
    for name in [tool['command']] + tool.get('aliases', []):
        if name == 'convert' and SYSTEM == 'Windows':
            # Windows convert.exe changes disk filesystems; it is not ImageMagick.
            continue
        found = shutil.which(name)
        if found:
            # Codex's bundled Poppler is not a deployment dependency.
            if 'OpenAI.Codex' in found:
                continue
            return found
    if tool['command'] == 'file' and SYSTEM == 'Windows':
        path = Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/usr/bin/file.exe'
        if path.is_file():
            return str(path)
    if tool['command'] == 'soffice' and SYSTEM == 'Darwin':
        path = Path('/Applications/LibreOffice.app/Contents/MacOS/soffice')
        if path.is_file():
            return str(path)
    return None


def manager(system=SYSTEM):
    if system == 'Windows':
        if not shutil.which('winget'):
            raise RuntimeError('WinGet missing: install Microsoft App Installer first.')
        if sys.getwindowsversion().build < 19041:
            raise RuntimeError('Windows 10 build 19041 or later required.')
        return 'winget'
    if system == 'Darwin':
        if not shutil.which('brew'):
            raise RuntimeError('Homebrew missing. Install it from https://brew.sh then rerun.')
        if os.geteuid() == 0:
            raise RuntimeError('Run as your normal user; Homebrew must not run as root.')
        return 'brew'
    if system == 'Linux':
        for name in ('apt-get', 'dnf', 'pacman', 'zypper', 'apk'):
            if shutil.which(name):
                return name
    raise RuntimeError('Unsupported OS/package manager: ' + system)


def package_command(mgr, tool):
    if mgr == 'winget':
        return ['winget', 'install', '--id', tool['winget'], '--exact', '--source', 'winget',
                '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity']
    if mgr == 'brew':
        return ['brew', 'install'] + (['--cask'] if tool.get('cask') else []) + [tool['brew']]
    prefix = [] if os.geteuid() == 0 else ['sudo']
    key = 'apt' if mgr == 'apt-get' else mgr
    package = tool.get(key, tool['linux'])
    commands = {'apt-get':['apt-get', 'install', '-y'], 'dnf':['dnf', 'install', '-y'],
                'pacman':['pacman', '-S', '--needed', '--noconfirm'],
                'zypper':['zypper', '--non-interactive', 'install'], 'apk':['apk', 'add']}
    return prefix + commands[mgr] + [package]


def yazi_version():
    if not shutil.which('yazi'):
        return ()
    value = run(['yazi', '--version'], timeout=15, capture=True)
    match = re.search(r'(\d+)\.(\d+)\.(\d+)', value)
    return tuple(map(int, match.groups())) if match else ()


def install_yazi(mgr):
    if yazi_version() >= MIN_YAZI and shutil.which('ya'):
        return
    if mgr in ('winget', 'brew'):
        run(package_command(mgr, dict(winget='sxyazi.yazi', brew='yazi')))
        refresh_path()
    else:
        # Official static musl binaries work across glibc and musl distributions.
        arch = {'x86_64':'x86_64', 'amd64':'x86_64', 'aarch64':'aarch64', 'arm64':'aarch64'}.get(platform.machine().lower())
        if not arch:
            raise RuntimeError('Yazi binary unavailable for CPU: ' + platform.machine())
        url = 'https://api.github.com/repos/sxyazi/yazi/releases/tags/v26.9.1'
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'newWindowsEvn-installer'}), timeout=30) as response:
            release = json.load(response)
        name = 'yazi-' + arch + '-unknown-linux-musl.zip'
        asset = next(a for a in release['assets'] if a['name'] == name)
        digest = asset.get('digest', '')
        if not digest.startswith('sha256:'):
            raise RuntimeError('GitHub release has no SHA-256 digest; refusing unverified binary.')
        with tempfile.TemporaryDirectory(prefix='newWindowsEvn-') as tmp:
            archive = Path(tmp) / name
            with urllib.request.urlopen(asset['browser_download_url'], timeout=120) as source, archive.open('wb') as target:
                shutil.copyfileobj(source, target)
            if hashlib.sha256(archive.read_bytes()).hexdigest() != digest[7:]:
                raise RuntimeError('Yazi SHA-256 mismatch.')
            destination = Path.home() / '.local/bin'
            destination.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(archive) as bundle:
                for executable in ('yazi', 'ya'):
                    member = next(n for n in bundle.namelist() if n.endswith('/' + executable))
                    target = destination / executable
                    target.write_bytes(bundle.read(member))
                    target.chmod(0o755)
        refresh_path()
    if yazi_version() < MIN_YAZI or not shutil.which('ya'):
        raise RuntimeError('Yazi >=26.9.1 and ya are required; package manager provided an older version.')


def deploy_file(source, target, content=None):
    target = Path(target)
    data = source.read_bytes() if content is None else content.encode('utf-8')
    if target.exists() and target.read_bytes() == data:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        stamp = datetime.datetime.now().strftime('%Y%m%d%H%M%S%f')
        backup = target.with_name(target.name + '.bak.' + stamp)
        shutil.copy2(target, backup)
        print('Backup:', backup)
    target.write_bytes(data)
    print('Installed:', target)


def append_block(path, tag, lines):
    start, end = '# >>> ' + tag + ' >>>', '# <<< ' + tag + ' <<<'
    old = path.read_text(encoding='utf-8-sig') if path.exists() else ''
    block = start + '\n' + lines + '\n' + end
    pattern = re.escape(start) + r'.*?' + re.escape(end)
    value = re.sub(pattern, lambda _: block, old, flags=re.S) if start in old else old.rstrip() + '\n\n' + block + '\n'
    deploy_file(path, path, value)


def deploy(tools, offline=False):
    cfg = config_dir()
    for name in ('git', 'smart-enter', 'full-border', 'diff'):
        if not (cfg / 'plugins' / (name + '.yazi') / 'main.lua').is_file():
            if offline:
                source = ROOT / 'offline/plugins' / (name + '.yazi')
                if not (source / 'main.lua').is_file():
                    raise RuntimeError('Offline plugin missing: ' + str(source))
                shutil.copytree(source, cfg / 'plugins' / (name + '.yazi'), dirs_exist_ok=True)
            else:
                run(['ya', 'pkg', 'add', 'yazi-rs/plugins:' + name], timeout=180)
    # Copy our own portable previewer, never modified third-party source.
    plugin = cfg / 'plugins/devkit-office.yazi'
    for source in (ROOT / 'config/yazi/plugins/devkit-office.yazi').iterdir():
        if source.is_file() and source.name != 'main.lua':
            deploy_file(source, plugin / source.name)
    paths = {t['command']:find_tool(t) for t in tools}
    deploy_file(plugin / 'runtime.json', plugin / 'runtime.json', json.dumps(paths, indent=2))
    lua = (ROOT / 'config/yazi/plugins/devkit-office.yazi/main.lua').read_text(encoding='utf-8')
    lua = lua.replace('@@PYTHON@@', json.dumps(sys.executable, ensure_ascii=False)).replace('@@HELPER@@', json.dumps(str(plugin / 'preview.py'), ensure_ascii=False))
    deploy_file(plugin / 'main.lua', plugin / 'main.lua', lua)
    for name in ('yazi.toml', 'init.lua', 'keymap.toml'):
        deploy_file(ROOT / 'config/yazi' / name, cfg / name)
    if SYSTEM == 'Windows':
        os.environ['YAZI_CONFIG_HOME'] = str(cfg)
        run(['pwsh', '-NoProfile', '-File', str(ROOT / 'scripts/Install-Config.ps1'), '-Force', '-SkipYazi'])
    else:
        # Do not change the user's login shell. Install Bash/Zsh helpers only.
        shell_file = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'powershell7-dev-kit/devkit.sh'
        deploy_file(ROOT / 'config/shell/devkit.sh', shell_file)
        import shlex
        line = '. ' + shlex.quote(str(shell_file))
        for profile in (Path.home() / '.bashrc', Path.home() / '.zshrc'):
            append_block(profile, 'powershell7-dev-kit', line)
        local_bin = Path.home() / '.local/bin'
        local_bin.mkdir(parents=True, exist_ok=True)
        for name in ('bat', 'fd', 'magick'):
            found = paths.get(name)
            if found and not shutil.which(name):
                link = local_bin / name
                if not link.exists():
                    link.symlink_to(found)
    print('Configuration:', cfg)


def verify(tools):
    missing = []
    for tool in tools:
        path = find_tool(tool)
        print(('[OK] ' if path else '[MISSING] ') + tool['command'] + ': ' + (path or 'not installed'))
        if not path:
            missing.append(tool['command'])
    if yazi_version() < MIN_YAZI or not shutil.which('ya'):
        missing.append('yazi>=26.9.1 / ya')
    cfg = config_dir()
    for file in ('yazi.toml', 'init.lua', 'keymap.toml', 'plugins/devkit-office.yazi/preview.py', 'plugins/devkit-office.yazi/runtime.json'):
        if not (cfg / file).is_file():
            missing.append(str(cfg / file))
    for name in ('git', 'smart-enter', 'full-border', 'diff'):
        if not (cfg / 'plugins' / (name + '.yazi') / 'main.lua').is_file():
            missing.append('plugin ' + name)
    pdf = find_tool(next(t for t in tools if t['command'] == 'pdftoppm'))
    if pdf:
        # Poppler variants may return a nonzero usage status for -h.
        try:
            help_text = run([pdf, '-h'], timeout=15, capture=True)
        except RuntimeError as error:
            help_text = str(error)
        if '-jpeg' not in help_text:
            missing.append('Poppler JPEG support')
    if missing:
        raise RuntimeError('Deployment incomplete: ' + ', '.join(missing))
    print('PASS: common-file tools, plugins and configuration present. Test images in a graphical terminal.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='read-only verification; no installation')
    parser.add_argument('--config-only', action='store_true', help='deploy/back up configs without package installation')
    parser.add_argument('--offline', action='store_true', help='config-only; use cached plugins without network access')
    parser.add_argument('--skip-modules', action='store_true', help='skip optional PowerShell module installation')
    args = parser.parse_args()
    if sys.version_info < (3, 9):
        raise RuntimeError('Python 3.9+ required.')
    refresh_path()
    tools = json.loads((ROOT / 'config/file-tools.json').read_text(encoding='utf-8'))['tools']
    if args.check:
        verify(tools)
        return
    mgr = None if args.config_only or args.offline else manager()
    if not args.config_only and not args.offline:
        failures = []
        if mgr == 'apt-get':
            run(([] if os.geteuid() == 0 else ['sudo']) + ['apt-get', 'update'])
        for tool in tools:
            if find_tool(tool):
                print('Already present:', tool['command'])
                continue
            try:
                run(package_command(mgr, tool))
                refresh_path()
            except RuntimeError as error:
                failures.append(str(error))
        if failures:
            raise RuntimeError('Package installation failed; existing configs preserved.\n' + '\n'.join(failures))
        install_yazi(mgr)
        if SYSTEM == 'Windows':
            for command, package in [('pwsh','Microsoft.PowerShell'), ('wt','Microsoft.WindowsTerminal'),
                                      ('lazygit','JesseDuffield.lazygit'), ('xmake','Xmake-io.Xmake'), ('oh-my-posh','JanDeDobbeleer.OhMyPosh')]:
                if not shutil.which(command):
                    run(package_command(mgr, {'winget':package}))
                    refresh_path()
            if not args.skip_modules:
                run(['pwsh', '-NoProfile', '-Command', "foreach ($n in 'PSFzf','Terminal-Icons') { if (-not (Get-Module -ListAvailable $n)) { Install-Module $n -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop } }"])
    # Never replace configuration until dependencies have been verified.
    absent = [t['command'] for t in tools if not find_tool(t)]
    if absent:
        raise RuntimeError('Missing dependencies; configs untouched: ' + ', '.join(absent))
    if yazi_version() < MIN_YAZI:
        raise RuntimeError('Yazi 26.9.1+ required; configs untouched.')
    deploy(tools, offline=args.offline)
    verify(tools)
    print('Done. Reopen your terminal, run y (or yazi), then hover a file. O opens the default application.')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, StopIteration, subprocess.TimeoutExpired, KeyboardInterrupt) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        sys.exit(1)
