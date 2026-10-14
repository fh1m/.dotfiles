pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
Singleton {
 id:root
 property var data:({});property var history:({});property bool loading:false;property string error:"";property string operation:"current";property var pending:[]
 property int page:0
 property string selectedDate:Qt.formatDateTime(new Date(),'yyyy-MM-dd')
 readonly property var current:data.weather?.current??({})
 readonly property string city:data.city?.name||'Dhaka'
 readonly property string summary:current.temperature_2m!==undefined?Math.round(current.temperature_2m)+'°C · '+description(current.weather_code):'Weather loading…'
 function description(code){if(code===undefined||code===null)return 'Unavailable';if(code===0)return 'Clear sky';if(code<=3)return ['','Mostly clear','Partly cloudy','Overcast'][code];if(code<=48)return 'Fog';if(code<=57)return 'Drizzle';if(code<=67)return 'Rain';if(code<=77)return 'Snow';if(code<=82)return 'Rain showers';if(code<=86)return 'Snow showers';return 'Thunderstorms';}
 function glyph(code){if(code===undefined||code===null)return '\uf0c2';if(code===0)return '\uf185';if(code<=2)return '\uf0c2';if(code<=3)return '\uf0c2';if(code<=48)return '\uf0c2';if(code<=67||code>=80&&code<=82)return '\uf043';if(code<90)return '\uf2dc';return '\uf0e7';}
 function refresh(force=false){run(force?'force':'current',[]);}
 function run(action,args){if(proc.running){pending=[action,args];return;}operation=action;loading=true;error='';proc.command=['@HOME@/.local/bin/sensei-weather',action].concat(args);proc.running=true;}
 function chooseCity(value){run('city',[value]);}
 function loadHistory(date){selectedDate=date;run('history',[date]);}
 function dated(day){const d=data.weather?.daily??({});const i=(d.time||[]).indexOf(day);if(i<0)return null;const row={date:day};for(const key of Object.keys(d))if(Array.isArray(d[key]))row[key]=d[key][i];return row;}
 Process {id:proc
 stdout:StdioCollector {onStreamFinished:{try{const result=JSON.parse(text);if(root.operation==='history')root.history=result;else if(result.weather)root.data=result;root.error=result.error||'';}catch(e){root.error=String(e);}}}
 onExited:{root.loading=false;if(root.pending.length){const next=root.pending;root.pending=[];root.run(next[0],next[1]);}}
 }
 Timer {interval:900000;running:true;repeat:true;triggeredOnStart:true;onTriggered:root.refresh()}
}
