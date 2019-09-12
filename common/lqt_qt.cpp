#include "lqt_qt.hpp"

// #include <QThread>

#include <QMetaObject>
#include <QMetaMethod>

// #define VERBOSE_BUILD

#define CASE(x) case QMetaMethod::x : lua_pushstring(L, " " #x); break
static int lqtL_methods(lua_State *L) {
	QObject* self = static_cast<QObject*>(lqtL_toudata(L, 1, "QObject*"));
	if (self == NULL)
		return luaL_argerror(L, 1, "expecting QObject*");
	const QMetaObject *mo = self->metaObject();
	lua_createtable(L, mo->methodCount(), 0);
	for (int i=0; i < mo->methodCount(); i++) {
		QMetaMethod m = mo->method(i);
		lua_pushstring(L, m.methodSignature());
		switch (m.access()) {
		CASE(Private);
		CASE(Protected);
		CASE(Public);
		}
		switch (m.methodType()) {
		CASE(Method);
		CASE(Signal);
		CASE(Slot);
		CASE(Constructor);
		}
		lua_concat(L, 3);
		lua_rawseti(L, -2, m.methodIndex());
	}
	return 1;
}
#undef CASE

int lqtL_pushqobject(lua_State *L, QObject * object) {
    if (object == nullptr) {
        lua_pushnil(L);
        return 0;
    }
    const QMetaObject * meta = object->metaObject();
    while (meta) {
        QString className = meta->className();
        className += "*";
        char * cname = strdup(qPrintable(className));
        lua_getfield(L, LUA_REGISTRYINDEX, cname);
        int isnil = lua_isnil(L, -1);
        lua_pop(L, 1);
        if (!isnil) {
            lqtL_pushudata(L, object, cname);
            free(cname);
            return 1;
        } else {
            free(cname);
            meta = meta->superClass();
        }
    }
    QString className = meta->className();
    luaL_error(L, "QObject `%s` not registered!", className.toStdString().c_str());
    return 0;
}

static int lqtL_findchild(lua_State *L) {
    QObject* self = static_cast<QObject*>(lqtL_toudata(L, 1, "QObject*"));
    if (self == NULL)
        return luaL_argerror(L, 1, "expecting QObject*");

    QString name = luaL_checkstring(L, 2);
    QObject * child = self->findChild<QObject*>(name);

    if (child) {
        lqtL_pushqobject(L, child);
        return 1;
    } else {
        return 0;
    }
}

static int lqtL_children(lua_State *L) {
    QObject* self = static_cast<QObject*>(lqtL_toudata(L, 1, "QObject*"));
    if (self == NULL)
        return luaL_argerror(L, 1, "expecting QObject*");
    const QObjectList & children = self->children();

    lua_newtable(L);
    for (int i=0; i < children.count(); i++) {
        QObject * object = children[i];
        QString name = object->objectName();
        if (!name.isEmpty() && lqtL_pushqobject(L, object)) {
            lua_setfield(L, -2, qPrintable(name));
        }
    }
    return 1;
}

static int lqtL_connect(lua_State *L) {
    static int methodId = 0;

    QObject* sender = static_cast<QObject*>(lqtL_toudata(L, 1, "QObject*"));
    if (sender == NULL)
        return luaL_argerror(L, 1, "sender not QObject*");

    const char *signal = luaL_checkstring(L, 2);
    const QMetaObject *senderMeta = sender->metaObject();
    int idxS = senderMeta->indexOfSignal(signal + 1);
    if (idxS == -1)
        return luaL_argerror(L, 2, qPrintable(QString("no such sender signal: '%1'").arg(signal + 1)));

    QObject* receiver;
    QString methodName;

    if (lua_type(L, 3) == LUA_TFUNCTION) {
        receiver = sender;

        // simulate sender:__addmethod('LQT_SLOT_X(signature)', function()...end)
        QMetaMethod m = senderMeta->method(idxS);
        methodName = QString(m.methodSignature()).replace(QRegExp("^[^\\(]+"), QString("LQT_SLOT_%1").arg(methodId++));

        lua_getfield(L, 1, "__addslot");
        lua_pushvalue(L, 1);
        lua_pushstring(L, qPrintable(methodName));
        lua_pushvalue(L, 3);

        if(lqtL_pcall(L, 3, 0, 0) != 0)
            lua_error(L);

        methodName.prepend("1");

#ifdef VERBOSE_BUILD
        printf("Connect method (%p) %d(`%s`) to lua-method `%s`\n"
            , receiver
            , idxS
            , signal
            , methodName.toStdString().c_str()
        );
#endif
    } else {
        receiver = static_cast<QObject*>(lqtL_toudata(L, 3, "QObject*"));
        if (receiver == NULL)
            return luaL_argerror(L, 3, "receiver not QObject*");
        const char *method = luaL_checkstring(L, 4);
        methodName = method;

        const QMetaObject *receiverMeta = receiver->metaObject();
        int idxR = receiverMeta->indexOfMethod(method + 1);
        if (idxR == -1)
            return luaL_argerror(L, 4, qPrintable(QString("no such receiver method: '%1'").arg(method + 1)));

#ifdef VERBOSE_BUILD
        printf("Connect method (%p) %d(`%s`) to method (%p) %d(`%s`)\n"
            , sender
            , idxS
            , signal
            , receiver
            , idxR
            , method
        );
#endif
    }

    bool ok = QObject::connect(sender, signal, receiver, qPrintable(methodName));
    lua_pushboolean(L, ok);
    return 1;
}

static int lqtL_metaObject(lua_State *L) {

    QObject* self = static_cast<QObject*>(lqtL_toudata(L, 1, "QObject*"));
    if (self == NULL)
        return luaL_argerror(L, 1, "expecting QObject*");

	lqtL_pushudata(L, self->metaObject(), "QMetaObject*");
	return 1;
}

void lqtL_qobject_custom (lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "QObject*");
    int qobject = lua_gettop(L);

    lqtL_embed(L);

    lua_pushstring(L, "__methods");
    lua_pushcfunction(L, lqtL_methods);
    lua_rawset(L, qobject);

    lua_pushstring(L, "findChild");
    lua_pushcfunction(L, lqtL_findchild);
    lua_rawset(L, qobject);

    lua_pushstring(L, "children");
    lua_pushcfunction(L, lqtL_children);
    lua_rawset(L, qobject);

    lua_pushstring(L, "connect");
    lua_pushcfunction(L, lqtL_connect);
    lua_rawset(L, qobject);

    lua_pushstring(L, "metaObject");
    lua_pushcfunction(L, lqtL_metaObject);
    lua_rawset(L, qobject);

    // also modify the static QObject::connect function
    lua_getfield(L, -2, "QObject");
    lua_pushcfunction(L, lqtL_connect);
    lua_setfield(L, -2, "connect");
}


QList<QByteArray> lqtL_getStringList(lua_State *L, int i) {
    QList<QByteArray> ret;
    int n = lua_objlen(L, i);
    for (int i=0; i<n; i++) {
        lua_pushnumber(L, i+1);
        lua_gettable(L, i);
        ret[i] = QByteArray(lua_tostring(L, -1));
        lua_pop(L, 1);
    }
    return ret;
}

void lqtL_pushStringList(lua_State *L, const QList<QByteArray> &table) {
    const int n = table.size();
    lua_createtable(L, n, 0);
    for (int i=0; i<n; i++) {
        lua_pushnumber(L, i+1);
        lua_pushstring(L, table[i].data());
        lua_settable(L, -3);
    }
}
