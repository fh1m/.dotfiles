import QtQuick
import QtQuick.Controls
import qs.config
ComboBox {
 id:root
 implicitHeight:NoesisStyle.control
 implicitWidth:140
 font.family:NoesisStyle.uiFont;font.pixelSize:NoesisStyle.label
 leftPadding:NoesisStyle.md;rightPadding:28
 contentItem:Text {text:root.displayText;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
 indicator:Text {text:"⌄";color:NoesisStyle.secondary;font:root.font;x:root.width-20;y:(root.height-height)/2}
 background:Rectangle {radius:NoesisStyle.radius;color:NoesisStyle.surface;border.width:1;border.color:root.activeFocus?NoesisStyle.accent:NoesisStyle.rule}
 delegate:ItemDelegate {required property var modelData;required property int index;width:root.width;text:modelData;font:root.font;highlighted:root.highlightedIndex===index;contentItem:Text {text:parent.text;font:root.font;color:NoesisStyle.ink;verticalAlignment:Text.AlignVCenter}
  background:Rectangle {color:parent.highlighted?NoesisStyle.hover:NoesisStyle.surface}}
 popup:Popup {y:root.height+NoesisStyle.xs;width:root.width;padding:NoesisStyle.xs;implicitHeight:Math.min(280,contentItem.implicitHeight+8)
  contentItem:ListView {clip:true;implicitHeight:contentHeight;model:root.popup.visible?root.delegateModel:null;currentIndex:root.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator {}}
  background:Rectangle {color:NoesisStyle.surface;radius:NoesisStyle.radius;border.width:1;border.color:NoesisStyle.rule}
 }
}
