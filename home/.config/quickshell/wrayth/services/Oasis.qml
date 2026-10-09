pragma Singleton
import QtQuick
import Quickshell
import "../noesis-ui" as Shared
Singleton {
 readonly property var state:Shared.NoesisController.state
 readonly property string activeVault:Shared.NoesisController.activeVault
 readonly property bool windowOpen:Shared.NoesisController.windowOpen
 readonly property bool working:Shared.NoesisController.working
 readonly property string error:Shared.NoesisController.error
 readonly property string message:Shared.NoesisController.message
 readonly property var currentContext:Shared.NoesisController.currentContext
 function open(){Shared.NoesisController.open();}
 function close(){Shared.NoesisController.hide();}
 function run(args){Shared.NoesisController.run(args);}
 function note(path){Shared.NoesisController.note(path);}
 function refresh(){Shared.NoesisController.refresh();}
 function preview(path){Shared.NoesisController.preview(path);}
 function cancel(){Shared.NoesisController.cancel();}
}
