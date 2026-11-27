"""Opt-in native memory boundary; never touches the running desktop session."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

import pytest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.skipif(not os.environ.get('SENSEI_QS_BINARY'), reason='Select a native Quickshell runtime explicitly')
def test_unallocated_wallpaper_does_not_decode_full_resolution(tmp_path):
    binary = Path(os.environ['SENSEI_QS_BINARY']).expanduser()
    for name in ('components', 'services', 'config'):
        (tmp_path / name).mkdir()
    shutil.copy2(ROOT / 'home/.config/quickshell/sensei/components/Wallpaper.qml',
                 tmp_path / 'components/Wallpaper.qml')
    # Theme/selection services are unrelated to the image allocation under test.
    (tmp_path / 'services/Wallpapers.qml').write_text(
        'pragma Singleton\nimport QtQuick\nimport Quickshell\n'
        'QtObject {property url displayed:Quickshell.env("DEN_TEST_IMAGE");property int fadeDuration:0}\n')
    (tmp_path / 'config/Appearance.qml').write_text(
        'pragma Singleton\nimport QtQuick\nQtObject {property var duration:({panel:0})}\n')
    (tmp_path / 'shell.qml').write_text(
        'import QtQuick\nimport Quickshell\nimport "components" as Ui\n'
        'ShellRoot {Ui.Wallpaper {width:0;height:0}\n'
        'Timer {interval:250;running:true;onTriggered:Qt.quit()}}\n')
    image = tmp_path / 'large.png'
    with Image.new('RGB', (7680, 4320), '#243247') as fixture:
        fixture.save(image)
    measure = '''
import json,resource,subprocess,sys
result=subprocess.run(sys.argv[1:],capture_output=True,text=True,timeout=20)
print(json.dumps({'exit':result.returncode,'peakKiB':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
                  'report':result.stdout+result.stderr}))
'''
    home = tmp_path / 'home'
    home.mkdir()
    with tempfile.TemporaryDirectory(prefix='den-image-') as runtime:
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
                   XDG_STATE_HOME=str(home / '.local/state'), XDG_DATA_HOME=str(home / '.local/share'),
                   XDG_CACHE_HOME=str(home / '.cache'), XDG_RUNTIME_DIR=runtime,
                   DBUS_SESSION_BUS_ADDRESS='unix:path=' + runtime + '/no-bus',
                   QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                   QS_NO_RELOAD_POPUP='1', DEN_TEST_IMAGE=image.as_uri())
        result = subprocess.run([sys.executable, '-c', measure,
                                 str(binary), '-p', str(tmp_path / 'shell.qml')], env=env,
                                capture_output=True, text=True, timeout=25)
    assert result.returncode == 0, result.stdout + result.stderr
    measured = json.loads(result.stdout)
    assert measured['exit'] == 0, measured['report']
    peak_kib = measured['peakKiB']
    # One full ARGB decode alone is 126.56 MiB. The cold software-rendered
    # fixture must stay below 96 MiB, including the real Qt/QML runtime.
    assert peak_kib < 96 * 1024, f'Unallocated wallpaper consumed {peak_kib / 1024:.2f} MiB peak RSS'
