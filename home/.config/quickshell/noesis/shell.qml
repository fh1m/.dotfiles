//@ pragma AppId org.fh1m.Noesis
//@ pragma ShellId org.fh1m.Noesis
//@ pragma Env NOESIS_STANDALONE = 1
import QtQuick
import Quickshell
import "ui" as LearningUi
ShellRoot {
 LearningUi.NoesisWindow {}
 Component.onCompleted:LearningUi.NoesisController.open()
}
