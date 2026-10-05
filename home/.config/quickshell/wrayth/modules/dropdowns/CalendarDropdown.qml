import QtQuick
import QtQuick.Controls
import Quickshell
import qs.components
import qs.config
import qs.services
DropdownFrame {
 headerAccent:Theme.widgetAccent
 id:root;title:"\uf073 Calendar";katakana:"ПЛАН";implicitWidth:1080;fillColor:Theme.widgetGlass;scanlines:false
 property int page:CalendarDesk.page
 property date monthDate:new Date(Number(CalendarDesk.month.slice(0,4)),Number(CalendarDesk.month.slice(5,7))-1,1)
 property string selectedDay:CalendarDesk.selectedDay
 property int editingEvent:0;property int editingTask:0;property bool allDay:false;property int taskFilter:0
 property var reminderOptions:[0,5,10,15,30,60,1440]
 onPageChanged:CalendarDesk.page=page
 onSelectedDayChanged:CalendarDesk.selectedDay=selectedDay
 SystemClock {id:clock;precision:SystemClock.Seconds}
 function monthStep(delta){monthDate=new Date(monthDate.getFullYear(),monthDate.getMonth()+delta,1);CalendarDesk.month=Qt.formatDateTime(monthDate,'yyyy-MM-01');}
 function today(){monthDate=new Date(clock.date.getFullYear(),clock.date.getMonth(),1);selectedDay=Qt.formatDateTime(clock.date,'yyyy-MM-dd');CalendarDesk.month=Qt.formatDateTime(monthDate,'yyyy-MM-01');}
 function editEvent(e){editingEvent=e?.id??0;eventTitle.text=e?.title??'';eventDate.text=e?.date??selectedDay;eventTime.text=e?.time??'09:00';eventLocation.text=e?.location??'';eventNotes.text=e?.notes??'';eventDuration.text=String(e?.duration||30);allDay=!!e?.all_day;reminderOptions=[0,5,10,15,30,60,1440];let lead=e?.lead??10;if(!reminderOptions.includes(lead))reminderOptions=reminderOptions.concat([lead]);eventLead.currentIndex=reminderOptions.indexOf(lead);eventRepeat.currentIndex=['none','daily','weekly','monthly','custom'].indexOf(e?.repeat??'none');page=3;}
 function editTask(t){editingTask=t?.id??0;taskTitle.text=t?.title??'';taskDate.text=t?.date??selectedDay;taskProject.text=t?.project??'Robotics';taskEstimate.text=String(t?.estimate??25);taskPriority.currentIndex=[2,1,0].indexOf(t?.priority??1);page=1;}
 function startTask(id){CalendarDesk.focusAction('reset',{});CalendarDesk.focusAction('settings',{task:id});CalendarDesk.focusAction('start',{});page=2;}
 readonly property var dayEvents:(Demo.active?[]:CalendarDesk.events).filter(e=>e.date===selectedDay&&e.category!=='Pomodoro')
 readonly property var dayTasks:(Demo.active?[]:CalendarDesk.tasks).filter(t=>!t.archived&&!t.done&&t.date===selectedDay)
 readonly property string todayKey:Qt.formatDateTime(clock.date,'yyyy-MM-dd')
 readonly property int pendingTasks:(Demo.active?[]:CalendarDesk.tasks).filter(t=>!t.archived&&!t.done&&t.date<=todayKey).length
 readonly property var f:CalendarDesk.focusState
 Connections {target:CalendarDesk;function onPageChanged(){root.page=CalendarDesk.page;}function onSaved(){if(CalendarDesk.operation==='task-save'){root.editingTask=0;taskTitle.text='';}else{root.editingEvent=0;root.selectedDay=eventDate.text;root.monthDate=new Date(Number(root.selectedDay.slice(0,4)),Number(root.selectedDay.slice(5,7))-1,1);CalendarDesk.month=Qt.formatDateTime(root.monthDate,'yyyy-MM-01');eventTitle.text='';root.page=0;}}}
 Column {width:parent.width;spacing:12
 ChamferPanel {width:parent.width;height:38;chamfer:6;scanlines:false;fillColor:Theme.alpha(Theme.widgetSurface,.5);borderColor:Theme.widgetBorder
 Text {anchors.left:parent.left;anchors.leftMargin:12;anchors.verticalCenter:parent.verticalCenter;width:parent.width-185;elide:Text.ElideRight;text:WeatherDesk.glyph(WeatherDesk.current.weather_code)+'  '+WeatherDesk.city+' · '+WeatherDesk.summary+' · feels '+(WeatherDesk.current.apparent_temperature??'—')+'°C · humidity '+(WeatherDesk.current.relative_humidity_2m??'—')+'%';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetText}
 ControlTile {anchors.right:parent.right;anchors.rightMargin:5;anchors.verticalCenter:parent.verticalCenter;implicitHeight:28;implicitWidth:155;label:'Weather details';onActivated:ShellState.dropdown='weather'}
 }
 Row {width:parent.width;spacing:12
 Repeater {model:['Today · Dhaka','Task queue','Focus cycle']
 ChamferPanel {id:calendarMetric;required property string modelData;required property int index;property string value:index===0?Qt.formatDateTime(clock.date,'dddd, dd MMM · hh:mm AP'):index===1?root.pendingTasks+' due / overdue · '+(Demo.active?[]:CalendarDesk.tasks).filter(t=>!t.archived&&t.done).length+' completed':(root.f.running?(root.f.phase==='focus'?'Focus ':'Break ')+CalendarDesk.formatSeconds(CalendarDesk.focusRemaining(clock.date.getTime())):'Ready · '+root.f.focus+' min')+' · '+root.f.completed+' sessions';width:(parent.width-24)/3;height:60;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:10;spacing:6;Text {text:calendarMetric.modelData;font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}Text {width:parent.width;text:calendarMetric.value;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetAccent;elide:Text.ElideRight}}
 }}
 }
 Row {width:parent.width;spacing:8
 Repeater {model:[{name:'Calendar',glyph:'\uf073'},{name:'Tasks',glyph:'\uf0ae'},{name:'Focus / timers',glyph:'\uf2f2'},{name:'Events / reminders',glyph:'\uf271'},{name:'World time',glyph:'\uf0ac'}]
 ControlTile {required property var modelData;required property int index;implicitWidth:(parent.width-32)/5;implicitHeight:32;label:modelData.name;glyph:modelData.glyph;navigation:true;selected:root.page===index;onActivated:root.page=index}
 }
 }
 Item {width:parent.width;height:560
 // Month and selected-day agenda use the entire available width.
 Row {anchors.fill:parent;spacing:12;visible:root.page===0
 Column {width:624;spacing:10
 Row {height:34;spacing:8;ControlTile {implicitWidth:44;implicitHeight:34;label:'‹';onActivated:root.monthStep(-1)}Text {width:355;anchors.verticalCenter:parent.verticalCenter;text:Qt.formatDateTime(root.monthDate,'MMMM yyyy');font.family:Appearance.font.ui;font.pixelSize:23;color:Theme.widgetText}ControlTile {implicitWidth:44;implicitHeight:34;label:'›';onActivated:root.monthStep(1)}ControlTile {implicitWidth:100;implicitHeight:34;label:'Today';onActivated:root.today()}}
 Row {height:22;spacing:6;Repeater {model:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];Text {required property string modelData;width:84;text:modelData;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted;horizontalAlignment:Text.AlignHCenter}}}
 Grid {columns:7;spacing:6;width:624;height:408
 Repeater {model:42
 ChamferPanel {id:day;required property int index;property date value:new Date(root.monthDate.getFullYear(),root.monthDate.getMonth(),1-((root.monthDate.getDay()+6)%7)+index);property string key:Qt.formatDateTime(value,'yyyy-MM-dd');property int eventCount:(Demo.active?[]:CalendarDesk.events).filter(e=>e.date===key&&e.category!=='Pomodoro').length;property int todoCount:(Demo.active?[]:CalendarDesk.tasks).filter(t=>!t.archived&&!t.done&&t.date===key).length;property bool selected:key===root.selectedDay;width:84;height:63;chamfer:6;scanlines:false;fillColor:selected?Theme.blend(Theme.widgetSurface,Theme.widgetAccent,.2):dayPointer.containsMouse?Theme.widgetRaised:Theme.widgetSurface;borderColor:key===root.todayKey?Theme.widgetAccent:selected?Theme.widgetAccent:Theme.widgetBorder;borderWidth:selected?2:1;opacity:value.getMonth()===root.monthDate.getMonth()?1:.45
 Text {x:9;y:6;text:day.value.getDate();font.family:Appearance.font.ui;font.pixelSize:18;color:day.selected?Theme.widgetAccent:Theme.widgetText}
 Row {x:9;anchors.bottom:parent.bottom;anchors.bottomMargin:8;spacing:7;Text {visible:day.eventCount>0;text:'\uf073 '+day.eventCount;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.widgetAccent}Text {visible:day.todoCount>0;text:'\uf0ae '+day.todoCount;font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.widgetAccent}}
 Behavior on fillColor {ColorAnimation {duration:140}}
 MouseArea {id:dayPointer;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:root.selectedDay=day.key;onDoubleClicked:root.editEvent(null)}
 }
 }
 }
 Row {spacing:8;ControlTile {implicitWidth:303;label:'New reminder';glyph:'\uf067';onActivated:root.editEvent(null)}ControlTile {implicitWidth:303;label:'New robotics task';glyph:'\uf0ae';onActivated:root.editTask(null)}}
 }
 Column {width:parent.width-636;spacing:10
 Text {width:parent.width;text:'Agenda · '+root.selectedDay;font.family:Appearance.font.ui;font.pixelSize:16;color:Theme.widgetAccent}
 ListView {width:parent.width;height:275;clip:true;spacing:7;model:root.dayEvents;ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:97;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:10;spacing:7;Text {width:parent.width;text:(modelData.all_day?'All day':modelData.time)+' · '+modelData.title;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;elide:Text.ElideRight}Text {width:parent.width;text:modelData.duration+' min · remind '+modelData.lead+' min before'+(modelData.location?' · '+modelData.location:'');font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;elide:Text.ElideRight}Row {spacing:6;ControlTile {implicitWidth:92;implicitHeight:26;label:'Edit';onActivated:root.editEvent(modelData)}ControlTile {implicitWidth:110;implicitHeight:26;label:modelData.repeat==='none'?'Complete':'End series';onActivated:CalendarDesk.action('done',modelData.id)}ControlTile {visible:modelData.repeat!=='none';implicitWidth:96;implicitHeight:26;label:'Skip date';onActivated:CalendarDesk.action('skip',modelData.id+':'+modelData.occurrence)}}}
 }
 ChamferPanel {anchors.fill:parent;visible:root.dayEvents.length===0;fillColor:Theme.alpha(Theme.widgetSurface,.7);chamfer:6;scanlines:false;borderColor:Theme.widgetBorder;Column {anchors.centerIn:parent;spacing:10;Text {anchors.horizontalCenter:parent.horizontalCenter;text:'\uf073';font.family:Appearance.font.ui;font.pixelSize:32;color:Theme.widgetAccent}Text {text:'Sensei, this day is yours to plan.';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}ControlTile {anchors.horizontalCenter:parent.horizontalCenter;label:'Schedule a reminder';onActivated:root.editEvent(null)}}}
 }
 Row {width:parent.width;Text {width:parent.width-90;text:'Tasks for this day';font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetAccent}ControlTile {implicitWidth:85;implicitHeight:26;label:'All tasks';onActivated:root.page=1}}
 ListView {width:parent.width;height:202;clip:true;spacing:6;model:root.dayTasks;ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:59;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;Rectangle {width:3;height:parent.height;color:modelData.priority===2?Theme.widgetAccent:Theme.widgetAccent}Text {x:12;y:8;width:parent.width-94;text:modelData.title;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;elide:Text.ElideRight}Text {x:12;y:31;text:modelData.project+' · '+modelData.estimate+' min';font.family:Appearance.font.ui;font.pixelSize:10;color:Theme.widgetMuted}ControlTile {anchors.right:parent.right;anchors.rightMargin:7;anchors.verticalCenter:parent.verticalCenter;implicitWidth:76;implicitHeight:29;label:'Focus';onActivated:root.startTask(modelData.id)}}
 Text {anchors.centerIn:parent;visible:root.dayTasks.length===0;text:'No tasks assigned · add a bench test or study block.';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;wrapMode:Text.Wrap;width:parent.width-20;horizontalAlignment:Text.AlignHCenter}
 }
 }
 }
 // Tasks: filters, check-off, estimates, project tags and task-linked focus.
 Row {anchors.fill:parent;spacing:12;visible:root.page===1
 Column {width:680;spacing:10
 Row {spacing:8;DeskComboBox {width:190;height:36;model:['Open tasks','Due / overdue','Completed','Archived'];currentIndex:root.taskFilter;onActivated:root.taskFilter=currentIndex}DeskTextField {id:taskSearch;width:482;placeholderText:'Find a task or project'}}
 ListView {id:taskList;width:parent.width;height:514;clip:true;spacing:7;model:(Demo.active?[]:CalendarDesk.tasks).filter(t=>(root.taskFilter===3?t.archived:!t.archived&&(root.taskFilter===2?t.done:!t.done))&&(root.taskFilter!==1||t.date<=root.todayKey)&&(t.title+' '+t.project).toLowerCase().includes(taskSearch.text.toLowerCase()));ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:75;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Rectangle {width:3;height:parent.height;color:modelData.done?Theme.widgetFaint:modelData.priority===2?Theme.widgetAccent:Theme.widgetAccent}
 Row {anchors.fill:parent;anchors.margins:10;spacing:8;ControlTile {implicitWidth:34;implicitHeight:34;anchors.verticalCenter:parent.verticalCenter;glyph:modelData.done||modelData.archived?'\uf0e2':'\uf00c';onActivated:CalendarDesk.action(modelData.done||modelData.archived?'task-restore':'task-done',modelData.id)}Column {width:parent.width-247;spacing:7;Text {width:parent.width;text:modelData.title;font.family:Appearance.font.ui;font.pixelSize:14;font.strikeout:!!modelData.done;color:modelData.done?Theme.widgetMuted:Theme.widgetText;elide:Text.ElideRight}Text {width:parent.width;text:modelData.date+' · '+modelData.project+' · '+modelData.estimate+' min planned / '+modelData.minutes+' focused';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;elide:Text.ElideRight}}ControlTile {implicitWidth:77;implicitHeight:32;label:'Focus';enabled:!modelData.done&&!modelData.archived;onActivated:root.startTask(modelData.id)}ControlTile {implicitWidth:67;implicitHeight:32;label:'Edit';onActivated:root.editTask(modelData)}ControlTile {implicitWidth:35;implicitHeight:32;glyph:'\uf187';onActivated:CalendarDesk.action('task-archive',modelData.id)}}
 }
 Text {anchors.centerIn:parent;visible:taskList.count===0;width:parent.width-40;text:'Sensei, add your next robotics task.\nProject tags, priorities and estimated time keep the day practical.';wrapMode:Text.Wrap;horizontalAlignment:Text.AlignHCenter;font.family:Appearance.font.ui;font.pixelSize:15;color:Theme.widgetMuted}
 }
 }
 ChamferPanel {width:parent.width-692;height:560;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:14;spacing:12
 Text {text:root.editingTask?'Edit task':'New task';font.family:Appearance.font.ui;font.pixelSize:18;color:Theme.widgetAccent}
 DeskTextField {id:taskTitle;width:parent.width;placeholderText:'Task · e.g. calibrate encoder / train policy'}
 Text {text:'Due date and project';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 DeskTextField {id:taskDate;width:parent.width;text:root.selectedDay;placeholderText:'YYYY-MM-DD'}
 DeskTextField {id:taskProject;width:parent.width;text:'Robotics';placeholderText:'Project / robot / course'}
 Text {text:'Priority and focused-time estimate';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8;DeskComboBox {id:taskPriority;width:(parent.parent.width-8)/2;height:36;model:['High priority','Normal priority','Low priority'];currentIndex:1}DeskTextField {id:taskEstimate;width:(parent.parent.width-8)/2;text:'25';placeholderText:'Minutes';validator:IntValidator {bottom:1;top:1440}}}
 ControlTile {implicitWidth:parent.width;label:root.editingTask?'Save task':'Add task';glyph:'\uf0c7';onActivated:CalendarDesk.taskSave({id:root.editingTask,title:taskTitle.text,date:taskDate.text,project:taskProject.text,priority:[2,1,0][taskPriority.currentIndex],estimate:parseInt(taskEstimate.text)||25})}
 ControlTile {implicitWidth:parent.width;label:'Clear / new task';onActivated:root.editTask(null)}
 Text {width:parent.width;text:'Sensei, select Focus on a task to start a Pomodoro linked to it. Completed sessions add focused minutes to that task. Archiving preserves its record.';wrapMode:Text.Wrap;font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}
 }
 }
 }
 // Pomodoro, custom timers, persistent stopwatch and laps.
 Row {anchors.fill:parent;spacing:12;visible:root.page===2
 Column {width:624;spacing:12
 ChamferPanel {width:parent.width;height:322;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Text {x:14;y:13;width:parent.width-28;text:(CalendarDesk.tasks.find(t=>t.id===root.f.task)?.title??'Free focus')+' · '+root.f.completed+' sessions completed';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted;elide:Text.ElideRight}
 Canvas {id:dial;anchors.centerIn:parent;width:250;height:250;property real progress:Math.max(0,Math.min(1,1-CalendarDesk.focusRemaining(clock.date.getTime())/((root.f[root.f.phase]||25)*60)));onProgressChanged:requestPaint();property color ink:Theme.widgetAccent;onInkChanged:requestPaint();onPaint:{const c=getContext('2d');c.reset();c.lineWidth=8;c.strokeStyle=Theme.widgetBorder;c.beginPath();c.arc(125,125,110,0,Math.PI*2);c.stroke();c.strokeStyle=ink;c.lineCap='round';c.beginPath();c.arc(125,125,110,-Math.PI/2,-Math.PI/2+Math.PI*2*progress);c.stroke();}}
 Column {anchors.centerIn:parent;spacing:10;Text {anchors.horizontalCenter:parent.horizontalCenter;text:root.f.phase==='focus'?'Focus':root.f.phase==='long'?'Long break':'Short break';font.family:Appearance.font.ui;font.pixelSize:15;color:Theme.widgetMuted}Text {text:CalendarDesk.formatSeconds(CalendarDesk.focusRemaining(clock.date.getTime()));font.family:Appearance.font.ui;font.pixelSize:46;color:Theme.widgetAccent}Text {anchors.horizontalCenter:parent.horizontalCenter;text:root.f.running?'In progress':'Ready / paused';font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}}
 }
 Row {spacing:8;ControlTile {implicitWidth:205;label:root.f.running?'Pause':'Start / resume';glyph:root.f.running?'\uf04c':'\uf04b';onActivated:CalendarDesk.focusAction(root.f.running?'pause':'resume',{})}ControlTile {implicitWidth:205;label:'Skip phase';glyph:'\uf051';enabled:root.f.running;onActivated:CalendarDesk.focusAction('skip',{})}ControlTile {implicitWidth:198;label:'Reset cycle';glyph:'\uf0e2';onActivated:CalendarDesk.focusAction('reset',{})}}
 Row {spacing:8;DeskTextField {id:customMinutes;width:82;text:'10';placeholderText:'Minutes';validator:IntValidator {bottom:1;top:1440}}DeskTextField {id:customTitle;width:350;placeholderText:'Timer label · bench cooldown / test stop'}ControlTile {implicitWidth:176;implicitHeight:36;label:'Start timer';onActivated:CalendarDesk.timer((parseInt(customMinutes.text)||10)*60,customTitle.text||'Bench timer finished')}}
 ListView {id:timerList;width:parent.width;height:132;clip:true;spacing:6;model:CalendarDesk.upcoming.filter(e=>e.category==='Timer');ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:48;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder;Text {x:12;anchors.verticalCenter:parent.verticalCenter;width:parent.width-132;text:modelData.title+' · '+CalendarDesk.formatSeconds(modelData.occurrence-clock.date.getTime()/1000);font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetText;elide:Text.ElideRight}ControlTile {anchors.right:parent.right;anchors.rightMargin:8;anchors.verticalCenter:parent.verticalCenter;implicitWidth:110;implicitHeight:28;label:'Cancel';onActivated:CalendarDesk.action('done',modelData.id)}}
 Text {anchors.centerIn:parent;visible:timerList.count===0;text:'Independent timers appear here and notify even with the shell closed.';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 }
 }
 ChamferPanel {width:parent.width-636;height:560;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:14;spacing:12
 Text {text:'Cycle settings';font.family:Appearance.font.ui;font.pixelSize:18;color:Theme.widgetAccent}
 Text {text:'Focus / short break · minutes';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8;DeskTextField {id:focusMinutes;width:190;text:String(root.f.focus||25);readOnly:root.f.running;validator:IntValidator {bottom:1;top:240}}DeskTextField {id:shortMinutes;width:190;text:String(root.f.short||5);readOnly:root.f.running;validator:IntValidator {bottom:1;top:240}}}
 Text {text:'Long break / sessions before long break';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}
 Row {spacing:8;DeskTextField {id:longMinutes;width:190;text:String(root.f.long||15);readOnly:root.f.running;validator:IntValidator {bottom:1;top:240}}DeskTextField {id:cycleCount;width:190;text:String(root.f.cycles||4);readOnly:root.f.running;validator:IntValidator {bottom:1;top:12}}}
 Row {spacing:8;ControlTile {implicitWidth:190;label:root.f.auto?'Auto advance · on':'Auto advance · off';selected:root.f.auto;onActivated:CalendarDesk.focusAction('settings',{auto:!root.f.auto})}ControlTile {implicitWidth:190;label:'Apply durations';enabled:!root.f.running;onActivated:CalendarDesk.focusAction('settings',{focus:parseInt(focusMinutes.text)||25,short:parseInt(shortMinutes.text)||5,long:parseInt(longMinutes.text)||15,cycles:parseInt(cycleCount.text)||4})}}
 Text {width:parent.width;text:'Pause before editing durations. Long breaks arrive after the chosen number of completed focus sessions.';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted;wrapMode:Text.Wrap}
 Rectangle {width:parent.width;height:1;color:Theme.widgetBorder}
 Text {text:'Stopwatch · '+CalendarDesk.formatSeconds(CalendarDesk.stopwatchElapsed(clock.date.getTime()));font.family:Appearance.font.ui;font.pixelSize:22;color:Theme.widgetAccent}
 Row {spacing:8;ControlTile {implicitWidth:123;label:CalendarDesk.stopwatchRunning?'Pause':'Start';onActivated:CalendarDesk.stopwatchToggle()}ControlTile {implicitWidth:123;label:'Lap';onActivated:CalendarDesk.stopwatchLap()}ControlTile {implicitWidth:124;label:'Reset';onActivated:CalendarDesk.stopwatchReset()}}
 ListView {width:parent.width;height:116;clip:true;model:CalendarDesk.laps;delegate:Text {required property var modelData;required property int index;width:ListView.view.width;height:24;text:'Lap '+(index+1)+' · '+CalendarDesk.formatSeconds(modelData);font.family:Appearance.font.ui;font.pixelSize:12;color:Theme.widgetMuted}ScrollBar.vertical:DeskScrollBar {}}
 }
 }
 }
 // Event editor uses the same themed fields as the rest of the desk.
 Column {anchors.fill:parent;spacing:10;visible:root.page===3
 Row {spacing:10;DeskTextField {id:eventTitle;width:680;placeholderText:'Event / reminder title'}DeskTextField {id:eventDate;width:175;text:root.selectedDay;placeholderText:'YYYY-MM-DD'}DeskTextField {id:eventTime;width:175;text:'09:00';placeholderText:'HH:MM (24h)'}}
 Row {spacing:10;ControlTile {implicitWidth:125;implicitHeight:36;label:'All day';selected:root.allDay;onActivated:root.allDay=!root.allDay}DeskTextField {id:eventDuration;width:95;text:'30';placeholderText:'Minutes';validator:IntValidator {bottom:1;top:10080}}DeskComboBox {id:eventLead;width:225;height:36;model:root.reminderOptions.map(m=>m===0?'At event time':m===1440?'1 day before':m+' min before');currentIndex:2}DeskComboBox {id:eventRepeat;width:225;height:36;model:['No repeat','Daily','Weekly','Monthly','Imported recurrence']}DeskTextField {id:eventLocation;width:342;placeholderText:'Location / meeting link / robot bench'}}
 DeskTextArea {id:eventNotes;width:parent.width;height:72;placeholderText:'Notes · test plan, dependencies, robot ID, preparation…'}
 Row {spacing:8;ControlTile {implicitWidth:186;label:root.editingEvent?'Save changes':'Create reminder';glyph:'\uf0c7';onActivated:CalendarDesk.save({id:root.editingEvent,title:eventTitle.text,date:eventDate.text,time:root.allDay?'09:00':eventTime.text,duration:parseInt(eventDuration.text)||30,lead:root.reminderOptions[eventLead.currentIndex],repeat:['none','daily','weekly','monthly','custom'][eventRepeat.currentIndex],location:eventLocation.text,notes:eventNotes.text,all_day:root.allDay})}ControlTile {implicitWidth:170;label:'New event';glyph:'\uf067';onActivated:root.editEvent(null)}ControlTile {implicitWidth:170;label:'Import .ics';glyph:'\uf019';onActivated:CalendarDesk.importCalendar()}ControlTile {implicitWidth:170;label:'Export .ics';glyph:'\uf093';onActivated:CalendarDesk.action('export','/home/fh1m/.local/share/sensei-calendar/calendar.ics')}}
 Text {text:'Upcoming entries · '+(Demo.active?[]:CalendarDesk.events).filter(e=>e.category!=='Pomodoro').length;font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetAccent}
 ListView {id:eventList;width:parent.width;height:308;clip:true;spacing:6;model:(Demo.active?[]:CalendarDesk.events).filter(e=>e.category!=='Pomodoro');ScrollBar.vertical:DeskScrollBar {}
 delegate:ChamferPanel {required property var modelData;width:ListView.view.width;height:57;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {x:12;y:8;width:parent.width-332;spacing:6;Text {width:parent.width;text:modelData.date+' '+(modelData.all_day?'All day':modelData.time)+' · '+modelData.title;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;elide:Text.ElideRight}Text {text:modelData.duration+' min · '+modelData.repeat+' · remind '+modelData.lead+' min before';font.family:Appearance.font.ui;font.pixelSize:11;color:Theme.widgetMuted}}
 Row {anchors.right:parent.right;anchors.rightMargin:9;anchors.verticalCenter:parent.verticalCenter;spacing:7;ControlTile {implicitWidth:95;implicitHeight:29;label:'Edit';onActivated:root.editEvent(modelData)}ControlTile {implicitWidth:95;implicitHeight:29;label:'Complete';onActivated:CalendarDesk.action('done',modelData.id)}ControlTile {implicitWidth:95;implicitHeight:29;label:'Remove';onActivated:CalendarDesk.action('delete',modelData.id)}}
 }
 Text {anchors.centerIn:parent;visible:eventList.count===0;text:'Sensei, create a reminder above or import your calendar.';font.family:Appearance.font.ui;font.pixelSize:14;color:Theme.widgetMuted}
 }
 }
 Column {anchors.fill:parent;spacing:12;visible:root.page===4
 Grid {width:parent.width;columns:3;spacing:12
 Repeater {model:CalendarDesk.clocks
 ChamferPanel {required property var modelData;width:(parent.width-24)/3;height:130;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:15;spacing:17;Text {text:modelData.name;font.family:Appearance.font.ui;font.pixelSize:21;color:Theme.widgetAccent}Text {width:parent.width;text:modelData.time;font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetText;wrapMode:Text.Wrap}}
 }
 }
 }
 ChamferPanel {width:parent.width;height:264;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
 Column {anchors.fill:parent;anchors.margins:18;spacing:18
 Text {text:'Sensei, today is '+Qt.formatDateTime(clock.date,'dddd, dd MMMM yyyy');font.family:Appearance.font.ui;font.pixelSize:20;color:Theme.widgetText}
 Text {text:'Dhaka · '+Qt.formatDateTime(clock.date,'hh:mm:ss AP')+' · UTC+06';font.family:Appearance.font.ui;font.pixelSize:29;color:Theme.widgetAccent}
 Rectangle {width:parent.width;height:8;radius:6;color:Theme.widgetBorder;Rectangle {width:parent.width*(clock.date.getHours()*3600+clock.date.getMinutes()*60+clock.date.getSeconds())/86400;height:parent.height;radius:6;color:Theme.widgetAccent}}
 Text {text:root.pendingTasks+' tasks due / overdue · '+root.f.completed+' focus sessions · '+CalendarDesk.upcoming.filter(e=>e.date===root.todayKey&&e.category!=='Timer').length+' upcoming events today';font.family:Appearance.font.ui;font.pixelSize:13;color:Theme.widgetMuted}
 Row {spacing:10;ControlTile {implicitWidth:210;label:'Plan today';glyph:'\uf073';onActivated:{root.today();root.page=0}}ControlTile {implicitWidth:210;label:'Start focused work';glyph:'\uf04b';onActivated:root.page=2}ControlTile {implicitWidth:210;label:'Task queue';glyph:'\uf0ae';onActivated:root.page=1}}
 }
 }
 }
 }
 Text {width:parent.width;height:30;text:CalendarDesk.error||'Sensei, your planner is stored locally. Reminders and Pomodoro transitions run independently of the shell. Import / export lives in your local calendar folder.';font.family:Appearance.font.ui;font.pixelSize:11;color:CalendarDesk.error?Theme.widgetAccent:Theme.widgetMuted;wrapMode:Text.Wrap}
 }
}
