#include <QGuiApplication>
#include <QQuickItem>
#include <cassert>
#include "guard.hpp"
int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    ContextGuard guard;
    QQuickWindow window;
    assert(!window.activeFocusItem());
    QContextMenuEvent origin(QContextMenuEvent::Mouse, QPoint(0,0), QPoint(0,0));
    assert(guard.eventFilter(&window, &origin));
    QContextMenuEvent valid(QContextMenuEvent::Mouse, QPoint(20,20), QPoint(20,20));
    assert(!guard.eventFilter(&window, &valid));
    QObject ordinary;
    assert(!guard.eventFilter(&ordinary, &origin));
    QEvent mouse(QEvent::MouseButtonPress);
    assert(!guard.eventFilter(&window, &mouse));
    if (argc > 1 && (QString::fromLocal8Bit(argv[1]) == "--unguarded" || QString::fromLocal8Bit(argv[1]) == "--plugin-only")) {
        QCoreApplication::sendEvent(&window, &origin);
        return 0;
    }
    app.installEventFilter(&guard);
    // Exercises actual Qt delivery. The unguarded version crashes on affected Qt.
    QCoreApplication::sendEvent(&window, &origin);
    QQuickItem item(window.contentItem());
    item.forceActiveFocus();
    if (window.activeFocusItem()) assert(!guard.eventFilter(&window, &origin));
    return 0;
}
