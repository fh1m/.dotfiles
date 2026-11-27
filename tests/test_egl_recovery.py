"""Opt-in real Wayland/EGL regressions; no input grab or user-media playback.

SENSEI_NATIVE_EGL_TEST=1 pytest -q tests/test_egl_recovery.py
SENSEI_EGL_TEST_SYSTEM=1 intentionally tests the unpatched system libraries.
"""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import time
import uuid

import pytest

pytestmark = pytest.mark.skipif(not os.environ.get('SENSEI_NATIVE_EGL_TEST'),
                                reason='Requires an explicitly requested live Wayland/EGL test')
FIXTURES = Path(__file__).parent / 'fixtures/egl-recovery'


@pytest.fixture(scope='module')
def native(tmp_path_factory):
    root = tmp_path_factory.mktemp('egl-recovery')
    runtime = root / 'runtime'
    runtime.mkdir(mode=0o700)
    instances = json.loads(subprocess.check_output(['hyprctl', '-i', '0', 'instances', '-j'], text=True))
    assert len(instances) == 1, 'Choose an unambiguous live compositor before running this test'
    instance = instances[0]
    env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime),
               WAYLAND_DISPLAY=f'/run/user/{os.getuid()}/' + instance['wl_socket'],
               HYPRLAND_INSTANCE_SIGNATURE=instance['instance'], QT_QPA_PLATFORM='wayland',
               QSG_RHI_BACKEND='opengl', QS_NO_RELOAD_POPUP='1', LC_ALL='C.UTF-8',
               DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(runtime / 'no-bus'))
    for key in ('QT_QUICK_BACKEND', 'QT_DISABLE_HW_TEXTURES_CONVERSION', 'LD_PRELOAD'):
        env.pop(key, None)
    if not os.environ.get('SENSEI_EGL_TEST_SYSTEM'):
        qt = Path.home() / '.local/opt/sensei-qt-wayland'
        mesa = Path.home() / '.local/opt/sensei-mesa-egl'
        for prefix, manifest in ((qt, 'qt-libraries.sha256'), (mesa, 'mesa-libraries.sha256')):
            subprocess.run(['sha256sum', '--check', '--status', manifest], cwd=prefix, check=True)
        env['LD_LIBRARY_PATH'] = str(mesa / 'lib') + ':' + str(qt / 'lib')
        env['QT_PLUGIN_PATH'] = str(qt / 'plugins')
    else:
        env.pop('LD_LIBRARY_PATH', None)
        env.pop('QT_PLUGIN_PATH', None)
    binary = os.environ.get('SENSEI_QS_BINARY', str(Path.home() / '.local/opt/sensei-quickshell/bin/qs'))
    assert Path(binary).is_file(), 'Build or select the native Quickshell runtime first'
    shutil.copyfile(FIXTURES / 'shell.qml', root / 'shell.qml')
    for name in ('fail-image', 'fail-swap'):
        subprocess.run(['cc', '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror', '-fPIC',
                        '-shared', str(FIXTURES / (name + '.c')), '-o', str(root / (name + '.so')),
                        '-ldl'], check=True)
    libdir = Path(subprocess.check_output(['pkg-config', '--variable=libdir', 'egl'], text=True).strip())
    desktop_env = dict(os.environ, XDG_RUNTIME_DIR=f'/run/user/{os.getuid()}',
                       WAYLAND_DISPLAY=env['WAYLAND_DISPLAY'],
                       HYPRLAND_INSTANCE_SIGNATURE=instance['instance'])
    return {'root': root, 'runtime': runtime, 'env': env, 'desktopEnv': desktop_env,
            'binary': binary, 'libdir': libdir}


def test_failed_mesa_reservation_can_allocate_again(native):
    """Exercise the actual DRI allocator boundary, not a source-text assertion."""
    root, libdir = native['root'], native['libdir']
    dynamic = subprocess.check_output(['readelf', '-d', str(libdir / 'libEGL_mesa.so.0')], text=True)
    names = re.findall(r'Shared library: \[(libgallium-[^\]\n]+)\]', dynamic)
    if len(names) != 1 or not re.fullmatch(r'libgallium-26\.2\.4(?:-[A-Za-z0-9._]+)?\.so', names[0]):
        pytest.skip('The reviewed internal DRI allocation fixture targets Mesa 26.2.4 only')
    driver = libdir / names[0]
    flags = shlex.split(subprocess.check_output(['pkg-config', '--cflags', '--libs',
                                               'egl', 'wayland-egl', 'wayland-client'], text=True))
    subprocess.run(['cc', '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                    str(FIXTURES / 'allocation.c'), '-o', str(root / 'allocation'), *flags,
                    '-ldl', '-Wl,--no-as-needed', str(driver), '-Wl,--as-needed'], check=True)
    prefix = Path(subprocess.check_output(['pkg-config', '--variable=prefix', 'egl'], text=True).strip())
    env = dict(native['env'], LD_PRELOAD=str(root / 'fail-image.so') + ':' + str(driver),
               __EGL_VENDOR_LIBRARY_FILENAMES=str(prefix / 'share/glvnd/egl_vendor.d/50_mesa.json'))
    result = subprocess.run([str(root / 'allocation'), 'fail-then-recover'], env=env,
                            capture_output=True, text=True, timeout=20)
    log = result.stdout + result.stderr
    if result.returncode != 0 and 'rejected=0' in log and 'failed to create dri2 screen' in log:
        pytest.skip('Current proprietary GPU does not expose a Mesa DRI screen; swap recovery is tested separately')
    assert result.returncode == 0, log
    assert 'query=0' in log and 'error=0x3003' in log, log
    assert 'PROBE_PASS allocation and presentation recovery' in log, log


