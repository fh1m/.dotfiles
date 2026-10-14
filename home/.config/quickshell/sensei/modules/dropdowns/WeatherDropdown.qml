import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;implicitWidth:1080;title:'\uf0c2 Weather';katakana:'ПОГОДА';scanlines:false;fillColor:Theme.widgetGlass
 readonly property var c:WeatherDesk.current
 readonly property var daily:WeatherDesk.data.weather?.daily??({})
 readonly property var hourly:WeatherDesk.page===3?(WeatherDesk.history.history?.hourly??({})):(WeatherDesk.data.weather?.hourly??({}))
 readonly property string date:WeatherDesk.selectedDate
 readonly property int nowIndex:(WeatherDesk.data.weather?.hourly?.time||[]).indexOf(String(root.c.time||'').slice(0,13)+':00')
 readonly property var hours:(hourly.time||[]).map((t,i)=>({time:t,index:i})).filter(r=>r.time.slice(0,10)===root.date)
 function val(value,unit=''){return value===undefined||value===null?'—':Number(value).toLocaleString(Qt.locale(),'f',unit==='°C'?1:0)+unit;}
 Component.onCompleted:WeatherDesk.refresh()
 Column {width:parent.width;spacing:12
 Row {width:parent.width;spacing:8
 DeskTextField {id:cityInput;width:230;height:36;text:WeatherDesk.city;placeholderText:'City';placeholderTextColor:Theme.widgetMuted;color:Theme.widgetText;selectionColor:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:13;onAccepted:WeatherDesk.chooseCity(text.trim())}
 ControlTile {implicitWidth:105;implicitHeight:36;label:'Set city';glyph:'\uf041';onActivated:WeatherDesk.chooseCity(cityInput.text.trim())}
 ControlTile {implicitWidth:105;implicitHeight:36;label:'Refresh';glyph:'\uf021';enabled:!WeatherDesk.loading;onActivated:WeatherDesk.refresh(true)}
 Text {width:570;anchors.verticalCenter:parent.verticalCenter;text:(WeatherDesk.loading?'Updating · ':'')+(WeatherDesk.data.stale?'Cached · ':'')+(WeatherDesk.data.fetched?'Updated '+Qt.formatDateTime(new Date(WeatherDesk.data.fetched*1000),'hh:mm AP'):'')+' · '+(WeatherDesk.data.city?.timezone||'Asia/Dhaka');color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12;elide:Text.ElideRight}
 }
 Row {spacing:8;Repeater {model:['Today','Hourly','Forecast','History'];ControlTile {required property string modelData;required property int index;implicitWidth:257;label:modelData;navigation:true;selected:WeatherDesk.page===index;onActivated:{WeatherDesk.page=index;if(index===3){const yesterday=new Date();yesterday.setDate(yesterday.getDate()-1);WeatherDesk.loadHistory(Qt.formatDateTime(yesterday,'yyyy-MM-dd'));}else WeatherDesk.selectedDate=Qt.formatDateTime(new Date(),'yyyy-MM-dd');}}}}
 Text {width:parent.width;visible:!!WeatherDesk.error;text:WeatherDesk.error;color:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:12;wrapMode:Text.Wrap}
 Item {width:parent.width;height:490;visible:WeatherDesk.page===0
 Row {anchors.fill:parent;spacing:12
 ChamferPanel {width:330;height:490;chamfer:6;scanlines:false;fillColor:Theme.alpha(Theme.widgetSurface,.7);borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:22;spacing:17
 Text {text:WeatherDesk.city;color:Theme.widgetText;font.family:Appearance.font.display;font.pixelSize:27}
 Text {text:WeatherDesk.glyph(root.c.weather_code);color:Theme.widgetAccent;font.family:Appearance.font.icons;font.pixelSize:82}
 Text {text:root.val(root.c.temperature_2m,'°C');color:Theme.widgetText;font.family:Appearance.font.display;font.pixelSize:44}
 Text {text:WeatherDesk.description(root.c.weather_code);color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:17}
 Text {width:parent.width;text:'Feels like '+root.val(root.c.apparent_temperature,'°C')+'\n'+Qt.formatDateTime(new Date(),'dddd, dd MMMM');color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:13;lineHeight:1.6;wrapMode:Text.Wrap}
 Text {width:parent.width;text:'Air quality · US AQI '+root.val(WeatherDesk.data.air?.current?.us_aqi)+'\nPM2.5 '+root.val(WeatherDesk.data.air?.current?.pm2_5,' µg/m³')+' · PM10 '+root.val(WeatherDesk.data.air?.current?.pm10,' µg/m³');color:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:12;lineHeight:1.5;wrapMode:Text.Wrap}
 }
 }
 Column {width:parent.width-342;spacing:12
 Grid {columns:3;spacing:10
 Repeater {model:[['\uf043','Humidity',root.val(root.c.relative_humidity_2m,'%')],['\uf0c2','Wind',root.val(root.c.wind_speed_10m,' km/h')],['\uf14e','Direction',root.val(root.c.wind_direction_10m,'°')],['\uf043','Rain',root.val(root.c.precipitation,' mm')],['\uf0c2','Cloud cover',root.val(root.c.cloud_cover,'%')],['\uf0e4','Pressure',root.val(root.c.pressure_msl,' hPa')],['\uf0c2','Gusts',root.val(root.c.wind_gusts_10m,' km/h')],['\uf185','Sunrise',(WeatherDesk.dated(Qt.formatDateTime(new Date(),'yyyy-MM-dd'))?.sunrise||'—').slice(-5)],['\uf186','Sunset',(WeatherDesk.dated(Qt.formatDateTime(new Date(),'yyyy-MM-dd'))?.sunset||'—').slice(-5)],['\uf185','UV index',root.val(WeatherDesk.data.weather?.hourly?.uv_index?.[root.nowIndex])],['\uf06e','Visibility',root.val((WeatherDesk.data.weather?.hourly?.visibility?.[root.nowIndex]??0)/1000,' km')],['\uf043','Rain chance',root.val(WeatherDesk.data.weather?.hourly?.precipitation_probability?.[root.nowIndex],'%')]]
 ChamferPanel {required property var modelData;width:227;height:88;chamfer:6;scanlines:false;fillColor:Theme.alpha(Theme.widgetSurface,.7);borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:13;spacing:9;Row {spacing:8;Text {text:modelData[0];font.family:Appearance.font.icons;font.pixelSize:14;color:Theme.widgetAccent}Text {text:modelData[1];font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}}Text {text:modelData[2];font.family:Appearance.font.display;font.pixelSize:21;color:Theme.widgetText}}
 }}}
 ChamferPanel {width:parent.width;height:96;fillColor:Theme.alpha(Theme.widgetSurface,.7);chamfer:6;scanlines:false;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:13;spacing:10
 Text {text:'Daylight / outdoor work';color:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:14}
 Text {width:parent.width;text:'Today · UV '+root.val(WeatherDesk.dated(Qt.formatDateTime(new Date(),'yyyy-MM-dd'))?.uv_index_max)+' · rain chance '+root.val(WeatherDesk.dated(Qt.formatDateTime(new Date(),'yyyy-MM-dd'))?.precipitation_probability_max,'%')+'\nModelled conditions · Open-Meteo / CAMS';color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:13;lineHeight:1.8;wrapMode:Text.Wrap}
 }
 }
 }
 }
 }
 Column {width:parent.width;spacing:10;visible:WeatherDesk.page===1||WeatherDesk.page===3
 Row {spacing:8
 ControlTile {implicitWidth:45;label:'‹';onActivated:{const d=new Date(root.date+'T12:00:00');d.setDate(d.getDate()-1);const key=Qt.formatDateTime(d,'yyyy-MM-dd');if(WeatherDesk.page===3)WeatherDesk.loadHistory(key);else WeatherDesk.selectedDate=key;}}
 DeskTextField {id:dateField;width:170;height:38;text:root.date;placeholderText:'yyyy-MM-dd';placeholderTextColor:Theme.widgetMuted;color:Theme.widgetText;selectionColor:Theme.widgetAccent;font.family:Appearance.font.ui;onAccepted:{if(WeatherDesk.page===3)WeatherDesk.loadHistory(text);else WeatherDesk.selectedDate=text;}}
 ControlTile {implicitWidth:45;label:'›';onActivated:{const d=new Date(root.date+'T12:00:00');d.setDate(d.getDate()+1);const key=Qt.formatDateTime(d,'yyyy-MM-dd');if(WeatherDesk.page===3)WeatherDesk.loadHistory(key);else WeatherDesk.selectedDate=key;}}
 ControlTile {implicitWidth:90;label:'Load date';onActivated:{if(WeatherDesk.page===3)WeatherDesk.loadHistory(dateField.text);else WeatherDesk.selectedDate=dateField.text;}}
 Text {width:660;anchors.verticalCenter:parent.verticalCenter;text:WeatherDesk.page===3?(WeatherDesk.history.historyLabel||'Select a past date'):'Temperature line · precipitation bars';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted;elide:Text.ElideRight}
 }
 ChamferPanel {width:parent.width;height:140;fillColor:Theme.alpha(Theme.widgetSurface,.7);borderColor:Theme.widgetBorder;chamfer:6;scanlines:false
 Canvas {id:chart;anchors.fill:parent;anchors.margins:12;property var rows:root.hours;property var values:root.hourly
 onRowsChanged:requestPaint();onValuesChanged:requestPaint();onWidthChanged:requestPaint()
 onPaint:{const ctx=getContext('2d');ctx.reset();const rows=root.hours;if(!rows.length)return;const temps=rows.map(r=>Number(root.hourly.temperature_2m?.[r.index]??0));const lo=Math.min(...temps)-2,hi=Math.max(...temps)+2;ctx.strokeStyle=Theme.widgetBorder;ctx.lineWidth=1;for(let i=1;i<4;i++){ctx.beginPath();ctx.moveTo(0,height*i/4);ctx.lineTo(width,height*i/4);ctx.stroke();}ctx.fillStyle=Theme.alpha(Theme.widgetAccent,.3);for(let i=0;i<rows.length;i++){const rain=root.hourly.precipitation?.[rows[i].index]||0;ctx.fillRect(i*width/rows.length,height-Math.min(height*.7,rain*14),width/rows.length-3,Math.min(height*.7,rain*14));}ctx.strokeStyle=Theme.widgetAccent;ctx.lineWidth=2;ctx.beginPath();temps.forEach((v,i)=>{const x=i*width/Math.max(1,temps.length-1),y=height-10-(v-lo)/(hi-lo)*(height-20);if(i)ctx.lineTo(x,y);else ctx.moveTo(x,y);});ctx.stroke();}
 }
 }
 Row {spacing:8;Repeater {model:['Time','Conditions','Temp','Feels','Rain chance','Rain','Humidity','Wind km/h','Visibility'];Text {required property string modelData;width:modelData==='Conditions'?190:98;text:modelData;color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:11}}}
 ListView {width:parent.width;height:285;clip:true;spacing:3;model:root.hours;ScrollBar.vertical:DeskScrollBar {}
 delegate:Rectangle {required property var modelData;width:ListView.view.width;height:35;color:index%2?Theme.alpha(Theme.widgetSurface,.5):'transparent';property int index:modelData.index
 Row {anchors.verticalCenter:parent.verticalCenter;spacing:8;Repeater {model:[modelData.time.slice(-5),WeatherDesk.description(root.hourly.weather_code?.[index]),root.val(root.hourly.temperature_2m?.[index],'°C'),root.val(root.hourly.apparent_temperature?.[index],'°C'),root.val(root.hourly.precipitation_probability?.[index],'%'),root.val(root.hourly.precipitation?.[index],' mm'),root.val(root.hourly.relative_humidity_2m?.[index],'%'),root.val(root.hourly.wind_speed_10m?.[index])+'/'+root.val(root.hourly.wind_gusts_10m?.[index]),root.val((root.hourly.visibility?.[index]??0)/1000,' km')]
 Text {required property string modelData;required property int index;width:index===1?190:98;text:modelData;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetText;elide:Text.ElideRight}
 }}
 }
 }
 Text {visible:root.hours.length===0;text:WeatherDesk.loading?'Fetching this day…':'No hourly data for this date.';color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:13}
 }
 Column {width:parent.width;spacing:10;visible:WeatherDesk.page===2
 Text {text:'Select a day to inspect its hourly conditions';color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:13}
 ListView {width:parent.width;height:470;clip:true;spacing:6;model:(root.daily.time||[]).filter(t=>t>=Qt.formatDateTime(new Date(),'yyyy-MM-dd'));ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property string modelData;property var day:WeatherDesk.dated(modelData);width:ListView.view.width;height:63;fillColor:Theme.alpha(Theme.widgetSurface,.7);chamfer:6;scanlines:false;borderColor:Theme.widgetBorder
 Row {anchors.fill:parent;anchors.margins:13;spacing:14
 Text {width:175;anchors.verticalCenter:parent.verticalCenter;text:Qt.formatDateTime(new Date(modelData+'T12:00:00'),'dddd, dd MMM');color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:13}
 Text {width:32;anchors.verticalCenter:parent.verticalCenter;text:WeatherDesk.glyph(day?.weather_code);color:Theme.widgetAccent;font.family:Appearance.font.icons;font.pixelSize:23}
 Text {width:260;anchors.verticalCenter:parent.verticalCenter;text:WeatherDesk.description(day?.weather_code);color:Theme.widgetText;font.family:Appearance.font.ui;font.pixelSize:13}
 Text {width:160;anchors.verticalCenter:parent.verticalCenter;text:root.val(day?.temperature_2m_min,'°C')+' / '+root.val(day?.temperature_2m_max,'°C');color:Theme.widgetAccent;font.family:Appearance.font.ui;font.pixelSize:13}
 Text {width:315;anchors.verticalCenter:parent.verticalCenter;text:'Rain '+root.val(day?.precipitation_probability_max,'%')+' · '+root.val(day?.precipitation_sum,' mm')+' · wind '+root.val(day?.wind_speed_10m_max,' km/h');color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:12}
 }
 MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{WeatherDesk.selectedDate=modelData;WeatherDesk.page=1;}}
 }
 }
 }
 Text {width:parent.width;text:'Open-Meteo · modelled weather · CAMS air quality · '+WeatherDesk.city+' · °C / km/h';color:Theme.widgetMuted;font.family:Appearance.font.ui;font.pixelSize:10}
 }
}
