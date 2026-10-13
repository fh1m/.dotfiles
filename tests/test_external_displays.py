"""HDMI mode choice, shared workspaces and honest hardware brightness."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]

def module():
    loader=importlib.machinery.SourceFileLoader('external_displays',str(ROOT/'home/.local/bin/sensei-displays'))
    spec=importlib.util.spec_from_loader(loader.name,loader);m=importlib.util.module_from_spec(spec);loader.exec_module(m);return m


def screen(name,ws,focused=False):return {'id':{'eDP-1':0,'DP-2':1,'HDMI-A-1':2}.get(name,3),'name':name,'activeWorkspace':{'id':ws},'focused':focused,'width':1920,'height':1080,'scale':1,'x':-1920,'y':0}


class ExternalDisplays(unittest.TestCase):
    def test_workspace_does_not_wait_for_ddc_state_lock(self):
        m=module()
        with patch.object(m.sys,'argv',['sensei-displays','workspace','3']),patch.object(m,'workspace') as focus,patch.object(m.fcntl,'flock') as lock:
            m.main();focus.assert_called_once_with(3,None);lock.assert_called_once()

    def test_highest_resolution_then_fastest_supported_rate(self):
        m=module();monitor=screen('HDMI-A-1',6)
        monitor['availableModes']=['1920x1080@60.00Hz','1280x720@120.00Hz','1920x1080@74.97Hz','malformed']
        self.assertEqual(m.optimal_mode(monitor),('1920x1080@74.97',1920,1080,74.97))

    def test_native_layout_is_idempotent_and_4k_uses_integer_scaling(self):
        m=module();monitor=screen('HDMI-A-1',6)
        monitor.update(refreshRate=74.973,availableModes=['1920x1080@74.97Hz'])
        with patch.object(m,'run') as run:
            m.configure([monitor]);run.assert_not_called()
            monitor.update(availableModes=['3840x2160@60.00Hz'])
            m.configure([monitor]);expression=run.call_args.args[0][-1]
            self.assertIn('mode="3840x2160@60"',expression)
            self.assertIn('scale=2',expression)
            self.assertIn('position="-1920x0"',expression)

    def test_state_exposes_actual_mode_not_an_advertised_mode(self):
        m=module();monitor=screen('HDMI-A-1',6)
        monitor.update(refreshRate=74.973,currentFormat='XRGB8888')
        with patch.object(m,'read_state',return_value={}),patch.object(m,'connected',return_value={'HDMI-A-1':{'id':'fixture'}}),patch.object(m,'monitors',return_value=[monitor]),patch.object(m,'run',return_value=''),patch.object(m,'write_state'):
            record=m.sync(layout=False,notify=False)['displays'][0]
            self.assertEqual((record['width'],record['height'],record['scale']),(1920,1080,1))
            self.assertEqual(record['refresh'],74.973)
            self.assertEqual(record['format'],'XRGB8888')
            self.assertFalse(record['ready'])

    def test_ddc_ignores_internal_and_invalid_displays(self):
        m=module();text='Display 1\n   I2C bus: /dev/i2c-1\n   DRM connector: card1-HDMI-A-1\nInvalid display\n   I2C bus: /dev/i2c-12\n   DRM connector: card2-DP-2\n'
        self.assertEqual(m.ddc_devices(text),{'HDMI-A-1':1})

    def test_brightness_uses_reported_maximum(self):
        m=module()
        with patch.object(m,'run',return_value='VCP 10 C 100 200\n'):
            self.assertEqual(m.brightness(1)['level'],50)
        with patch.object(m,'run',return_value='VCP 10 ERR\n'):
            with self.assertRaises(ValueError):m.brightness(1)

    def test_workspace_switches_both_halves_and_preserves_invoking_monitor(self):
        m=module();outputs=[screen('eDP-1',1),screen('HDMI-A-1',101,True),screen('DP-2',7)]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'dispatch') as dsp:
            m.workspace(3,'HDMI-A-1')
            command=dsp.call_args.args[0]
            self.assertIn('workspace="3"',command);self.assertIn('workspace="103"',command)
            self.assertNotIn('swap_monitors',command)
            self.assertTrue(command.endswith('return hl.dsp.focus({monitor="HDMI-A-1"}) end)()'))
            dsp.assert_called_once()
            dsp.reset_mock();m.workspace(7,'HDMI-A-1')
            dsp.assert_called_once_with('hl.dsp.focus({workspace="7"})')

    def test_logical_identity_is_shared_but_physical_workspaces_are_distinct(self):
        m=module()
        for n in range(1,7):
            self.assertEqual(m.logical(m.physical(n,'HDMI-A-1')),n)
            self.assertEqual(m.physical(n,'eDP-1'),n)
        for n in (7,8,100,107,-98):self.assertEqual(m.logical(n),n)
        self.assertEqual(m.physical(7,'HDMI-A-1'),7)

    def test_aligned_workspace_reconciliation_does_not_dispatch(self):
        m=module();outputs=[screen('eDP-1',3),screen('HDMI-A-1',103,True),screen('DP-2',7)]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'clients',return_value=[]),patch.object(m,'dispatch') as dsp:
            m.reconcile();dsp.assert_not_called()

    def test_focus_of_window_in_other_workspace_aligns_both_screens(self):
        m=module();outputs=[screen('eDP-1',1),screen('HDMI-A-1',103,True)]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'clients',return_value=[]),patch.object(m,'workspace') as change:
            m.reconcile();change.assert_called_once_with(3,'HDMI-A-1')

    def test_unplug_recovers_external_half_without_restarting_windows(self):
        m=module();outputs=[screen('eDP-1',1,True),screen('DP-2',7)]
        windows=[{'address':'0xabc','workspace':{'id':103},'monitor':0}]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'clients',return_value=windows),patch.object(m,'dispatch') as dsp:
            m.reconcile();dsp.assert_called_once_with('hl.dsp.window.move({window="address:0xabc",workspace="3",follow=false})')

    def test_adopts_existing_external_window_preserving_subject(self):
        m=module();outputs=[screen('eDP-1',1),screen('HDMI-A-1',1,True)]
        windows=[{'address':'0xabc','workspace':{'id':1},'monitor':2}]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'clients',return_value=windows),patch.object(m,'workspace'),patch.object(m,'dispatch') as dsp:
            m.reconcile();dsp.assert_called_once_with('hl.dsp.window.move({window="address:0xabc",workspace="101",follow=false})')

    def test_duplicate_default_names_migrate_but_custom_names_survive(self):
        m=module();outputs=[screen('eDP-1',1),screen('HDMI-A-1',101,True)]
        records=[{'id':101,'name':'Terminal'},{'id':103,'name':'My research'}]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'clients',return_value=[]),patch.object(m,'known_workspaces',return_value=records),patch.object(m,'dispatch') as dsp:
            m.reconcile();dsp.assert_called_once()
            self.assertIn('workspace="101"',dsp.call_args.args[0]);self.assertIn('External',dsp.call_args.args[0])

    def test_workspace_move_keeps_window_on_its_current_display(self):
        m=module();outputs=[screen('eDP-1',1),screen('HDMI-A-1',101,True)]
        windows=[{'address':'0xabc','workspace':{'id':101},'monitor':2}]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'clients',return_value=windows),patch.object(m,'dispatch') as dsp:
            m.move_window(3,'0xabc');dsp.assert_called_once_with('hl.dsp.window.move({window="address:0xabc",workspace="103",follow=false})')

    def test_replaced_monitor_rechecks_identity_before_write(self):
        m=module();old={'output':'HDMI-A-1','id':'old','ready':True,'bus':1,'maximum':100}
        new=dict(old,id='new',bus=2)
        with patch.object(m,'read_state',return_value={'displays':[old]}),patch.object(m,'connected',return_value={'HDMI-A-1':{'id':'new'}}),patch.object(m,'sync',return_value={'displays':[new]}) as sync,patch.object(m,'run') as run,patch.object(m,'brightness',return_value={'raw':60,'maximum':100,'level':60}),patch.object(m,'write_state'):
            m.set_brightness('HDMI-A-1',60)
            sync.assert_called_once();self.assertEqual(run.call_args.args[0],['ddcutil','--bus','2','setvcp','10','60'])
            with self.assertRaises(ValueError):m.set_brightness('HDMI-A-1',float('nan'))

    def test_only_topology_changes_notify_not_refreshes(self):
        m=module();old={'outputs':['HDMI-A-1'],'displays':[],'session':'fixture'}
        with patch.dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE='fixture'),patch.object(m,'read_state',return_value=old),patch.object(m,'connected',return_value={}),patch.object(m,'monitors',return_value=[screen('HDMI-A-1',6)]),patch.object(m,'write_state'),patch.object(m.subprocess,'run') as notify:
            m.sync(layout=False);notify.assert_not_called()
        with patch.dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE='fixture'),patch.object(m,'read_state',return_value=old),patch.object(m,'connected',return_value={}),patch.object(m,'monitors',return_value=[]),patch.object(m,'write_state'),patch.object(m.subprocess,'run') as notify:
            m.sync(layout=False);self.assertEqual(notify.call_count,1);self.assertIn('Display disconnected',notify.call_args.args[0])

    def test_refresh_recovers_from_initial_ddc_detection_failure(self):
        m=module();old={'displays':[{'output':'HDMI-A-1','id':'same','bus':None,'ready':False}]}
        with patch.object(m,'read_state',return_value=old),patch.object(m,'connected',return_value={'HDMI-A-1':{'id':'same'}}),patch.object(m,'monitors',return_value=[]),patch.object(m,'run',return_value='Display 1\n I2C bus: /dev/i2c-2\n DRM connector: card1-HDMI-A-1\n') as run,patch.object(m,'brightness',return_value={'level':90}),patch.object(m,'write_state'):
            result=m.sync(layout=False,notify=False)
            self.assertTrue(result['displays'][0]['ready']);self.assertEqual(result['displays'][0]['bus'],2)
            self.assertEqual(run.call_args.args[0],['ddcutil','detect','--brief'])

    def test_existing_inactive_workspace_moves_before_focus(self):
        m=module();outputs=[screen('eDP-1',6),screen('HDMI-A-1',101,True)]
        with patch.object(m,'monitors',return_value=outputs),patch.object(m,'known_workspaces',return_value=[{'id':3,'monitor':'HDMI-A-1'}]),patch.object(m,'dispatch') as dsp:
            m.workspace(3,'eDP-1');command=dsp.call_args.args[0]
            self.assertLess(command.index('workspace.move'),command.index('workspace="3"}'))
            self.assertIn('workspace="103"',command)

    def test_numbered_selection_leaves_a_visible_special_workspace(self):
        m=module();target=screen('HDMI-A-1',106,True)
        target['specialWorkspace']={'name':'special:special'}
        with patch.object(m,'monitors',return_value=[target]),patch.object(m,'known_workspaces',return_value=[]),patch.object(m,'dispatch') as dsp:
            m.workspace(6,'HDMI-A-1');command=dsp.call_args.args[0]
            self.assertIn('toggle_special("special")',command)
            self.assertIn('workspace="106"',command)

    def test_unknown_output_or_invalid_workspace_does_not_dispatch(self):
        m=module()
        with patch.object(m,'monitors',return_value=[]),patch.object(m,'dispatch') as dsp:
            with self.assertRaises(ValueError):m.workspace(1,'HDMI-A-1')
            with self.assertRaises(ValueError):m.workspace(8)
            dsp.assert_not_called()


if __name__=='__main__':unittest.main()
