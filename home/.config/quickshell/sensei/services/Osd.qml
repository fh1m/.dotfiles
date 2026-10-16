pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Which of the two popups is up, and for how long. They show on a change and
// never at start-up: nothing shows until the timer below has armed them, so the
// sources' starting values do not pop a panel up when the shell loads.
Singleton {
    id: root

    // "", "volume" or "brightness".
    property string showing: ""
    // What was last shown, kept so the panel does not change identity while it
    // is fading out.
    property string lastShown: "volume"
    property int feedbackCount:0
    property int feedbackExitCode:0
    IpcHandler {target:"volume-feedback";function state():string{return JSON.stringify({enabled:root.feedbackEnabled,armed:root.armed,count:root.feedbackCount,exitCode:root.feedbackExitCode,volume:Audio.volume,muted:Audio.muted});}function toggle():void{root.toggleFeedback();}}
    property bool feedbackEnabled: true
    property string feedbackSink: ""
    property real feedbackVolume: 0
    // An explicit opt-out belongs in Sound, not a hidden environment variable.
    FileView {id:feedbackSettings;path:Quickshell.env("HOME")+"/.config/sensei-den/sound-feedback.json";watchChanges:true;printErrors:false
        onFileChanged:reload()
        onLoaded:{try{root.feedbackEnabled=JSON.parse(text()).enabled!==false;}catch(e){}}
    }
    function toggleFeedback(){feedbackEnabled=!feedbackEnabled;feedbackSettings.setText(JSON.stringify({enabled:feedbackEnabled})+"\n");}
    Timer {id:feedback;interval:180;onTriggered:{
        if(root.feedbackEnabled&&!DesktopTools.quiet&&!Audio.muted&&Audio.volume>0&&Audio.sink?.name===root.feedbackSink&&!sample.running){root.feedbackCount++;sample.running=true;}
    }}
    Process {id:sample;command:["canberra-gtk-play","--id=audio-volume-change","--description=Volume feedback","--property=media.role=event","--property=canberra.cache-control=permanent"];onExited:exitCode=>root.feedbackExitCode=exitCode}
    property bool armed: false
    property string screenName: "eDP-1"
    readonly property var screens: ShellState.screens.filter(s => s.name === screenName)

    function flash(which: string): void {
        if (!armed)
            return;
        screenName = ShellState.focusedScreenName();
        showing = which;
        lastShown = which;
        hide.restart();
    }

    // Long enough for the sources to report their starting values, which would
    // otherwise pop both panels up the moment the shell loads.
    Timer {
        interval: 1200
        running: true
        onTriggered: {root.armed = true;root.feedbackVolume=Audio.volume;root.feedbackSink=Audio.sink?.name||"";}
    }

    Timer {
        id: hide

        interval: 1800
        onTriggered: root.showing = ""
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.flash("volume");
            const sink=Audio.sink?.name||"";
            if(root.armed&&sink===root.feedbackSink&&Math.abs(Audio.volume-root.feedbackVolume)>.001)feedback.restart();
            root.feedbackSink=sink;root.feedbackVolume=Audio.volume;
        }
        function onSinkChanged():void {feedback.stop();root.feedbackSink="";}

        function onMutedChanged(): void {
            root.flash("volume");
        }
    }

    Connections {
        target: Brightness

        function onValueChanged(): void {
            root.flash("brightness");
        }
    }
}
