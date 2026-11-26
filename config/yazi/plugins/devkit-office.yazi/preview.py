"""Office/PDF -> one JPEG. Local conversion, isolated profile, bounded child processes."""
import ctypes
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile

JOB_HANDLE = None
ACTIVE = None
OFFICE = {'.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.odt', '.ods', '.odp', '.rtf'}


def windows_job():
    """Killing this helper also kills LibreOffice and its descendants on Windows."""
    global JOB_HANDLE
    if os.name != 'nt':
        return
    from ctypes import wintypes
    class Basic(ctypes.Structure):
        _fields_ = [('process_time', ctypes.c_int64), ('job_time', ctypes.c_int64), ('flags', wintypes.DWORD),
                    ('min_working', ctypes.c_size_t), ('max_working', ctypes.c_size_t),
                    ('active', wintypes.DWORD), ('affinity', ctypes.c_size_t),
                    ('priority', wintypes.DWORD), ('scheduling', wintypes.DWORD)]
    class IO(ctypes.Structure):
        _fields_ = [(name, ctypes.c_uint64) for name in ('read_ops','write_ops','other_ops','read_bytes','write_bytes','other_bytes')]
    class Extended(ctypes.Structure):
        _fields_ = [('basic', Basic), ('io', IO), ('process_memory', ctypes.c_size_t), ('job_memory', ctypes.c_size_t),
                    ('peak_process', ctypes.c_size_t), ('peak_job', ctypes.c_size_t)]
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.CreateJobObjectW.restype = wintypes.HANDLE
    kernel.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
    kernel.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD]
    kernel.GetCurrentProcess.restype = wintypes.HANDLE
    kernel.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
    JOB_HANDLE = kernel.CreateJobObjectW(None, None)
    limits = Extended()
    limits.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    if not JOB_HANDLE or not kernel.SetInformationJobObject(JOB_HANDLE, 9, ctypes.byref(limits), ctypes.sizeof(limits)):
        raise OSError('Unable to create bounded preview process job.')
    if not kernel.AssignProcessToJobObject(JOB_HANDLE, kernel.GetCurrentProcess()):
        raise OSError('Unable to isolate preview process tree.')


def stop_child():
    if ACTIVE is None or ACTIVE.poll() is not None:
        return
    if os.name == 'nt':
        subprocess.run(['taskkill', '/PID', str(ACTIVE.pid), '/T', '/F'], capture_output=True)
    else:
        try:
            os.killpg(ACTIVE.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    ACTIVE.wait()


def interrupted(signum, frame):
    stop_child()
    raise KeyboardInterrupt


def run(args, timeout=60):
    global ACTIVE
    options = dict(stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace')
    if os.name == 'nt':
        options['creationflags'] = subprocess.CREATE_NO_WINDOW
    else:
        options['start_new_session'] = True
    ACTIVE = subprocess.Popen(list(map(str, args)), **options)
    try:
        output, _ = ACTIVE.communicate(timeout=timeout)
        if ACTIVE.returncode:
            raise RuntimeError(output[-2000:])
        return output
    except (subprocess.TimeoutExpired, KeyboardInterrupt):
        stop_child()
        raise
    finally:
        ACTIVE = None


def render(source, target, page, runtime):
    source, target = Path(source).resolve(), Path(target).resolve()
    if page < 1 or not source.is_file():
        raise ValueError('Existing local file and positive page number required.')
    if source.stat().st_size > 200 * 1024 * 1024:
        raise ValueError('Preview limit: 200 MiB. Press O to open in the default application.')
    if source.suffix.lower() not in OFFICE | {'.pdf'}:
        raise ValueError('Unsupported preview type; press O to open.')
    pdftoppm = runtime.get('pdftoppm') or shutil.which('pdftoppm')
    if not pdftoppm:
        raise RuntimeError('Poppler missing; rerun the installer.')
    with tempfile.TemporaryDirectory(prefix='devkit-preview-') as folder:
        temp = Path(folder)
        pdf = source
        if source.suffix.lower() != '.pdf':
            soffice = runtime.get('soffice') or shutil.which('soffice')
            if not soffice:
                raise RuntimeError('LibreOffice missing; rerun the installer.')
            profile = temp / 'profile'
            (profile / 'user').mkdir(parents=True)
            (profile / 'user/registrymodifications.xcu').write_text(
                '<?xml version="1.0" encoding="UTF-8"?><oor:items xmlns:oor="http://openoffice.org/2001/registry">'
                '<item oor:path="/org.openoffice.Office.Common/Security/Scripting">'
                '<prop oor:name="MacroSecurityLevel" oor:op="fuse"><value>3</value></prop></item></oor:items>', encoding='utf-8')
            run([soffice, '-env:UserInstallation=' + profile.as_uri(), '--headless', '--nologo', '--nodefault',
                 '--nofirststartwizard', '--convert-to', 'pdf', '--outdir', temp, source])
            pdf = temp / (source.stem + '.pdf')
            if not pdf.is_file():
                raise RuntimeError('Office conversion failed (encrypted/unsupported document). Press O to open.')
        info = Path(pdftoppm).with_name('pdfinfo.exe' if os.name == 'nt' else 'pdfinfo')
        if not info.is_file():
            info = shutil.which('pdfinfo')
        if info:
            output = run([info, pdf], timeout=15)
            match = re.search(r'^Pages:\s+(\d+)', output, flags=re.M)
            if match and page > int(match.group(1)):
                return int(match.group(1))
        output_base = temp / 'page'
        run([pdftoppm, '-f', page, '-l', page, '-singlefile', '-scale-to', '1600', '-jpeg', pdf, output_base], timeout=30)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(output_base.with_suffix('.jpg'), target)
    return None


def main():
    windows_job()
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    runtime = json.loads(Path(__file__).with_name('runtime.json').read_text(encoding='utf-8'))
    bound = render(sys.argv[1], sys.argv[2], int(sys.argv[3]), runtime)
    if bound:
        print('BOUND:' + str(bound))


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired, KeyboardInterrupt) as error:
        print('Preview failed: ' + str(error), file=sys.stderr)
        sys.exit(1)
