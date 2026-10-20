"""Keep mandatory authentication intact when adding optional keyring integration."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('keyring_login', Path(__file__).resolve().parents[1]/'scripts/setup-keyring-login.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class KeyringLogin(unittest.TestCase):
    def test_required_rules_preserved_and_optional_hooks_in_correct_phases(self):
        original = ('#%PAM-1.0\nauth required pam_securetty.so\n'
                    'auth requisite pam_nologin.so\nauth include system-local-login\n'
                    'account include system-local-login\nsession required pam_systemd.so\n')
        result = module.configured(original)
        self.assertEqual([s for s in result.splitlines() if 'pam_gnome_keyring.so' not in s], original.splitlines())
        self.assertLess(result.index('auth       optional'), result.index('account include'))
        self.assertIn('session    optional     pam_gnome_keyring.so auto_start', result)
        self.assertNotIn('sufficient', result)

    def test_repeated_setup_does_not_duplicate_hooks_or_alter_existing_options(self):
        original = '# comment\nauth include system-local-login\nsession include system-local-login\n'
        once = module.configured(original)
        self.assertEqual(module.configured(once), once)
        existing = once.replace('pam_gnome_keyring.so\n', 'pam_gnome_keyring.so only_if=greetd\n')
        self.assertEqual(module.configured(existing), existing)


if __name__ == '__main__':
    unittest.main()
