import QtQuick
import Quickshell
import "notifications" as Ui
ShellRoot {
    id: root
    property int normalDismissals: 0
    property int heldDismissals: 0
    property int criticalDismissals: 0
    Ui.NotificationCard { id: normal; width:400; height:160; notification:({urgency:1,summary:"Normal",body:"Synthetic expiry check",actions:[]}); onDismissed:root.normalDismissals++ }
    Ui.NotificationCard { id: held; width:400; height:160; notification:({urgency:1,summary:"Held",body:"Synthetic hover check",actions:[]}); onDismissed:root.heldDismissals++ }
    Ui.NotificationCard { id: critical; width:400; height:160; notification:({urgency:2,summary:"Critical",body:"Synthetic persistent check",actions:[]}); onDismissed:root.criticalDismissals++ }
    Timer {interval:150;running:true;onTriggered:held.pauseLifetime(true)}
    Timer {interval:6700;running:true;onTriggered:{
        if(root.normalDismissals!==1||root.heldDismissals!==0||root.criticalDismissals!==0)throw new Error("Notification expired while held or critical");
        for(let i=0;i<30;i++){normal.pauseLifetime(true);normal.pauseLifetime(false);critical.pauseLifetime(true);critical.pauseLifetime(false);}
        held.pauseLifetime(false);
    }}
    Timer {interval:13500;running:true;onTriggered:{
        if(root.normalDismissals!==1||root.heldDismissals!==1||root.criticalDismissals!==0)throw new Error("Notification lifetime did not resume exactly once");
        held.pauseLifetime(true);held.pauseLifetime(false);
        console.log("PROOF_PASS notification expiry and pause");Qt.quit();
    }}
}
