import QtQuick
import Quickshell
import qs.services
ShellRoot {
    property int step:0
    function fail(message:string):void {console.log("PROOF_FAIL "+message);Qt.exit(1);}
    Connections {
        target:LiveMonitor
        function onDataChanged():void {
            if(Demo.active&&LiveMonitor.data.host==="SYNTHETIC_PRIVATE_HOST")fail("late unredacted sample became visible");
        }
    }
    Timer {
        interval:20;running:true;repeat:true
        onTriggered:{
            if(step===0&&LiveMonitor.data.host==="SYNTHETIC_PRIVATE_HOST"){
                step=1;Demo.active=true;
            } else if(step===1&&LiveMonitor.data.private===true){
                if(LiveMonitor.data.host!=="Private"||LiveMonitor.data.ips.length!==0||Object.keys(LiveMonitor.data.extra).length!==0){fail("private sample kept identifiers");return;}
                console.log("PROOF_PASS private transition rejects in-flight unredacted frame");Qt.quit();
            }
        }
    }
    Timer {interval:15000;running:true;onTriggered:fail("privacy handshake timed out at step "+step)}
}
