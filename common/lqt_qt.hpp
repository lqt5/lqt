#ifndef __LQT_QT_HPP
#define __LQT_QT_HPP

#include "lqt_common.hpp"

int lqtL_qt_metacall (lua_State *, QObject *, QObject *, QMetaObject::Call, const char *, int, void **);
void lqtL_qobject_custom (lua_State *L);

#ifndef MODULE_qtgui
void lqtL_qvariant_custom (lua_State *L);
#else
void lqtL_qvariant_custom_qtgui (lua_State *L);
#endif

// custom type handlers

QList<QByteArray> lqtL_getStringList(lua_State *L, int i);
void lqtL_pushStringList(lua_State *L, const QList<QByteArray> &table);

QGenericArgument lqtL_getGenericArgument(lua_State *L, int i);
bool lqtL_isGenericArgument(lua_State *L, int i);

#endif // __LQT_QT_HPP


