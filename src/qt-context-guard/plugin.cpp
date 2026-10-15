#include <QGenericPlugin>
#include <QGuiApplication>
#include <QDebug>
#include "guard.hpp"

class GuardPlugin final : public QGenericPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QGenericPluginFactoryInterface_iid FILE "metadata.json")
public:
    QObject *create(const QString &key, const QString &) override {
        if (key.compare("sensei-context-guard", Qt::CaseInsensitive)) return nullptr;
        // Qt owns the returned generic instance; do not also parent it to qApp.
        auto *guard = new ContextGuard();
        qApp->installEventFilter(guard);
        // Do not load this shell workaround into applications launched by it.
        auto plugins = qEnvironmentVariable("QT_QPA_GENERIC_PLUGINS").split(',', Qt::SkipEmptyParts);
        plugins.removeAll("sensei-context-guard");
        if (plugins.isEmpty()) qunsetenv("QT_QPA_GENERIC_PLUGINS");
        else qputenv("QT_QPA_GENERIC_PLUGINS", plugins.join(',').toUtf8());
        qInfo("Sensei: null-focus context-menu guard loaded");
        return guard;
    }
};
#include "plugin.moc"
