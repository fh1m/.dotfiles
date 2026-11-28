"""Render each atlas quadrant at real display densities without a live desktop."""
import json
from pathlib import Path

from PIL import Image, ImageDraw
import pytest

from test_quickshell_ui_freshness import HAS_QS, put, run_native

ROOT = Path(__file__).resolve().parents[1]
COMPANION = ROOT / 'home/.local/share/sensei-companion'
COLORS = [(224, 32, 72, 255), (28, 180, 100, 255),
          (40, 96, 224, 255), (232, 176, 28, 255)]


@pytest.mark.skipif(not HAS_QS, reason='Explicit native Quickshell runtime required')
@pytest.mark.parametrize('density', [1, 1.5, 2])
def test_guest_atlas_stays_bounded_and_never_exposes_adjacent_frames(tmp_path, density):
    (tmp_path / 'Actor').symlink_to(COMPANION, target_is_directory=True)
    atlas = Image.new('RGBA', (2048, 2048), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)
    for frame, color in enumerate(COLORS):
        x, y = (frame % 2) * 1024, (frame // 2) * 1024
        draw.rectangle((x + 128, y + 128, x + 895, y + 895), fill=color)
    atlas.save(tmp_path / 'atlas.png')
    capture = tmp_path / 'frames.png'
    harness = '''import QtQuick
import QtQuick.Window
import Quickshell
import "Actor" as Actor
ShellRoot {
    id: test
    property bool capturing:false
    property int ticks:0
    function images(item) {
        let result=[]
        for(const child of item.children||[]) {
            if(child.sourceSize!==undefined&&child.status!==undefined) result.push(child)
            else result=result.concat(images(child))
        }
        return result
    }
    Window {
        visible:true; width:504; height:140; color:'transparent'
        Row {
            id: gallery
            spacing:8
            Repeater {
                model:4
                Actor.GuestSprite {
                    required property int index
                    width:120; height:140; frame:index; reducedMotion:true
                    source:Qt.resolvedUrl('atlas.png')
                }
            }
        }
    }
    Timer {interval:20;repeat:true;running:true;onTriggered:{
        test.ticks++
        if(test.ticks>200) {console.error('PROOF_FAIL atlas readiness');Qt.exit(2);return}
        const samples=test.images(gallery)
        if(samples.length!==8||!samples.every(image=>image.status===Image.Ready))return
        const expected=Math.ceil(240*Number(Quickshell.env('QT_SCALE_FACTOR')))
        if(samples.some(image=>image.implicitWidth!==expected||image.implicitHeight!==expected)) {
            console.error('PROOF_FAIL oversized atlas decode');Qt.exit(2);return
        }
        if(test.capturing)return
        test.capturing=true
        gallery.grabToImage(result=>{
            if(!result.saveToFile(@CAPTURE@)) {Qt.exit(2);return}
            console.log('PROOF_PASS atlas crops and decode budget');Qt.quit()
        },Qt.size(504,140))
        stop()
    }}
}
'''.replace('@CAPTURE@', json.dumps(str(capture)))
    report = run_native(tmp_path, harness, extra_env={'QT_SCALE_FACTOR': str(density)})
    assert 'PROOF_PASS atlas crops and decode budget' in report
    with Image.open(capture) as pixels:
        assert pixels.size == (round(504 * density), round(140 * density))
        for frame, color in enumerate(COLORS):
            center = (round((frame * 128 + 60) * density), round(70 * density))
            assert pixels.getpixel(center) == color
            # Transparent margins distinguish one clipped pose from neighboring tiles.
            margin = (round((frame * 128 + 3) * density), round(70 * density))
            assert pixels.getpixel(margin)[3] == 0
