// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <MpvQt/MpvAbstractItem>
#include <QtQml/qqmlregistration.h>
#include <QSize>

// libmpv owns a single synchronized A/V clock. This adapter adds no network API,
// arbitrary command endpoint, credentials, or persistent playback log.
class MpvSurface : public MpvAbstractItem {
 Q_OBJECT
 QML_ELEMENT
 Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
 Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
 Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
 Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
 Q_PROPERTY(bool seekable READ seekable NOTIFY seekableChanged)
 Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
 Q_PROPERTY(double playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY playbackRateChanged)
 Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
 Q_PROPERTY(QSize videoSize READ videoSize NOTIFY videoSizeChanged)
 Q_PROPERTY(qint64 frameNumber READ frameNumber NOTIFY frameNumberChanged)
 Q_PROPERTY(double avsync READ avsync NOTIFY avsyncChanged)
 Q_PROPERTY(int mediaStatus READ mediaStatus NOTIFY loadingChanged)
 public:
 explicit MpvSurface(QQuickItem *parent=nullptr);
 qint64 position()const{return m_position;} qint64 duration()const{return m_duration;}
 bool playing()const{return !m_paused&&!m_idle;} bool loading()const{return m_loading;}
 bool seekable()const{return m_seekable;} double volume()const{return m_volume;}
 double playbackRate()const{return m_rate;} QString source()const{return m_source;}
 QSize videoSize()const{return m_videoSize;} qint64 frameNumber()const{return m_frameNumber;}
 double avsync()const{return m_avsync;} int mediaStatus()const{return m_loading?1:m_idle?0:2;}
 void setPosition(qint64);void setVolume(double);void setPlaybackRate(double);void setSource(const QString&);
 Q_INVOKABLE void load(const QString &video,const QString &audio,bool visual,qint64 start=0,bool paused=false);
 Q_INVOKABLE void play();Q_INVOKABLE void pause();Q_INVOKABLE void stop();
 Q_INVOKABLE void setVideoEnabled(bool enabled);
 signals:
 void positionChanged();void durationChanged();void playingChanged();void loadingChanged();void seekableChanged();
 void volumeChanged();void playbackRateChanged();void sourceChanged();void videoSizeChanged();void frameNumberChanged();void avsyncChanged();
 void loaded();void ended();void failed();
 protected:
 QSGNode *updatePaintNode(QSGNode *,UpdatePaintNodeData *) override;
 private:
 bool m_rendererReady=false,m_visual=false;QString m_pendingVideo,m_pendingAudio;qint64 m_pendingStart=0;bool m_pendingPaused=false;
 qint64 m_position=0,m_duration=0,m_frameNumber=0;bool m_paused=true,m_idle=true,m_loading=false,m_seekable=false;
 double m_volume=65,m_rate=1,m_avsync=0;QString m_source;QSize m_videoSize;
};
