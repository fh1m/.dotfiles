import QtQuick
import QtQuick.Controls
Button {
 id:root
 font.hintingPreference:Font.PreferFullHinting
 font.underline:activeFocus
 font.bold:highlighted
 property bool primary:false
 property string variant:primary?"primary":"secondary"
 property bool busy:false
 property string hint:""
 property int textAlignment:Text.AlignHCenter
 Accessible.name:text
 hoverEnabled:true
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+topPadding+bottomPadding)
 leftPadding:NoesisStyle.md;rightPadding:NoesisStyle.md;topPadding:NoesisStyle.sm;bottomPadding:NoesisStyle.sm
 contentItem:Text {renderType:Text.NativeRendering;textFormat:Text.PlainText;text:root.text;color:!root.enabled?NoesisStyle.quiet:root.variant==="primary"?NoesisStyle.selectionInk:root.variant==="danger"?NoesisStyle.error:root.highlighted?NoesisStyle.accent:NoesisStyle.ink;font:root.font;horizontalAlignment:root.textAlignment;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
 background:Rectangle {color:!root.enabled?NoesisStyle.hover:root.variant==="primary"?(root.down?"#ee416f":root.hovered?"#fa5784":NoesisStyle.accent):root.down?"#302923":root.hovered||root.highlighted||root.variant==="secondary"?NoesisStyle.hover:"transparent";radius:NoesisStyle.radius;Behavior on color {ColorAnimation {duration:NoesisStyle.transition}}
 }
}
