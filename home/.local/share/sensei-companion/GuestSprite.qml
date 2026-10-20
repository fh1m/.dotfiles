import QtQuick
// One cached atlas, two clipped samples for a brief pose crossfade. No IO per frame.
Item {
    id:root
    property url source
    property int frame:0
    property bool reducedMotion:false
    property int shown:0
    property int previous:0
    property real blend:1
    readonly property real cellW:atlas.implicitWidth/2
    readonly property real cellH:atlas.implicitHeight/2
    readonly property real factor:Math.min(width/Math.max(1,cellW),height/Math.max(1,cellH))
    function change():void {
        previous=shown;shown=Math.max(0,Math.min(3,frame));
        if(reducedMotion){fade.stop();blend=1;}else {blend=0;fade.restart();}
    }
    onFrameChanged:change()
    onSourceChanged:{fade.stop();shown=Math.max(0,Math.min(3,frame));previous=shown;blend=1;}
    onReducedMotionChanged:if(reducedMotion){fade.stop();blend=1;}
    NumberAnimation {id:fade;target:root;property:'blend';to:1;duration:160;easing.type:Easing.InOutQuad}
    Item {anchors.centerIn:parent;width:root.cellW*root.factor;height:root.cellH*root.factor;clip:true
        Image {source:root.source;asynchronous:true;cache:true;retainWhileLoading:true;smooth:true;opacity:1-root.blend
            width:implicitWidth*root.factor;height:implicitHeight*root.factor
            x:-(root.previous%2)*root.cellW*root.factor;y:-Math.floor(root.previous/2)*root.cellH*root.factor
        }
        Image {id:atlas;source:root.source;asynchronous:true;cache:true;retainWhileLoading:true;smooth:true;opacity:root.blend
            width:implicitWidth*root.factor;height:implicitHeight*root.factor
            x:-(root.shown%2)*root.cellW*root.factor;y:-Math.floor(root.shown/2)*root.cellH*root.factor
        }
    }
}
