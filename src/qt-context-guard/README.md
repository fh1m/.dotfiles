# Null-focus context-menu guard

Workaround for [QTBUG-146671](https://bugreports.qt.io/browse/QTBUG-146671), also
tracked in [Quickshell #900](https://github.com/quickshell-mirror/quickshell/issues/900).
Homie's saved core enters `QQuickItem::mapToScene` through `contextMenuTargets`.

A scene-origin context-menu event on a QQuickWindow without an active focus item
can dereference null. `ContextGuard` consumes only that unusable synthesized
event. It never consumes the original mouse press/release, non-origin menus,
ordinary QObject events, or menus with a valid focus item.

```sh
bash scripts/build-qt-context-guard.sh
```

The public Qt generic-plugin API loads it only into `sensei-shell` processes.
No Qt/system library is replaced. The wrapper requires a matching Qt version
stamp; rebuild after a Qt update. Removing the local `sensei-qt-plugins` directory
and restarting the shell disables it. The package binary remains available.

CTest sends the actual origin event through Qt's event system after checking
its filtering boundary. `context_guard_test --unguarded` is an intentional
**offscreen crash reproducer**, never a desktop interaction test. Do not run it
in a loop. Normal CTest never uses that mode. The plugin is a temporary local
workaround; remove it after validating a fixed upstream Qt release.

[Qt plugin API](https://doc.qt.io/qt-6/qgenericplugin.html) ·
[QObject event filters](https://doc.qt.io/qt-6/qobject.html#installEventFilter)
