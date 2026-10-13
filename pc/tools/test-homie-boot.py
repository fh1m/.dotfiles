#!/usr/bin/python3
"""Safety checks for menu generation and exact Windows firmware selection."""
import importlib.util
from pathlib import Path
import unittest
from unittest import mock
import runpy
import subprocess


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


menu = load('homie-boot-menu')
windows = load('homie-boot-windows')
order = load('homie-boot-order')


class BootTests(unittest.TestCase):
    def setUp(self):
        self.source = f'''/+CachyOS
//linux-cachyos
protocol: linux
path: boot():/kernel#hash
module_path: boot():/initramfs#hash
cmdline: rootflags=subvol=/@ root=UUID={menu.ROOT}
//linux-cachyos-lts
protocol: linux
path: boot():/lts
//Snapshots
///fixture
////linux-cachyos
protocol: linux
path: boot():/old
/Old Windows
protocol: efi
path: guid(old):/bad.efi
'''
        self.disk = dict(serial=windows.SERIAL, size=256060514304,
                         children=[dict(name='sdc1', partuuid=windows.ESP, fstype='vfat')])
        self.firmware = f'Boot0005* Windows Boot Manager HD(1,GPT,{windows.ESP},0x800,0x64000)/\\EFI\\Microsoft\\Boot\\bootmgfw.efi'

    def test_menu_three_roots_and_preserved_recovery(self):
        result = menu.render(self.source)
        roots = [line for line in result.splitlines() if line.startswith('/') and not line.startswith('//')]
        self.assertEqual(roots, ['/Linux', '/Windows', '/Misc'])
        self.assertIn('////linux-cachyos', result)
        self.assertIn('//Linux LTS', result)
        self.assertIn('path: boot():/old', result)
        self.assertNotIn('guid(old)', result)
        self.assertEqual(result, menu.render(self.source))

    def test_missing_or_wrong_linux_root_rejected(self):
        for source in [self.source.replace(menu.ROOT, 'foreign-root'), self.source.replace('module_path:', 'missing:')]:
            with self.assertRaises(ValueError):
                menu.render(source)

    def test_exact_target_ignores_old_windows_and_tracks_boot_number(self):
        old = self.firmware.replace(windows.ESP, 'old-efi').replace('0005', '0003')
        self.assertEqual(windows.target([self.disk], old + '\n' + self.firmware), ('0005', 'sdc1'))
        self.assertEqual(windows.target([self.disk], self.firmware.replace('0005', '001A'))[0], '001A')

    def test_missing_duplicate_inactive_or_foreign_target_rejected(self):
        for firmware in ['', self.firmware + '\n' + self.firmware, self.firmware.replace('*', ' '), self.firmware.replace(windows.ESP, 'old-efi')]:
            with self.assertRaises(ValueError):
                windows.target([self.disk], firmware)
        with self.assertRaises(ValueError):
            windows.target([], self.firmware)
        with self.assertRaises(ValueError):
            windows.target([dict(self.disk, size=120000000000)], self.firmware)

    def test_user_cancel_never_arms_or_reboots(self):
        wrapper = Path(__file__).parents[1] / 'home/.local/bin/sensei-boot-windows'
        with mock.patch('subprocess.run', return_value=subprocess.CompletedProcess([], 1)) as call:
            with self.assertRaises(SystemExit) as stopped:
                runpy.run_path(str(wrapper), run_name='__main__')
            self.assertEqual(stopped.exception.code, 0)
            self.assertEqual(call.call_count, 1)
            self.assertEqual(call.call_args.args[0][0], 'zenity')

    def test_reboot_failure_attempts_cancel_and_reports_failed_cleanup(self):
        wrapper = Path(__file__).parents[1] / 'home/.local/bin/sensei-boot-windows'
        for cancel_result in [0, 1]:
            results = [subprocess.CompletedProcess([], code, stdout='', stderr='')
                       for code in [0, 0, 1, cancel_result, 0]]
            with self.subTest(cancel_result=cancel_result), mock.patch('subprocess.run', side_effect=results) as call:
                with self.assertRaises(SystemExit) as stopped:
                    runpy.run_path(str(wrapper), run_name='__main__')
                self.assertEqual(stopped.exception.code, 1)
                self.assertEqual(call.call_args_list[3].args[0][-1], 'cancel')
                error = call.call_args_list[4].args[0][-1]
                self.assertIn('may still be armed' if cancel_result else 'was cleared', error)

    def test_order_drift_repair_tracks_ids_and_preserves_unknown_and_bootnext(self):
        firmware = f'''BootNext: 0001
BootOrder: 0007,0001,0000,0002,0009
Boot0007* Windows Boot Manager HD(1,GPT,{order.OLD_ESP},0,0)/\\EFI\\MICROSOFT\\BOOT\\BOOTMGFW.EFI
Boot0001* Windows Boot Manager HD(1,GPT,{order.WINDOWS_ESP},0,0)/\\EFI\\MICROSOFT\\BOOT\\BOOTMGFW.EFI
Boot0000* Limine HD(1,GPT,{order.LINUX_ESP},0,0)/\\EFI\\LIMINE\\LIMINE_X64.EFI
Boot0002* Recovery HD(1,GPT,{order.LINUX_ESP},0,0)/\\EFI\\BOOT\\BOOTX64.EFI
Boot0009* Other recovery target
'''
        self.assertEqual(order.plan(firmware)[1], ['0000', '0001', '0002', '0009'])
        with self.assertRaises(ValueError):
            order.plan(firmware.replace(order.WINDOWS_ESP, 'foreign'))


if __name__ == '__main__':
    unittest.main()
