import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ToolchainPolicyTests(unittest.TestCase):
    def test_toolchain_policy_declares_supported_baseline(self):
        policy = json.loads((ROOT / 'config/toolchains.json').read_text(encoding='utf-8'))
        self.assertEqual(policy['policy']['cpp_standard'], 'C++20')
        self.assertEqual(policy['policy']['qt_preferred_major'], 5)
        self.assertEqual(policy['policy']['qt_preferred_version'], '5.12.12')
        self.assertFalse(policy['policy']['qt6_auto_install'])
        profiles = {item['id']: item for item in policy['profiles']}
        self.assertIn('msvc', profiles['qt5-msvc']['required'])
        self.assertIn('windows-sdk', profiles['qt5-msvc']['required'])
        self.assertIn('mingw', profiles['qt5-mingw']['required'])
        self.assertIn('cmake', profiles['qt5-mingw']['required'])
        self.assertIn('xmake', profiles['qt5-msvc']['required'])

    def test_inventory_script_is_read_only_and_has_both_profiles(self):
        script = (ROOT / 'scripts/Manage-Toolchain.ps1').read_text(encoding='utf-8')
        self.assertIn("[ValidateSet('Check','Export')]", script)
        self.assertIn("vswhere.exe", script)
        self.assertIn("qmake", script)
        self.assertIn("OpenCVConfig.cmake", script)
        self.assertIn("-like '17.*'", script)
        self.assertIn("QMAKE_XSPEC", script)
        self.assertIn("CompatibilityWarnings", script)
        self.assertIn("if (-not $IsWindows)", script)
        self.assertNotIn("winget install", script.lower())
        self.assertNotIn("Remove-Item", script)

    def test_offline_preparation_exports_inventory_before_checksum_manifest(self):
        script = (ROOT / 'scripts/Prepare-Offline.ps1').read_text(encoding='utf-8')
        self.assertIn("Manage-Toolchain.ps1", script)
        self.assertIn("toolchain-inventory.json", script)
        self.assertLess(script.index("toolchain-inventory.json"), script.index("SHA256SUMS.csv"))

    def test_proprietary_sdks_are_not_managed_or_copied(self):
        policy = json.loads((ROOT / 'config/toolchains.json').read_text(encoding='utf-8'))
        excluded = ' '.join(policy['not_managed']).lower()
        self.assertIn('halcon', excluded)
        self.assertIn('license', excluded)
        self.assertIn('vendor sdk', excluded)


if __name__ == '__main__':
    unittest.main()
