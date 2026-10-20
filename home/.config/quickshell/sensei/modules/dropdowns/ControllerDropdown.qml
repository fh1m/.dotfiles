import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"Controllers · input lab";implicitWidth:740
 property bool rawOpen:false
 function axis(code){return Controllers.device.axes?.find(a=>a.code===code)?.value||0;}
 Column {id:body;width:parent.width;spacing:14
  Row {width:parent.width;spacing:10
   Text {text:"\uf11b";font.family:Appearance.font.icons;font.pixelSize:27;color:Theme.widgetAccent}
   Column {width:parent.width-45;spacing:4
    Text {width:parent.width;text:Controllers.device.name||"Waiting for a controller";elide:Text.ElideRight;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.title;color:Theme.paper}
    Text {width:parent.width;text:Controllers.data.controllers.length?Controllers.data.controllers.length+" connected · "+(Controllers.device.connection||"Input")+" · "+(Controllers.device.monitoring===false?"tester paused":Controllers.busy?"calibrating / testing":"live input · up to 30 Hz"):"Connect USB or Bluetooth. Devices appear automatically.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   }
  }
  Flow {width:parent.width;spacing:8;Repeater {model:Controllers.data.controllers
   ControlTile {required property var modelData;implicitWidth:(body.width-8)/2;glyph:"\uf11b";label:modelData.name;detail:modelData.vendor+":"+modelData.product+" · "+modelData.driver;selected:Controllers.device.id===modelData.id;enabled:!Controllers.busy;onActivated:Controllers.selected=modelData.id}
  }}
  Row {width:parent.width;spacing:8;Repeater {model:[{name:"Live test",glyph:"\uf05b"},{name:"Tune",glyph:"\uf1de"},{name:"Device",glyph:"\uf2db"},{name:"Robotics",glyph:"\uf0ad"}]
   ControlTile {required property var modelData;required property int index;implicitWidth:(body.width-24)/4;label:modelData.name;glyph:modelData.glyph;selected:Controllers.page===index;navigation:true;onActivated:Controllers.page=index}
  }}
  Column {width:parent.width;spacing:12;visible:Controllers.page===0&&!!Controllers.device.id
   Row {width:parent.width;spacing:12;visible:Controllers.device.monitoring!==false
    Repeater {model:Controllers.device.layout?.sticks||[]
     Rectangle {required property var modelData;width:(body.width-12)/2;height:196;radius:9;color:Theme.surfaceOne;border.color:Theme.rule
      Text {x:14;y:12;text:modelData.name;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
      Item {anchors.centerIn:parent;width:132;height:132
       Rectangle {anchors.fill:parent;radius:66;color:"transparent";border.color:Theme.rule}
       Rectangle {anchors.centerIn:parent;width:132*(Controllers.device.deadzone||0);height:width;radius:width/2;color:"#22ff1768";border.color:Theme.rule}
       Rectangle {anchors.centerIn:parent;width:1;height:132;color:Theme.rule}
       Rectangle {anchors.centerIn:parent;width:132;height:1;color:Theme.rule}
       Rectangle {x:66+root.axis(modelData.x)*60-7;y:66+root.axis(modelData.y)*60-7;width:14;height:14;radius:7;color:Theme.widgetAccent;border.color:Theme.paper
        Behavior on x {NumberAnimation {duration:20}}
        Behavior on y {NumberAnimation {duration:20}}
       }
      }
      Text {anchors.bottom:parent.bottom;anchors.horizontalCenter:parent.horizontalCenter;anchors.bottomMargin:9;text:root.axis(modelData.x).toFixed(2)+"   /   "+root.axis(modelData.y).toFixed(2);font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.caption;color:Theme.paperMuted}
     }
    }
   }
   Row {width:parent.width;spacing:12;visible:Controllers.device.monitoring!==false
    Repeater {model:Controllers.device.layout?.triggers||[]
     Column {required property int modelData;required property int index;width:(body.width-12)/2;spacing:6
      Text {text:(index===0?"Left trigger":"Right trigger")+" · "+Math.round(root.axis(modelData)*100)+"%";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
      Rectangle {width:parent.width;height:8;radius:4;color:Theme.surfaceTwo;Rectangle {width:parent.width*root.axis(modelData);height:parent.height;radius:4;color:Theme.widgetAccent}}
     }
    }
   }
   Row {spacing:12;visible:Controllers.device.layout?.dpad===true&&Controllers.device.monitoring!==false
    Text {text:"D-pad";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted;anchors.verticalCenter:parent.verticalCenter}
    Repeater {model:[{text:"←",on:root.axis(16)<0},{text:"↑",on:root.axis(17)<0},{text:"↓",on:root.axis(17)>0},{text:"→",on:root.axis(16)>0}]
     Rectangle {required property var modelData;width:36;height:32;radius:5;color:modelData.on?Theme.widgetAccent:Theme.surfaceOne;border.color:Theme.rule
      Text {anchors.centerIn:parent;text:modelData.text;font.family:Appearance.font.data;font.pixelSize:18;color:parent.modelData.on?"#000000":Theme.paperMuted}
     }
    }
   }
   Flow {width:parent.width;spacing:6;Repeater {model:Controllers.device.buttons||[]
    Rectangle {required property var modelData;readonly property bool down:(Controllers.device.pressed||[]).some(b=>b.code===modelData.code);width:Math.max(66,buttonText.implicitWidth+20);height:30;radius:5;color:down?Theme.widgetAccent:Theme.surfaceOne;border.color:down?Theme.widgetAccent:Theme.rule
     Text {id:buttonText;anchors.centerIn:parent;text:modelData.name;font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.caption;color:parent.down?"#000000":Theme.paperMuted}
    }
   }}
   Text {width:parent.width;text:Controllers.device.monitoring===false?"Tester paused. Games still receive controller input.":(Controllers.device.pressed||[]).length?"Pressed · "+Controllers.device.pressed.map(b=>b.name).join(" · "):"Move a stick, sweep a trigger or press a button.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   Text {width:parent.width;text:(Controllers.device.events||[]).slice(-3).map(e=>e.name+" "+e.value).join("   ·   ");visible:(Controllers.device.events||[]).length>0;elide:Text.ElideLeft;font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.caption;color:Theme.widgetMuted}
  }
  Column {width:parent.width;spacing:12;visible:Controllers.page===1&&!!Controllers.device.id
   Text {width:parent.width;text:"Viewer profile · "+(Controllers.device.calibrated?"calibrated ranges":"driver ranges");font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
   Text {width:parent.width;text:"Calibration: release the sticks for 2 seconds, then rotate both fully and sweep analog triggers for 10 seconds. If nothing moves, your existing profile is preserved.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   Row {width:parent.width;spacing:12
    Text {text:"Deadzone · "+Math.round((Controllers.device.deadzone||0)*100)+"%";width:140;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted;anchors.verticalCenter:parent.verticalCenter}
    Slider {width:Math.max(100,body.width-168);from:0;to:.3;stepSize:.01;value:Controllers.device.deadzone||0;enabled:!Controllers.busy;onMoved:if(!pressed)Controllers.action('deadzone',value);onPressedChanged:if(!pressed)Controllers.action('deadzone',value)
     background:Rectangle {x:parent.leftPadding;y:parent.topPadding+parent.availableHeight/2-height/2;width:parent.availableWidth;height:5;radius:2;color:Theme.surfaceTwo;Rectangle {width:parent.width*parent.parent.visualPosition;height:parent.height;radius:2;color:Theme.widgetAccent}}
     handle:Rectangle {x:parent.leftPadding+parent.visualPosition*(parent.availableWidth-width);y:parent.topPadding+parent.availableHeight/2-height/2;width:16;height:16;radius:8;color:Theme.paper;border.color:Theme.widgetAccent;border.width:2}
    }
   }
   Flow {width:parent.width;spacing:8
    ControlTile {label:"Calibrate · 12 seconds";glyph:"\uf05b";enabled:!Controllers.busy;onActivated:Controllers.action('calibrate')}
    ControlTile {label:"Reset calibration";glyph:"\uf0e2";enabled:Controllers.device.calibrated===true&&!Controllers.busy;onActivated:Controllers.action('reset')}
   }
   Text {width:parent.width;text:"This profile changes the tester only. Steam, SDL and individual games retain their own calibration and mappings.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
  }
  Column {width:parent.width;spacing:10;visible:Controllers.page===2&&!!Controllers.device.id
   Text {width:parent.width;text:"Connection  "+Controllers.device.connection+"\nDriver  "+Controllers.device.driver+"\nUSB identity  "+Controllers.device.vendor+":"+Controllers.device.product+"\nInput node  "+Controllers.device.path+"\nPhysical path  "+Controllers.device.physical+"\nRumble  "+(Controllers.device.rumble?"reported by driver":"not reported")+"\nBattery  "+(Controllers.device.connection==="USB"?"wired device · not reported":"not reported by this input driver");wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   ControlTile {label:root.rawOpen?"Hide raw axes":"Raw axes / driver ranges";glyph:"\uf201";onActivated:root.rawOpen=!root.rawOpen}
   Repeater {model:root.rawOpen?Controllers.device.axes||[]:[]
    Row {required property var modelData;width:parent.width;spacing:10
     Text {width:100;text:modelData.name;font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.caption;color:Theme.paperMuted}
     Rectangle {width:Math.max(60,body.width-310);height:6;radius:3;color:Theme.surfaceTwo;anchors.verticalCenter:parent.verticalCenter;Rectangle {height:parent.height;width:parent.width*(modelData.trigger?modelData.value:(modelData.value+1)/2);radius:3;color:Theme.widgetAccent}}
     Text {width:180;text:modelData.raw+"  ["+modelData.min+", "+modelData.max+"]";font.family:Appearance.font.data;font.pixelSize:Appearance.textSize.caption;color:Theme.paper}
    }
   }
  }
  Column {width:parent.width;spacing:12;visible:Controllers.page===3&&!!Controllers.device.id
   Text {width:parent.width;text:"ROS 2 · input profile";font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paper}
   Text {width:parent.width;text:"Save settings here, then export for your chosen ROS container or workspace. This exports /joy input only; robot commands and teleoperation mappings are separate.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   Row {width:parent.width;spacing:8
    DeskComboBox {id:rosEnvironment;width:Math.max(180,body.width-220);model:Controllers.environments;enabled:!Controllers.busy}
    ControlTile {implicitWidth:212;label:"Inspect ROS devices";glyph:"\uf002";enabled:!Controllers.busy;onActivated:Controllers.action('ros-probe',Controllers.environments[rosEnvironment.currentIndex]||'host')}
   }
   Text {width:parent.width;text:Controllers.device.ros?.device_name?"Verified SDL name · "+Controllers.device.ros.device_name+"\nEnvironment · "+Controllers.device.ros.environment+" · "+(Controllers.device.ros.mapped?"mapped gamepad available":"generic joystick recommended"):"Inspect your ROS environment to save its SDL device name before exporting.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   Row {width:parent.width;spacing:8
    ControlTile {implicitWidth:(body.width-8)/2;label:"Generic joystick";detail:"joy_node · device-specific order";selected:Controllers.device.ros?.node!=="game_controller_node";enabled:!Controllers.busy;onActivated:Controllers.action('ros-node','joy_node')}
    ControlTile {implicitWidth:(body.width-8)/2;label:"Mapped gamepad";detail:"game_controller_node · SDL layout";selected:Controllers.device.ros?.node==="game_controller_node";enabled:!Controllers.busy;onActivated:Controllers.action('ros-node','game_controller_node')}
   }
   Repeater {model:[{name:"Publish rate · Hz",key:"ros-rate",value:Controllers.device.ros?.rate??20,max:1000},{name:"ROS deadzone · 0–0.3",key:"ros-deadzone",value:Controllers.device.ros?.deadzone??.05,max:.3},{name:"Coalesce events · ms",key:"ros-coalesce",value:Controllers.device.ros?.coalesce??1,max:1000}]
    Row {required property var modelData;width:parent.width;spacing:12
     Text {width:210;text:modelData.name;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.body;color:Theme.paperMuted;anchors.verticalCenter:parent.verticalCenter}
     DeskTextField {id:settingValue;width:120;text:String(modelData.value);enabled:!Controllers.busy;validator:DoubleValidator {bottom:0;top:modelData.max;decimals:modelData.key==='ros-coalesce'?0:3;locale:'C'}}
     ControlTile {implicitWidth:80;label:'Save';enabled:!Controllers.busy&&settingValue.acceptableInput;onActivated:Controllers.action(modelData.key,settingValue.text)}
    }
   }
   ControlTile {label:Controllers.device.ros?.sticky?"Sticky buttons · on":"Sticky buttons · off";detail:"Keep off for a held dead-man button";selected:Controllers.device.ros?.sticky===true;enabled:!Controllers.busy;onActivated:Controllers.action('ros-sticky',Controllers.device.ros?.sticky?'off':'on')}
   Text {width:parent.width;text:"Rate 0 means event-only. Mapped gamepad needs an SDL mapping. First verify with joy_enumerate_devices and inspect /den/input/joy; evdev codes shown here are not ROS array indices.";wrapMode:Text.Wrap;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
   Flow {width:parent.width;spacing:8
    ControlTile {label:"Export ROS profile";glyph:"\uf019";enabled:!Controllers.busy;onActivated:Controllers.action('export-ros')}
    ControlTile {label:"Copy launch command";glyph:"\uf0c5";enabled:Controllers.exportDevice===Controllers.device.id&&Controllers.exportCommand!=='';onActivated:Quickshell.execDetached(['wl-copy','--',Controllers.exportCommand])}
    ControlTile {label:"Open exported files";glyph:"\uf07c";enabled:Controllers.exportDevice===Controllers.device.id&&Controllers.exportPath!=='';onActivated:Quickshell.execDetached(['xdg-open',Controllers.exportPath])}
   }
  }
  Flow {width:parent.width;spacing:8
   ControlTile {label:"Refresh";glyph:"\uf021";enabled:!Controllers.busy;onActivated:Controllers.refresh()}
   ControlTile {label:Controllers.device.monitoring===false?"Resume tester":"Pause tester";glyph:"\uf04c";enabled:!!Controllers.device.id&&!Controllers.busy;onActivated:Controllers.action('enabled',Controllers.device.monitoring===false?'on':'off')}
   ControlTile {label:"Rumble · 350 ms";glyph:"\uf0e7";enabled:Controllers.device.rumble===true&&!Controllers.busy;onActivated:Controllers.action('rumble')}
  }
  Text {width:parent.width;text:Controllers.report;wrapMode:Text.Wrap;textFormat:Text.PlainText;font.family:Appearance.font.reading;font.pixelSize:Appearance.textSize.secondary;color:Theme.paperMuted}
 }
}
