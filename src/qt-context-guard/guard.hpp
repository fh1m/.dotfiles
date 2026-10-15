#pragma once
#include <QContextMenuEvent>
#include <QObject>
#include <QQuickWindow>

// QTBUG-146671: Qt treats scene origin as a missing context-menu position,
// then dereferences a null activeFocusItem on non-focusing layer surfaces.
// Preserve the original mouse event and every valid context-menu event.
class ContextGuard final : public QObject {
public:
    using QObject::QObject;
    bool eventFilter(QObject *target, QEvent *event) override {
        if (event->type() != QEvent::ContextMenu) return false;
        auto *window = qobject_cast<QQuickWindow *>(target);
        auto *menu = static_cast<QContextMenuEvent *>(event);
        if (window && menu->pos().isNull() && !window->activeFocusItem()) {
            event->accept();
            return true;
        }
        return false;
    }
};
