import QtQuick
import qs.components
import qs.config
import qs.services
DropdownFrame {
    id:root
    title:"External display"
    implicitWidth:440
    Column {width:parent.width;spacing:14
        Repeater {model:ExternalDisplays.displays
            Column {required property var modelData;width:parent.width;spacing:8
                Text {text:modelData.label;textFormat:Text.PlainText;color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:16;font.bold:true}
                Text {text:modelData.output+" · "+(modelData.active?"Left of main · shared workspaces":"Ready after next login");color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12}
                ControlSlider {visible:modelData.ready;height:visible?implicitHeight:0;title:"Hardware brightness";glyph:"\uf26c";level:modelData.level??0;onEdited:percent=>ExternalDisplays.setLevel(modelData.output,percent)}
                Text {visible:!modelData.ready;width:parent.width;wrapMode:Text.WordWrap;text:modelData.error||"DDC brightness unavailable; use the monitor controls";color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12}
            }
        }
        Text {width:parent.width;wrapMode:Text.WordWrap;text:ExternalDisplays.error||"Scroll the external-display icon for 5% steps. DDC adjusts the monitor backlight without dimming its pixels.";color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12}
    }
}
