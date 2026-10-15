import QtQuick
import QtQuick.Controls
ComboBox {
 id:root
 font.hintingPreference:Font.PreferFullHinting
 implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+topPadding+bottomPadding)
 implicitWidth:Math.max(140*NoesisStyle.interfaceScale,metrics.advanceWidth+leftPadding+rightPadding)
 TextMetrics {id:metrics;font:root.font;text:root.displayText}
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 leftPadding:NoesisStyle.md;rightPadding:28*NoesisStyle.interfaceScale
 contentItem:Text {renderType:Text.NativeRendering;textFormat:Text.PlainText;text:root.displayText;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
 indicator:Text {renderType:Text.NativeRendering;textFormat:Text.PlainText;text:"⌄";color:NoesisStyle.secondary;font:root.font;x:root.width-20*NoesisStyle.interfaceScale;y:(root.height-height)/2}
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.hover
  Rectangle {anchors.left:parent.left;anchors.right:parent.right;anchors.bottom:parent.bottom;height:2;visible:root.activeFocus;color:NoesisStyle.accent}
 }
 delegate:ItemDelegate {id:choice;required property var modelData;required property int index;width:root.width;implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+16);text:modelData;font:root.font;highlighted:root.highlightedIndex===index;contentItem:Text {renderType:Text.NativeRendering;textFormat:Text.PlainText;text:parent.text;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
  background:Rectangle {color:choice.highlighted?NoesisStyle.hover:NoesisStyle.surface;Rectangle {anchors.left:parent.left;anchors.top:parent.top;anchors.bottom:parent.bottom;width:2;color:NoesisStyle.accent;visible:choice.highlighted}}}
 popup:Popup {y:root.height+NoesisStyle.xs;width:root.width;padding:NoesisStyle.xs;implicitHeight:Math.min(280,contentItem.implicitHeight+8)
  contentItem:ListView {clip:true;implicitHeight:contentHeight;model:root.popup.visible?root.delegateModel:null;currentIndex:root.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator {}}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;}
 }
}
