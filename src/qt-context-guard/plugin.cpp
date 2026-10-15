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
        auto *guard = new ContextGuard(qApp);
        qApp->installEventFilter(guard);
        qInfo("Sensei: null-focus context-menu guard loaded");
        return guard;
    }
};
#include "plugin.moc"
