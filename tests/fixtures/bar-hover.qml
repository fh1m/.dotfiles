import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
ShellRoot {
    property int step:0
    FileView {id:owner;path:Quickshell.env("XDG_RUNTIME_DIR")+"/sensei-den-cursor-owner.json"}
    function fail(message:string):void {console.log("PROOF_FAIL "+message);Qt.exit(1);}
    Timer {
        interval:20;running:true;repeat:true
        onTriggered:{
            if(step===0&&ShellState.cursorOwnershipKnown){
                ShellState.setBarHover("top","fixture-a",true);
                if(ShellState.barHovered){fail("parked cursor counted as active hover");return;}
                owner.setText(JSON.stringify({version:1,owned:true,output:"fixture-a"}));step=1;
            } else if(step===1&&ShellState.cursorOwned){
                ShellState.setBarHover("bottom","fixture-b",true);
                ShellState.setBarHover("top","fixture-a",false);
                if(!ShellState.barHovered){fail("one bar leaving erased another bar hover");return;}
                owner.setText(JSON.stringify({version:1,owned:false,output:""}));step=2;
            } else if(step===2&&!ShellState.cursorOwned){
                if(ShellState.barHovered||Object.keys(ShellState.barHovers).length!==1){fail("ownership transition did not disqualify stale hover");return;}
                ShellState.setBarHover("bottom","fixture-b",false);
                if(Object.keys(ShellState.barHovers).length!==0){fail("destroyed bar retained hover state");return;}
                console.log("PROOF_PASS parked hover -> local ownership -> overlapping bars -> remote ownership -> cleanup");Qt.quit();
            }
        }
    }
    Timer {interval:15000;running:true;onTriggered:fail("ownership observation timed out at step "+step)}
}
