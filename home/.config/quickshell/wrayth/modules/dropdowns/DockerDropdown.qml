import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services
DropdownFrame {
 id:root;title:"\uf308 Docker · robotics lab";katakana:"КОНТЕЙНЕРЫ";implicitWidth:1080
 greeting:"Sensei, your robotics environments, GPU workloads and ARM builds are within reach."
 property string filter:"";property string session:"robotics";property string confirm:"";property string project:"";property string archive:"/home/fh1m/Documents/docker-image.tar";property string localPath:"/home/fh1m/Phone/Transfers";property string remotePath:"/workspace";property string commandDraft:"";property string experimentName:"robotics-run";property string experimentCommand:"";property string imageDraft:"";property string workspace:"/home/fh1m";property string runName:"sensei-lab";property string runCommand:"/bin/sh";property string platform:"linux/amd64";property bool gpu:false;property bool hostNet:false;property bool hostIpc:false;property string serial:"";property string rosDomain:"0"
 function destroy(name,args){let key=name+':'+JSON.stringify(args);if(confirm!==key){confirm=key;DockerLab.message='Click the same removal / kill action again to confirm.';return;}confirm='';DockerLab.action(name,args);}
 FolderDialog {id:folder;title:'Sensei, choose a build/workspace folder';onVisibleChanged:ShellState.externalDialogOpen=visible;onAccepted:root.workspace=decodeURIComponent(String(selectedFolder).replace(/^file:\/\//,''))}
 FileDialog {id:composePicker;title:'Choose Compose YAML';nameFilters:['Compose (*.yaml *.yml)'];onVisibleChanged:ShellState.externalDialogOpen=visible;onAccepted:root.project=decodeURIComponent(String(selectedFile).replace(/^file:\/\//,''))}
 Column {width:parent.width;spacing:10
  Row {spacing:7;Repeater {model:['Containers','Images','Launch','Compose','Storage / Net','tmux','ARM / GPU','Tasks'];ControlTile {required property string modelData;required property int index;label:modelData;implicitWidth:Math.floor((root.width-28-49)/8);implicitHeight:32;navigation:true;selected:DockerLab.page===index;onActivated:{DockerLab.page=index;root.confirm='';}}}}
  Row {spacing:8;DeskTextField {width:490;placeholderText:'Filter names, images, status';text:root.filter;onTextChanged:root.filter=text}ControlTile {label:'Refresh';glyph:'\uf021';implicitWidth:110;onActivated:DockerLab.refresh()}Text {anchors.verticalCenter:parent.verticalCenter;text:'Docker '+(DockerLab.data.engine?.ServerVersion||'offline')+' · '+DockerLab.containers.length+' containers · '+DockerLab.images.length+' images';font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}}
  Item {width:parent.width;height:580
   Row {anchors.fill:parent;spacing:12;visible:DockerLab.page===0||DockerLab.page===1
    ListView {id:objects;width:330;height:parent.height;clip:true;spacing:7;reuseItems:true;cacheBuffer:100;model:(DockerLab.page===0?DockerLab.containers:DockerLab.images).filter(d=>!root.filter||JSON.stringify(d).toLowerCase().includes(root.filter.toLowerCase()));ScrollBar.vertical:DeskScrollBar {}
     delegate:ControlTile {required property var modelData;width:objects.width;implicitHeight:70;label:DockerLab.page===0?modelData.Names:(modelData.Repository+':'+modelData.Tag);detail:DockerLab.page===0?modelData.Status:modelData.Size+' · '+modelData.ID;glyph:DockerLab.page===0?'\uf1b3':'\uf1b2';selected:DockerLab.selectedId===(modelData.ID||'');onActivated:DockerLab.select(DockerLab.page===0?'container':'image',modelData.ID)}
    }
    Column {width:parent.width-342;spacing:9
     Text {width:parent.width;text:DockerLab.selectedId?(DockerLab.detail.inspect?.Name||DockerLab.detail.inspect?.RepoTags?.[0]||DockerLab.selectedId):'Select an environment';elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
     Flow {width:parent.width;spacing:6;visible:DockerLab.page===0&&DockerLab.selectedKind==='container'&&!!DockerLab.selectedId
      Repeater {model:['start','stop','restart','pause','unpause'];ControlTile {required property string modelData;label:modelData;implicitWidth:105;implicitHeight:30;onActivated:DockerLab.action(modelData,[DockerLab.selectedId])}}
      ControlTile {label:'Kill';implicitWidth:90;implicitHeight:30;onActivated:root.destroy('kill',[DockerLab.selectedId])}
      ControlTile {label:'Remove';implicitWidth:100;implicitHeight:30;onActivated:root.destroy('remove',[DockerLab.selectedId])}
      ControlTile {label:'tmux shell';glyph:'\uf120';implicitWidth:125;implicitHeight:30;onActivated:DockerLab.action('tmux',[DockerLab.selectedId,root.session,'/bin/sh'])}
     }
     Row {spacing:6;visible:DockerLab.page===1&&DockerLab.selectedKind==='image'&&!!DockerLab.selectedId
      ControlTile {label:'Use image';implicitWidth:130;implicitHeight:30;onActivated:{root.imageDraft=DockerLab.detail.inspect?.RepoTags?.[0]||DockerLab.selectedId;DockerLab.page=2;}}
      ControlTile {label:'Save archive';implicitWidth:140;implicitHeight:30;onActivated:DockerLab.action('save',[DockerLab.selectedId,root.archive])}
      ControlTile {label:'Remove';implicitWidth:100;implicitHeight:30;onActivated:root.destroy('image-remove',[DockerLab.selectedId])}
     }
     Flickable {width:parent.width;height:420;contentHeight:inspection.implicitHeight;clip:true;ScrollBar.vertical:DeskScrollBar {}
      Text {id:inspection;width:parent.width;text:DockerLab.selectedId?JSON.stringify(DockerLab.detail.inspect||{},null,2)+(DockerLab.detail.stats?'\n\nResource use\n'+DockerLab.detail.stats:'')+(DockerLab.detail.processes?'\n\nProcesses\n'+DockerLab.detail.processes:'')+(DockerLab.detail.changes?'\n\nFilesystem changes\n'+DockerLab.detail.changes:'')+(DockerLab.detail.logs?'\n\nRecent logs\n'+DockerLab.detail.logs:''):'Inspect state, health, ports, mounts, networks, GPU requests, restart policy, users and labels here. Running containers add resource use, processes and file changes.';textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetText;lineHeight:1.3}
     }
    }
   }
   Flickable {anchors.fill:parent;visible:DockerLab.page===2;contentHeight:launch.implicitHeight;clip:true;ScrollBar.vertical:DeskScrollBar {}
    Column {id:launch;width:parent.width;spacing:10
     Text {text:'Launch a reproducible robotics workspace';font.family:Appearance.font.data;font.pixelSize:18;font.bold:true;color:Theme.widgetText}
     Row {spacing:8;DeskTextField {width:510;placeholderText:'Image reference';text:root.imageDraft;onTextChanged:root.imageDraft=text}ControlTile {label:'Pull image';implicitWidth:150;onActivated:DockerLab.action('pull',[root.imageDraft])}DeskComboBox {width:240;model:DockerLab.images.map(i=>i.Repository+':'+i.Tag).filter(i=>!i.includes('<none>'));onActivated:root.imageDraft=model[currentIndex]}}
     Row {spacing:8;DeskTextField {width:270;placeholderText:'Container name';text:root.runName;onTextChanged:root.runName=text}DeskComboBox {width:190;model:['linux/amd64','linux/arm64','linux/arm/v7'];onActivated:{root.platform=model[currentIndex];if(root.platform!=='linux/amd64')root.gpu=false;}}DeskTextField {width:240;placeholderText:'tmux session';text:root.session;onTextChanged:root.session=text}DeskTextField {width:210;placeholderText:'ROS_DOMAIN_ID';text:root.rosDomain;onTextChanged:root.rosDomain=text}}
     Row {spacing:8;DeskTextField {width:690;placeholderText:'Host workspace mounted at /workspace';text:root.workspace;onTextChanged:root.workspace=text}ControlTile {label:'Choose folder';implicitWidth:200;onActivated:folder.open()}}
     DeskTextField {width:parent.width;placeholderText:'Container command';text:root.runCommand;onTextChanged:root.runCommand=text}
     Flow {width:parent.width;spacing:8;ControlTile {label:'NVIDIA GPU';glyph:'\uf2db';selected:root.gpu;enabled:root.platform==='linux/amd64'&&!!DockerLab.data.gpu;onActivated:root.gpu=!root.gpu}ControlTile {label:'ROS host network';selected:root.hostNet;onActivated:root.hostNet=!root.hostNet}ControlTile {label:'Shared IPC';selected:root.hostIpc;onActivated:root.hostIpc=!root.hostIpc}}
     Row {spacing:8;DeskComboBox {width:380;model:['No serial device'].concat(DockerLab.serial||[]);onActivated:root.serial=currentIndex?model[currentIndex]:''}ControlTile {label:'Launch in tmux';glyph:'\uf135';implicitWidth:210;onActivated:DockerLab.action('run',[JSON.stringify({image:root.imageDraft,name:root.runName,platform:root.platform,gpu:root.gpu,hostNetwork:root.hostNet,hostIPC:root.hostIpc,workspace:root.workspace,devices:root.serial?[root.serial]:[],session:root.session,command:root.runCommand,rosDomain:root.rosDomain})])}}
     Text {width:parent.width;text:'Native amd64 supports your RTX 2060. ARM containers use QEMU CPU emulation. Host network / IPC are explicit options for ROS discovery; only the selected serial node is passed through. The host NVIDIA driver stays outside the container.';wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted}
     Text {text:'Archives and file transfer';font.family:Appearance.font.data;font.pixelSize:16;font.bold:true;color:Theme.widgetText}
     DeskTextField {width:parent.width;placeholderText:'Image archive path';text:root.archive;onTextChanged:root.archive=text}
     Row {spacing:8;ControlTile {label:'Load image archive';implicitWidth:200;onActivated:DockerLab.action('load',[root.archive])}ControlTile {label:'Export selected container';implicitWidth:250;enabled:DockerLab.selectedKind==='container'&&!!DockerLab.selectedId;onActivated:DockerLab.action('export',[DockerLab.selectedId,root.archive])}}
     Row {spacing:8;DeskTextField {width:480;placeholderText:'Local file/directory';text:root.localPath;onTextChanged:root.localPath=text}DeskTextField {width:480;placeholderText:'Absolute container path';text:root.remotePath;onTextChanged:root.remotePath=text}}
     Row {spacing:8;ControlTile {label:'Copy from container';implicitWidth:220;enabled:DockerLab.selectedKind==='container'&&!!DockerLab.selectedId;onActivated:DockerLab.action('copy',[DockerLab.selectedId,root.remotePath,root.localPath,'out'])}ControlTile {label:'Copy into container';implicitWidth:220;enabled:DockerLab.selectedKind==='container'&&!!DockerLab.selectedId;onActivated:DockerLab.action('copy',[DockerLab.selectedId,root.remotePath,root.localPath,'in'])}}
    }
   }
   Column {anchors.fill:parent;visible:DockerLab.page===3;spacing:10
    Text {text:'Compose projects';font.family:Appearance.font.data;font.pixelSize:18;font.bold:true;color:Theme.widgetText}
    Row {spacing:8;DeskTextField {width:760;placeholderText:'Compose YAML path';text:root.project;onTextChanged:root.project=text}ControlTile {label:'Choose file';implicitWidth:180;onActivated:composePicker.open()}}
    Flow {width:parent.width;spacing:7;Repeater {model:['up','stop','start','restart','pull','build','ps','logs'];ControlTile {required property string modelData;label:modelData;implicitWidth:110;implicitHeight:32;onActivated:DockerLab.action('compose',[root.project,modelData])}}ControlTile {label:'down';implicitWidth:110;implicitHeight:32;onActivated:root.destroy('compose',[root.project,'down'])}}
    ListView {width:parent.width;height:380;clip:true;spacing:8;model:DockerLab.compose||[];delegate:ControlTile {required property var modelData;width:parent.width;implicitHeight:65;label:modelData.Name;detail:modelData.Status+' · '+modelData.ConfigFiles;onActivated:root.project=String(modelData.ConfigFiles).split(',')[0]}}
   }
   Flickable {anchors.fill:parent;visible:DockerLab.page===4;contentHeight:storage.implicitHeight;clip:true;ScrollBar.vertical:DeskScrollBar {}
    Column {id:storage;width:parent.width;spacing:10
     Text {text:'Storage accounting';font.family:Appearance.font.data;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
     Repeater {model:DockerLab.disk;Text {required property var modelData;text:modelData.Type+' · '+modelData.Size+' · reclaimable '+modelData.Reclaimable;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted}}
     Text {text:'Volumes';font.family:Appearance.font.data;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
     Repeater {model:DockerLab.volumes;Row {required property var modelData;spacing:8;ControlTile {label:modelData.Name;detail:modelData.Driver;implicitWidth:670;implicitHeight:42;onActivated:DockerLab.select('volume',modelData.Name)}ControlTile {label:'Remove';implicitWidth:125;implicitHeight:42;onActivated:root.destroy('volume-remove',[modelData.Name])}}}
     Text {text:'Networks';font.family:Appearance.font.data;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
     Repeater {model:DockerLab.networks;Row {required property var modelData;spacing:8;ControlTile {label:modelData.Name;detail:modelData.Driver+' · '+modelData.Scope;implicitWidth:670;implicitHeight:42;onActivated:DockerLab.select('network',modelData.ID)}ControlTile {label:'Remove';implicitWidth:125;implicitHeight:42;onActivated:root.destroy('network-remove',[modelData.ID])}}}
     Text {width:parent.width;text:DockerLab.selectedKind==='network'||DockerLab.selectedKind==='volume'?JSON.stringify(DockerLab.detail.inspect||{},null,2):'Select a volume or network to inspect driver, mountpoint, labels, options, attached containers, addresses and permissions.';textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:12;color:Theme.widgetMuted}
    }
   }
   Column {anchors.fill:parent;visible:DockerLab.page===5;spacing:12
    Text {text:'One session, separate robotics environments';font.family:Appearance.font.data;font.pixelSize:18;font.bold:true;color:Theme.widgetText}
    Row {spacing:8;DeskComboBox {width:360;model:DockerLab.sessions;onActivated:root.session=model[currentIndex]}DeskTextField {width:350;placeholderText:'New or existing session name';text:root.session;onTextChanged:root.session=text}ControlTile {label:'Selected container shell';implicitWidth:255;enabled:DockerLab.selectedKind==='container'&&!!DockerLab.selectedId;onActivated:DockerLab.action('tmux',[DockerLab.selectedId,root.session,'/bin/sh'])}}
    Text {width:parent.width;text:'Select a container, then open its shell in a named tmux window. Stopped containers start only when you request a shell. New image launches get their own window; detaching tmux keeps your robotics session running. Choose existing sessions or name a new one.';wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:14;color:Theme.widgetMuted}
    Text {text:'Ctrl+b, d · detach   /   Ctrl+b, w · choose window   /   Ctrl+b, c · new window';font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetAccent}
   }
   Column {anchors.fill:parent;visible:DockerLab.page===6;spacing:12
    Text {text:'NVIDIA + ARM toolchain';font.family:Appearance.font.data;font.pixelSize:18;font.bold:true;color:Theme.widgetText}
    Text {width:parent.width;text:'NVIDIA runtime: '+(DockerLab.data.gpu?'ready':'not configured')+'\nQEMU interpreters: '+(DockerLab.arm||[]).join(', ')+'\nKVM access: '+(DockerLab.data.kvm?'available':'unavailable')+'\nEngine architecture: '+(DockerLab.data.engine?.Architecture||'—');wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted;lineHeight:1.5}
    Row {spacing:8;ControlTile {label:'Check NVIDIA container';implicitWidth:275;onActivated:DockerLab.action('gpu-check',['nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04'])}ControlTile {label:'Check ARM64 execution';implicitWidth:275;onActivated:DockerLab.action('arm-check',[])}}
    DeskTextField {width:parent.width;placeholderText:'Build directory';text:root.workspace;onTextChanged:root.workspace=text}
    Row {spacing:8;DeskTextField {width:510;placeholderText:'Output image tag';text:root.imageDraft;onTextChanged:root.imageDraft=text}DeskComboBox {width:190;model:['linux/amd64','linux/arm64','linux/arm/v7'];onActivated:root.platform=model[currentIndex]}ControlTile {label:'Build + load locally';implicitWidth:240;onActivated:DockerLab.action('build',[root.workspace,root.imageDraft,root.platform])}}
    Text {width:parent.width;text:'Cross-platform builds may be slower under emulation. CUDA execution is native amd64; ARM images target your robot hardware and do not borrow x86 host CUDA libraries. Use multi-platform build/push arguments in Advanced when publishing an image.';wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:13;color:Theme.widgetMuted}
   }
   Column {anchors.fill:parent;visible:DockerLab.page===7;spacing:9
    Text {text:'Tasks and advanced Docker controls';font.family:Appearance.font.data;font.pixelSize:17;font.bold:true;color:Theme.widgetText}
    Row {spacing:8;DeskTextField {width:820;placeholderText:'Explicit Docker arguments · e.g. network create robotics';text:root.commandDraft;onTextChanged:root.commandDraft=text}ControlTile {label:'Run';implicitWidth:120;enabled:root.commandDraft.trim()!=='';onActivated:DockerLab.action('cli',[root.commandDraft])}}
    Text {text:'Experiment cockpit · each run saves command, Git revision, duration and output';font.family:Appearance.font.data;font.pixelSize:13;font.bold:true;color:Theme.widgetAccent}
    Row {spacing:8;DeskTextField {width:240;placeholderText:'Run name';text:root.experimentName;onTextChanged:root.experimentName=text}DeskTextField {width:580;placeholderText:'Command · e.g. colcon build';text:root.experimentCommand;onTextChanged:root.experimentCommand=text}ControlTile {label:'Record run';implicitWidth:120;enabled:root.experimentCommand.trim()!=='';onActivated:Quickshell.execDetached(['sensei-terminal','--hold','--title','Sensei · experiment','-e','/home/fh1m/.local/bin/sensei-lab','run','--project',root.workspace,'--name',root.experimentName,'--command-line',root.experimentCommand])}}
    Row {spacing:8;Text {width:780;anchors.verticalCenter:parent.verticalCenter;text:'Project: '+root.workspace+' · Set it in Launch. Records: ~/.local/state/sensei-lab';elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}ControlTile {label:'Open project';glyph:'\uf120';implicitWidth:156;implicitHeight:28;onActivated:Quickshell.execDetached(['sensei-terminal','--title','Sensei · '+root.experimentName,'-e','/home/fh1m/.local/bin/sensei-lab','open','--project',root.workspace,'--name',root.experimentName])}}
    ListView {width:parent.width;height:380;clip:true;spacing:9;reuseItems:true;model:DockerLab.tasks;ScrollBar.vertical:DeskScrollBar {}
     delegate:ChamferPanel {required property var modelData;width:parent.width;height:170;chamfer:6;scanlines:false;fillColor:Theme.widgetSurface;borderColor:Theme.widgetBorder
      Text {x:12;y:10;width:parent.width-150;text:modelData.label+' · '+modelData.state+(modelData.exitCode!==undefined?' · exit '+modelData.exitCode:'');elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:13;font.bold:true;color:modelData.state==='failed'?Theme.widgetAccent:Theme.widgetText}
      ControlTile {anchors.right:parent.right;anchors.rightMargin:10;y:5;implicitWidth:110;implicitHeight:30;label:'Cancel';visible:modelData.state==='running';onActivated:DockerLab.action('cancel',[modelData.id])}
      Flickable {x:12;y:43;width:parent.width-24;height:115;contentHeight:taskText.implicitHeight;clip:true;Text {id:taskText;width:parent.width;text:modelData.output||modelData.error||'Waiting for output…';textFormat:Text.PlainText;wrapMode:Text.Wrap;font.family:Appearance.font.data;font.pixelSize:11;color:Theme.widgetMuted}}
     }
    }
   }
  }
  Text {width:parent.width;text:DockerLab.message||(DockerLab.busy?'Sensei, loading Docker inventory…':'Sensei, Docker events update this panel while open. No background inventory polling.');textFormat:Text.PlainText;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight;font.family:Appearance.font.data;font.pixelSize:12;color:DockerLab.success?Theme.widgetMuted:Theme.widgetAccent}
 }
 IpcHandler {target:'dockerpanel';function layout():string{return JSON.stringify({height:root.height,page:DockerLab.page});}}
}
