import QtQuick
import QtQuick.Controls
ComboBox {
 id:root
 implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+topPadding+bottomPadding)
 implicitWidth:Math.max(140*NoesisStyle.interfaceScale,metrics.advanceWidth+leftPadding+rightPadding)
 TextMetrics {id:metrics;font:root.font;text:root.displayText}
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 leftPadding:NoesisStyle.md;rightPadding:28*NoesisStyle.interfaceScale
 contentItem:Text {textFormat:Text.PlainText;text:root.displayText;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
 indicator:Text {textFormat:Text.PlainText;text:"⌄";color:NoesisStyle.secondary;font:root.font;x:root.width-20*NoesisStyle.interfaceScale;y:(root.height-height)/2}
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.surface;border.width:1;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule}
 delegate:ItemDelegate {required property var modelData;required property int index;width:root.width;implicitHeight:Math.max(NoesisStyle.control,contentItem.implicitHeight+16);text:modelData;font:root.font;highlighted:root.highlightedIndex===index;contentItem:Text {textFormat:Text.PlainText;text:parent.text;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter;wrapMode:Text.Wrap}
  background:Rectangle {color:parent.highlighted?NoesisStyle.hover:NoesisStyle.surface}}
 popup:Popup {y:root.height+NoesisStyle.xs;width:root.width;padding:NoesisStyle.xs;implicitHeight:Math.min(280,contentItem.implicitHeight+8)
  contentItem:ListView {clip:true;implicitHeight:contentHeight;model:root.popup.visible?root.delegateModel:null;currentIndex:root.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator {}}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
 }
}
