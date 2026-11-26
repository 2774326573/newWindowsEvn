import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'scripts/install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerTests(unittest.TestCase):
    def test_config_paths_and_overrides(self):
        self.assertEqual(installer.config_dir('Windows', '/home/test', {'APPDATA':'/app'}), Path('/app/yazi/config'))
        self.assertEqual(installer.config_dir('Linux', '/home/test', {}), Path('/home/test/.config/yazi'))
        self.assertEqual(installer.config_dir('Darwin', '/home/test', {'XDG_CONFIG_HOME':'/custom'}), Path('/custom/yazi'))
        self.assertEqual(installer.config_dir('Windows', '/home/test', {'YAZI_CONFIG_HOME':'/override'}), Path('/override'))

    def test_changed_file_backup_and_idempotence(self):
        with tempfile.TemporaryDirectory() as temp:
            source, target = Path(temp) / 'source', Path(temp) / 'target'
            source.write_text('new')
            target.write_text('user setting')
            installer.deploy_file(source, target)
            backups = list(Path(temp).glob('target.bak.*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), 'user setting')
            installer.deploy_file(source, target)
            self.assertEqual(len(list(Path(temp).glob('target.bak.*'))), 1)

    def test_profile_block_preserves_custom_content(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / 'profile'
            target.write_text('export CUSTOM=1\n')
            installer.append_block(target, 'devkit', 'first')
            installer.append_block(target, 'devkit', 'second')
            value = target.read_text()
            self.assertIn('export CUSTOM=1', value)
            self.assertEqual(value.count('# >>> devkit >>>'), 1)
            self.assertIn('second', value)
            self.assertNotIn('first', value)

    def test_package_manager_mappings(self):
        tools = json.loads((ROOT / 'config/file-tools.json').read_text())['tools']
        with patch.object(os, 'geteuid', return_value=1000, create=True):
            for manager in ('winget','brew','apt-get','dnf','pacman','zypper','apk'):
                for tool in tools:
                    cmd = installer.package_command(manager, tool)
                    self.assertTrue(all(isinstance(arg, str) and arg for arg in cmd))
                    if manager not in ('winget','brew'):
                        self.assertEqual(cmd[0], 'sudo')
            fd = next(t for t in tools if t['command'] == 'fd')
            self.assertEqual(installer.package_command('apt-get', fd)[-1], 'fd-find')
            self.assertEqual(installer.package_command('pacman', fd)[-1], 'fd')

    def test_unknown_manager_fails(self):
        with patch.object(installer.shutil, 'which', return_value=None):
            with self.assertRaises(RuntimeError):
                installer.manager('Linux')
            with self.assertRaises(RuntimeError):
                installer.manager('Plan9')

    def test_windows_does_not_mistake_disk_convert_for_imagemagick(self):
        with patch.object(installer, 'SYSTEM', 'Windows'), patch.object(installer.shutil, 'which', side_effect=lambda x: 'C:/Windows/System32/convert.exe' if x == 'convert' else None):
            self.assertIsNone(installer.find_tool({'command':'magick', 'aliases':['convert']}))

    def test_offline_cache_covers_windows_file_tools(self):
        packages = (ROOT / 'config/packages.txt').read_text().splitlines()
        for tool in json.loads((ROOT / 'config/file-tools.json').read_text())['tools']:
            self.assertIn(tool['winget'], packages)

    def test_template_paths_are_not_machine_specific(self):
        lua = (ROOT / 'config/yazi/plugins/devkit-office.yazi/main.lua').read_text()
        self.assertIn('@@PYTHON@@', lua)
        self.assertIn('@@HELPER@@', lua)
        self.assertNotIn('C:\\Users', lua)


if __name__ == '__main__':
    unittest.main()
