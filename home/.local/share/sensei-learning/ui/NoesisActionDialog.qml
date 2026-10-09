import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

NoesisDialog {
 id:root
 property var actions:[]
 signal chosen(string action)
 title:"Context actions"
 function begin(items){actions=items;open();list.currentIndex=0;list.forceActiveFocus();}
 function choose(action){close();chosen(action);}
 contentItem:ListView {
  id:list
  implicitHeight:Math.min(360,count*NoesisStyle.row)
  clip:true
  model:root.actions
  keyNavigationEnabled:true
  Keys.onReturnPressed:if(currentIndex>=0)root.choose(root.actions[currentIndex].action)
  Keys.onEnterPressed:if(currentIndex>=0)root.choose(root.actions[currentIndex].action)
  delegate:NoesisRow {
   required property var modelData
   required property int index
   width:ListView.view.width
   title:modelData.label
   subtitle:modelData.reason||""
   highlighted:ListView.isCurrentItem
   onClicked:root.choose(modelData.action)
  }
  ScrollBar.vertical:ScrollBar {}
 }
}
