#include "lqt_qt.hpp"
#include "lqt_addmethod.h"

#ifdef MODULE_qtwebenginewidgets

QWebEngineCallback<int> lqtL_getQWebEngineCallback_int(lua_State *L, int idx) {

    lua_pushvalue(L, idx);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return QWebEngineCallback<int>([L,ref](int ret) {

        lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if(!lua_isfunction(L, -1))
            return;

        lua_pushnumber(L, ret);
        if(lqtL_pcall(L, 1, 0, 0))
            lua_error(L);
    });
}

QWebEngineCallback<const QByteArray &> lqtL_getQWebEngineCallback_QByteArray(lua_State *L, int idx) {

    lua_pushvalue(L, idx);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return QWebEngineCallback<const QByteArray &>([L,ref](const QByteArray & ret) {

        lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if(!lua_isfunction(L, -1))
            return;

        lqtL_pushudata(L, &ret, "QByteArray*");
        if(lqtL_pcall(L, 1, 0, 0))
            lua_error(L);
    });
}

QWebEngineCallback<bool> lqtL_getQWebEngineCallback_bool(lua_State *L, int idx) {

    lua_pushvalue(L, idx);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return QWebEngineCallback<bool>([L,ref](bool ret) {

        lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if(!lua_isfunction(L, -1))
            return;

        lua_pushboolean(L, ret ? 1 : 0);
        if(lqtL_pcall(L, 1, 0, 0))
            lua_error(L);
    });
}

QWebEngineCallback<const QString &> lqtL_getQWebEngineCallback_QString(lua_State *L, int idx) {

    lua_pushvalue(L, idx);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return QWebEngineCallback<const QString &>([L,ref](const QString &ret) {

        lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if(!lua_isfunction(L, -1))
            return;

        lqtL_pushudata(L, &ret, "QString*");
        if(lqtL_pcall(L, 1, 0, 0))
            lua_error(L);
    });
}

QWebEngineCallback<const QVariant &> lqtL_getQWebEngineCallback_QVariant(lua_State *L, int idx) {

    lua_pushvalue(L, idx);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return QWebEngineCallback<const QVariant &>([L,ref](const QVariant &ret) {

        lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
        if(!lua_isfunction(L, -1))
            return;

        lqtL_pushudata(L, &ret, "QVariant*");
        if(lqtL_pcall(L, 1, 0, 0))
            lua_error(L);
    });
}

#endif