def find_layer(value, namespace):
    if isinstance(value, dict):
        if value.get('namespace') == namespace:
            return value
        children = value.values()
    elif isinstance(value, list):
        children = value
    else:
        return None
    for child in children:
        result = find_layer(child, namespace)
        if result is not None:
            return result
    return None


@pytest.mark.parametrize('loop', ['basic', 'threaded'])
def test_failed_commit_resumes_visible_frames(native, loop):
    """A live timer or process alone is insufficient: compositor pixels must resume."""
    from PIL import Image
    root = native['root']
    flag = root / ('reject-' + loop)
    namespace = 'den-egl-recovery-' + uuid.uuid4().hex
    env = dict(native['env'], DEN_EGL_FAIL_FLAG=str(flag), SENSEI_EGL_TEST_ID=namespace,
               QSG_RENDER_LOOP=loop,
               LD_PRELOAD=str(root / 'fail-swap.so') + ':' + str(native['libdir'] / 'libEGL.so.1'))
    qml = str(root / 'shell.qml')

    def call(method, *values):
        result = subprocess.run([native['binary'], '-p', qml, 'ipc', '--any-display', 'call',
                                 'egl-recovery-probe', method, *map(str, values)], env=env,
                                capture_output=True, text=True, timeout=2)
        if result.returncode:
            raise RuntimeError('Owned probe IPC unavailable')
        return json.loads(result.stdout)

    def pixels():
        colors = []
        for index in range(6):
            layers = json.loads(subprocess.check_output(['hyprctl', 'layers', '-j'], env=native['desktopEnv'], text=True, timeout=3))
            layer = find_layer(layers, namespace)
            assert layer is not None, 'Owned layer disappeared'
            x, y = layer['x'] + layer['w'] // 2, layer['y'] + layer['h'] // 2
            image = root / f'{loop}-{index}.png'
            subprocess.run(['grim', '-s', '1', '-g', f'{x},{y} 1x1', str(image)],
                           env=native['desktopEnv'], check=True, capture_output=True, timeout=3)
            with Image.open(image) as bitmap:
                colors.append(bitmap.convert('RGB').getpixel((0, 0)))
            time.sleep(.13)
        return colors

    with tempfile.TemporaryFile(mode='w+t') as log:
        child = subprocess.Popen(['prlimit', '--core=0:0', '--', native['binary'], '-p', qml],
                                 env=env, stdout=log, stderr=log)
        try:
            deadline, state = time.monotonic() + 8, None
            while time.monotonic() < deadline:
                assert child.poll() is None, 'Probe exited during normal startup'
                try:
                    state = call('state')
                except (RuntimeError, subprocess.TimeoutExpired):
                    pass
                if state and state['swaps'] > 0:
                    break
                time.sleep(.05)
            assert state and state['swaps'] > 0, 'No initial presentation'
            assert len(set(pixels())) > 1, 'No visible presentation before the fault'
            flag.touch()
            call('resize', 257, 193)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                log.seek(0)
                if 'PROBE_REJECT_SWAP' in log.read() or child.poll() is not None:
                    break
                time.sleep(.02)
            time.sleep(1.2)
            flag.unlink()
            time.sleep(.5)
            assert child.poll() is None, 'Failed swap crashed the renderer'
            assert len(set(pixels())) > 1, 'Widget survived but remained visually frozen'
            recovered = call('state')
            assert (recovered['width'], recovered['height']) == (257, 193), 'Resize did not exercise a new buffer'
            assert recovered['swaps'] > state['swaps'], 'No post-failure presentation'
            log.seek(0)
            evidence = log.read()
            assert 'PROBE_REJECT_SWAP' in evidence, 'No failure was actually injected'
            assert 'eglSwapBuffers failed with 0x3003' in evidence, 'Original allocation error was hidden'
            assert 'ReferenceError:' not in evidence and 'TypeError:' not in evidence, evidence
        finally:
            flag.unlink(missing_ok=True)
            if child.poll() is None:
                child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait(timeout=3)
