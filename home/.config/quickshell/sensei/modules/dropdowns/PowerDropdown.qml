import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

DropdownFrame {
 id:root
 implicitWidth:500
 title:"Battery & power"
 katakana:Power.onBattery?"Battery":"AC connected"
 function number(v,unit):string {return v===null||v===undefined?"Unavailable":Number(v).toFixed(1)+" "+unit;}
 function estimate():string {
  const d=Power.details;
  if(Power.onBattery){const t=Power.battery?.timeToEmpty??0;return t>0?Math.ceil(t/60)+" min remaining · estimated":"Runtime estimate unavailable";}
  if(d.status==="Charging"&&d.watts>0&&d.capacity>0&&d.limit){let minutes=Math.max(0,(d.capacity*d.limit/100-d.energy)/d.watts*60);return Math.ceil(minutes)+" min to "+d.limit+"% · at current rate";}
  return "AC connected · "+Power.stateLabel().toLowerCase();
 }
 Column {width:parent.width;spacing:12
  Row {spacing:14
   Text {text:Power.present?Math.round(Power.charge)+"%":"—";color:Theme.paper;font.family:Appearance.font.telemetry;font.pixelSize:34}
   Column {anchors.verticalCenter:parent.verticalCenter;spacing:4
    Text {text:Power.stateLabel().toLowerCase();color:Theme.signalRed;font.family:Appearance.font.ui;font.pixelSize:13}
    Text {text:root.estimate();color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:11}
   }
  }
  SegmentMeter {width:parent.width;segments:20;segmentWidth:(parent.width-38)/20;segmentHeight:7;value:Power.charge/100;litColor:Theme.signalRed}
  Grid {columns:2;columnSpacing:20;rowSpacing:8;width:parent.width
   Repeater {model:[['Energy',root.number(Power.details.energy,'Wh')+' / '+root.number(Power.details.capacity,'Wh')],['Power flow',root.number(Power.details.watts,'W')],['Battery health',root.number(Power.details.health,'%')],['Design capacity',root.number(Power.details.design,'Wh')],['Voltage',root.number(Power.details.voltage,'V')],['Charge ceiling',Power.details.limit?Power.details.limit+'%':'Unsupported']]
    Column {required property var modelData;width:(root.width-48)/2;spacing:3
     Text {text:parent.modelData[0];color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:10}
     Text {text:parent.modelData[1];color:Theme.paper;font.family:Appearance.font.telemetry;font.pixelSize:12}
    }
   }
  }
  Text {text:'Power flow · live samples, every 30 s while open';color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:10}
  Rectangle {width:parent.width;height:66;color:Theme.surfaceOne;radius:3
   Sparkline {anchors.fill:parent;anchors.margins:8;downValues:Power.rateHistory;upValues:[];points:60;floorValue:10;downColor:Theme.signalRed;strokeWidth:1.5}
   Text {anchors.centerIn:parent;visible:Power.rateHistory.length<2;text:'Collecting measurements…';color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:11}
  }
  Text {text:'Power policy';color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12}
  Row {spacing:7
   Repeater {model:Power.profiles
    ControlTile {required property var modelData;implicitWidth:150;label:modelData.cli==='power-saver'?'Saver':modelData.cli==='performance'?'Performance':'Balanced';glyph:modelData.cli==='power-saver'?'\uf06c':modelData.cli==='performance'?'\uf0e7':'\uf24e';selected:Power.profile===modelData.id;onActivated:Power.setProfile(modelData.cli)}
   }
  }
  Text {text:'Charging policy';color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12;visible:Power.details.limitSupported??false}
  Row {spacing:7;visible:Power.details.limitSupported??false
   Repeater {model:[60,80,100]
    ControlTile {required property int modelData;implicitWidth:150;label:modelData+'% ceiling';glyph:'\uf240';selected:Power.details.limit===modelData;onActivated:Power.chargeLimit(modelData)}
   }
  }
  ControlTile {implicitWidth:parent.width;label:'Charge fully once';detail:'Return to saved ceiling after one-shot charging';glyph:'\uf0e7';visible:Power.details.limitSupported??false;onActivated:Power.chargeLimit(100,true)}
  Column {width:parent.width;spacing:8;visible:Power.peripheralBatteries.length>0
   Text {text:'Connected device batteries';color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12}
   ScrollView {width:parent.width;height:Math.min(Power.peripheralBatteries.length*88,224);contentWidth:availableWidth;clip:true;ScrollBar.vertical:DeskScrollBar {}
    Column {width:parent.width;spacing:8
     Repeater {model:Power.peripheralBatteries
      Rectangle {required property var modelData;width:parent.width;height:80;color:Theme.surfaceOne;radius:3
       Column {x:10;y:8;width:parent.width-118;spacing:5
        Text {width:parent.width;text:modelData.name+' · '+Math.round(modelData.percent)+'%';color:Theme.paper;font.family:Appearance.font.ui;font.pixelSize:12;elide:Text.ElideRight}
        Text {width:parent.width;text:modelData.state+' · '+modelData.detail;color:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:10;elide:Text.ElideRight}
        SegmentMeter {width:parent.width;segments:12;segmentWidth:(parent.width-22)/12;segmentHeight:4;value:modelData.percent/100;litColor:Theme.signalRed}
       }
       ControlTile {anchors.right:parent.right;anchors.rightMargin:10;anchors.verticalCenter:parent.verticalCenter;implicitWidth:92;label:'Details';glyph:'\uf05a';onActivated:{if(modelData.kind==='phone'){PhoneBridge.selectedId=modelData.phoneId;ShellState.dropdownAnchorX=ShellState.anchorFor('phone');ShellState.dropdown='phone';}else if(modelData.kind==='bluetooth'){ShellState.dropdownAnchorX=ShellState.anchorFor('bluetooth');ShellState.dropdown='bluetooth';}else {ShellState.systemPage=1;ShellState.dropdownAnchorX=ShellState.anchorFor('system');ShellState.dropdown='system';}}}
      }
     }
    }
   }
  }
  Text {width:parent.width;text:Power.batteryError||Power.error||((Power.details.model||'Battery')+' · '+(Power.details.technology||'')+' · '+(Power.details.cycles===null||Power.details.cycles===undefined?'Cycles unavailable':Power.details.cycles+' cycles reported by firmware'));wrapMode:Text.Wrap;color:Power.batteryError||Power.error?Theme.signalRed:Theme.paperMuted;font.family:Appearance.font.ui;font.pixelSize:10}
 }
}
