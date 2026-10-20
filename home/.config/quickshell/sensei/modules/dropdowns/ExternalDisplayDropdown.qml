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
                Text {text:(modelData.barEdge==="top"?"Upper":"Lower")+" · "+modelData.label;textFormat:Text.PlainText;color:Theme.widgetText;font.family:Appearance.font.reading;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:16;font.bold:true}
                Text { textFormat: Text.PlainText;text:modelData.output+" · "+(modelData.active?(modelData.barEdge==="top"?"Above lower · shared workspaces":"Left of main · shared workspaces"):"Ready after next login");color:Theme.widgetMuted;font.family:Appearance.font.reading;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:12}
                Text { textFormat: Text.PlainText;visible:modelData.active;text:modelData.width+" × "+modelData.height+" · "+Number(modelData.refresh??60).toFixed(2)+" Hz · "+(modelData.scale??1)+"× scale";color:Theme.widgetText;font.family:Appearance.font.reading;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:13}
                ControlSlider {visible:modelData.ready;height:visible?implicitHeight:0;title:"Hardware brightness";glyph:"\uf26c";level:modelData.level??0;onEdited:percent=>ExternalDisplays.setLevel(modelData.output,percent)}
                Text { textFormat: Text.PlainText;visible:!modelData.ready;width:parent.width;wrapMode:Text.WordWrap;text:modelData.error||"DDC brightness unavailable; use the monitor controls";color:Theme.widgetMuted;font.family:Appearance.font.reading;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:12}
            }
        }
        Text { textFormat: Text.PlainText;width:parent.width;wrapMode:Text.WordWrap;text:ExternalDisplays.error||"Scroll the external-display icon for 5% steps. DDC adjusts the monitor backlight without dimming its pixels.";color:Theme.widgetMuted;font.family:Appearance.font.reading;renderType:Text.NativeRendering;font.hintingPreference:Font.PreferFullHinting;font.pixelSize:12}
    }
}
