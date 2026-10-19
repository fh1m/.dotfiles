import Quickshell
import Quickshell.Io
import qs.services
Scope {
    Variants {model:ShellState.screens;MusicVideoSurface {}}
    IpcHandler {
        target:'music-video-window'
        function mode(value:string,output:string):void{if(['inline','mini','fullscreen'].includes(value))SpotifyDesk.showVideo(value,output);}
        function close():void{SpotifyDesk.closeVideo();}
        function state():string{return SpotifyDesk.videoWindow?SpotifyDesk.videoWindow.describe():JSON.stringify({visible:false,mode:SpotifyDesk.videoMode,display:SpotifyDesk.videoWindowOutput});}
    }
}
