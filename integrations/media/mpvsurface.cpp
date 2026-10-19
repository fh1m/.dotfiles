// SPDX-License-Identifier: GPL-3.0-or-later
#include "mpvsurface.h"
#include <MpvQt/MpvController>
#include <QUrl>
#include <QTimer>
#include <QQuickWindow>
#include <algorithm>

MpvSurface::MpvSurface(QQuickItem *parent):MpvAbstractItem(parent) {
 setMirrorVertically(false);
 connect(this,&MpvAbstractItem::ready,this,[this](){
  QTimer::singleShot(80,this,[this](){m_rendererReady=true;if(!m_pendingVideo.isEmpty()){const auto video=m_pendingVideo,audio=m_pendingAudio;m_pendingVideo.clear();m_pendingAudio.clear();load(video,audio,true,m_pendingStart,m_pendingPaused);}else if(m_visual&&!m_source.isEmpty())command({"set","vid","1"});});
 });
 connect(this,&QQuickItem::windowChanged,this,[this](QQuickWindow *window){m_rendererReady=false;if(window)connect(window,&QQuickWindow::sceneGraphInvalidated,this,[this](){m_rendererReady=false;});});
 // mpvqt provides the render lifecycle; direct CPU copies avoid hybrid-GPU
 // decoder texture import. mpv still uses OpenGL for presentation.
 setProperty("hwdec","auto-copy");setProperty("video-sync","audio");
 setProperty("cache",true);setProperty("cache-pause-initial",false);setProperty("cache-pause-wait",0.5);setProperty("demuxer-max-bytes",64*1024*1024);
 setProperty("demuxer-max-back-bytes",8*1024*1024);setProperty("volume",m_volume);
 setProperty("keep-open",false);setProperty("ytdl",false);
 connect(mpvController(),&MpvController::propertyChanged,this,[this](const QString &name,const QVariant &v){
  if(name=="time-pos"){m_position=qRound64(v.toDouble()*1000);emit positionChanged();}
  else if(name=="duration"){m_duration=qRound64(v.toDouble()*1000);emit durationChanged();}
  else if(name=="pause"){m_paused=v.toBool();emit playingChanged();}
  else if(name=="idle-active"){m_idle=v.toBool();emit playingChanged();}
  else if(name=="paused-for-cache"){m_loading=v.toBool();emit loadingChanged();}
  else if(name=="seekable"){m_seekable=v.toBool();emit seekableChanged();}
  else if(name=="volume"){m_volume=v.toDouble();emit volumeChanged();}
  else if(name=="speed"){m_rate=v.toDouble();emit playbackRateChanged();}
  else if(name=="width"){m_videoSize.setWidth(v.toInt());emit videoSizeChanged();}
  else if(name=="height"){m_videoSize.setHeight(v.toInt());emit videoSizeChanged();}
  else if(name=="avsync"){m_avsync=v.toDouble();emit avsyncChanged();}
 });
 for(const auto &name:{"time-pos","duration","volume","speed","avsync"})observeProperty(name,MPV_FORMAT_DOUBLE);
 for(const auto &name:{"pause","idle-active","paused-for-cache","seekable"})observeProperty(name,MPV_FORMAT_FLAG);
 for(const auto &name:{"width","height"})observeProperty(name,MPV_FORMAT_INT64);
 connect(mpvController(),&MpvController::fileLoaded,this,[this](){m_loading=false;emit loadingChanged();emit loaded();});
 connect(mpvController(),&MpvController::endFile,this,[this](const QString &reason){m_loading=false;emit loadingChanged();if(reason=="eof")emit ended();else if(reason=="error")emit failed();});
}
void MpvSurface::setPosition(qint64 value){command({"seek",QString::number(std::max(qint64(0),value)/1000.0,'f',3),"absolute+exact"});}
void MpvSurface::setVolume(double value){setProperty("volume",std::clamp(value,0.0,100.0));}
void MpvSurface::setPlaybackRate(double value){setProperty("speed",std::clamp(value,0.5,2.0));}
void MpvSurface::setSource(const QString &value){if(value.isEmpty()){stop();return;}load(value,{},false);}
void MpvSurface::load(const QString &video,const QString &audio,bool visual,qint64 start,bool paused){
 const QUrl v(video),a(audio);
 if(v.scheme()!="https"||(!audio.isEmpty()&&a.scheme()!="https")){emit failed();return;}
 if(visual&&!m_rendererReady){m_pendingVideo=video;m_pendingAudio=audio;m_pendingStart=start;m_pendingPaused=paused;m_visual=true;m_loading=true;emit loadingChanged();return;}
 m_pendingVideo.clear();m_pendingAudio.clear();m_visual=visual;
 m_source=video;m_loading=true;m_position=0;m_frameNumber=0;emit sourceChanged();emit loadingChanged();emit positionChanged();emit frameNumberChanged();
 setProperty("start",QString::number(std::max(qint64(0),start)/1000.0,'f',3));
 setProperty("vid",visual?"auto":"no");setProperty("audio-files",audio.isEmpty()?QStringList{}:QStringList{audio});
 setProperty("pause",paused);command({"loadfile",video,"replace"});
}
void MpvSurface::play(){setProperty("pause",false);}void MpvSurface::pause(){setProperty("pause",true);}
void MpvSurface::stop(){m_pendingVideo.clear();m_pendingAudio.clear();m_visual=false;command({"stop"});m_source.clear();m_loading=false;emit sourceChanged();emit loadingChanged();}
void MpvSurface::setVideoEnabled(bool enabled){command({"set","vid",enabled?"1":"no"});}

QSGNode *MpvSurface::updatePaintNode(QSGNode *node,UpdatePaintNodeData *data){
 auto *result=QQuickFramebufferObject::updatePaintNode(node,data);
 QMetaObject::invokeMethod(this,[this](){++m_frameNumber;emit frameNumberChanged();},Qt::QueuedConnection);
 return result;
}
