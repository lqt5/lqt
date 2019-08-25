#include "lqt_qt.hpp"

// #define VERBOSE_BUILD

#if defined(MODULE_qtgui) || defined(MODULE_qtwidgets)
#include <QKeySequence>
#include <QBitmap>
#include <QBrush>
#include <QColor>
#include <QCursor>
#include <QFont>
#include <QIcon>
#include <QImage>
#include <QMatrix>
#include <QMatrix4x4>
#include <QPalette>
#include <QPen>
#include <QPoint>
#include <QPointF>
#include <QPixmap>
#include <QPolygon>
#include <QQuaternion>
#include <QRegion>
#include <QTextLength>
#include <QTextFormat>
#include <QVector2D>
#include <QVector3D>
#include <QVector4D>
#include <QQuaternion>
#include <QPolygonF>
#endif

#ifdef MODULE_qtwidgets
#include <QSizePolicy>
#endif

static void lqt_pushTypePtr(lua_State *L, int idx, QMetaType::Type type, const char *user_type, void *ptr) {

    switch(type) {
        case QMetaType::Bool: lua_pushboolean(L, *reinterpret_cast<bool *>(ptr) ? 1 : 0); break;
        case QMetaType::Int: lua_pushnumber(L, *reinterpret_cast<int *>(ptr)); break;
        case QMetaType::UInt: lua_pushnumber(L, *reinterpret_cast<unsigned int *>(ptr)); break;
        case QMetaType::LongLong: lua_pushnumber(L, *reinterpret_cast<long long *>(ptr)); break;
        case QMetaType::ULongLong: lua_pushnumber(L, *reinterpret_cast<unsigned long long *>(ptr)); break;
        case QMetaType::Double: lua_pushnumber(L, *reinterpret_cast<double *>(ptr)); break;
        case QMetaType::Long: lua_pushnumber(L, *reinterpret_cast<long *>(ptr)); break;
        case QMetaType::Short: lua_pushnumber(L, *reinterpret_cast<short *>(ptr)); break;
        case QMetaType::Char: lua_pushnumber(L, *reinterpret_cast<char *>(ptr)); break;
        case QMetaType::ULong: lua_pushnumber(L, *reinterpret_cast<unsigned long *>(ptr)); break;
        case QMetaType::UShort: lua_pushnumber(L, *reinterpret_cast<unsigned short *>(ptr)); break;
        case QMetaType::UChar: lua_pushnumber(L, *reinterpret_cast<unsigned char *>(ptr)); break;
        case QMetaType::Float: lua_pushnumber(L, *reinterpret_cast<float *>(ptr)); break;
        case QMetaType::SChar: lua_pushnumber(L, *reinterpret_cast<signed char *>(ptr)); break;

        case QMetaType::QObjectStar: lqtL_pushqobject(L, *(QObject **) ptr); break;

        #define CASE_TYPE(Type)\
            case QMetaType::Type: {\
                Type& ret = *(new Type(*reinterpret_cast<Type *>(ptr)));\
                lqtL_pushudata(L, &ret, #Type"*"); break;\
            }

        CASE_TYPE(QChar)
        CASE_TYPE(QString)
        CASE_TYPE(QStringList)
        CASE_TYPE(QByteArray)
        CASE_TYPE(QBitArray)
        CASE_TYPE(QDate)
        CASE_TYPE(QTime)
        CASE_TYPE(QDateTime)
        CASE_TYPE(QUrl)
        CASE_TYPE(QLocale)
        CASE_TYPE(QRect)
        CASE_TYPE(QRectF)
        CASE_TYPE(QSize)
        CASE_TYPE(QSizeF)
        CASE_TYPE(QLine)
        CASE_TYPE(QLineF)
        CASE_TYPE(QPoint)
        CASE_TYPE(QPointF)
        CASE_TYPE(QRegExp)
        CASE_TYPE(QEasingCurve)
        CASE_TYPE(QUuid)
        CASE_TYPE(QVariant)
        CASE_TYPE(QModelIndex)
        CASE_TYPE(QPersistentModelIndex)
        CASE_TYPE(QRegularExpression)
        CASE_TYPE(QJsonValue)
        CASE_TYPE(QJsonObject)
        CASE_TYPE(QJsonArray)
        CASE_TYPE(QJsonDocument)
        CASE_TYPE(QByteArrayList)
        CASE_TYPE(QVariantMap)
        CASE_TYPE(QVariantList)
        CASE_TYPE(QVariantHash)
        CASE_TYPE(QCborSimpleType)
        CASE_TYPE(QCborValue)
        CASE_TYPE(QCborArray)
        CASE_TYPE(QCborMap)

        #ifdef MODULE_qtgui
        // Gui types
        CASE_TYPE(QFont)
        CASE_TYPE(QPixmap)
        CASE_TYPE(QBrush)
        CASE_TYPE(QColor)
        CASE_TYPE(QPalette)
        CASE_TYPE(QIcon)
        CASE_TYPE(QImage)
        CASE_TYPE(QPolygon)
        CASE_TYPE(QRegion)
        CASE_TYPE(QBitmap)
        CASE_TYPE(QCursor)
        CASE_TYPE(QKeySequence)
        CASE_TYPE(QPen)
        CASE_TYPE(QTextLength)
        CASE_TYPE(QTextFormat)
        CASE_TYPE(QMatrix)
        CASE_TYPE(QTransform)
        CASE_TYPE(QMatrix4x4)
        CASE_TYPE(QVector2D)
        CASE_TYPE(QVector3D)
        CASE_TYPE(QVector4D)
        CASE_TYPE(QQuaternion)
        CASE_TYPE(QPolygonF)
        #endif // MODULE_qtgui

        // Widget types
        #ifdef MODULE_qtwidgets
        CASE_TYPE(QSizePolicy)
        #endif // MODULE_qtwidgets

        #undef CASE_TYPE

        case QMetaType::User:
        case QMetaType::UnknownType: {
            if(user_type != nullptr)
                lqtL_pushudata(L, *(void **)(ptr), user_type);
            else {
                printf("Unknown user type, push nil instead: %d %d\n", idx, type);
                lua_pushnil(L);
            }
        } break;
        default:
        break;
        // {
        //     static QVariant variants[16];
        //     QVariant &v = variants[idx];
        //     v = QVariant(type, ptr);
        //     lqtL_pushudata(L, &v, "QVariant*");
        //     int ret = lqtL_qvariant_value_custom(L, -1, false);
        //     if (ret == 0)
        //         lua_pushnil(L);
        //     else if(ret == 2) {
        //         lua_remove(L, -2);
        //         lua_error(L);
        //     }
        //     lua_remove(L, -2);
        // }
    }
}

static void lqt_getTypePtr(lua_State *L, int idx, QMetaType::Type type, void *ptr) {

    switch(type) {
        case QMetaType::Bool: *reinterpret_cast<bool *>(ptr) = lua_toboolean(L, idx) == 1; break;
        case QMetaType::Int: *reinterpret_cast<int *>(ptr) = lua_tointeger(L, idx); break;
        case QMetaType::UInt: *reinterpret_cast<unsigned int *>(ptr) = (unsigned int) lua_tonumber(L, idx); break;
        case QMetaType::LongLong: *reinterpret_cast<long long *>(ptr) = (long long) lua_tonumber(L, idx); break;
        case QMetaType::ULongLong: *reinterpret_cast<unsigned long long *>(ptr) = (unsigned long long) lua_tonumber(L, idx); break;
        case QMetaType::Double: *reinterpret_cast<double *>(ptr) = lua_tonumber(L, idx); break;
        case QMetaType::Long: *reinterpret_cast<long *>(ptr) = (long) lua_tonumber(L, idx); break;
        case QMetaType::Short: *reinterpret_cast<short *>(ptr) = (short) lua_tonumber(L, idx); break;
        case QMetaType::Char: *reinterpret_cast<char *>(ptr) = (char) lua_tonumber(L, idx); break;
        case QMetaType::ULong: *reinterpret_cast<unsigned long *>(ptr) = (unsigned long) lua_tonumber(L, idx); break;
        case QMetaType::UShort: *reinterpret_cast<unsigned short *>(ptr) = (unsigned short) lua_tonumber(L, idx); break;
        case QMetaType::UChar: *reinterpret_cast<unsigned char *>(ptr) = (unsigned char) lua_tonumber(L, idx); break;
        case QMetaType::Float: *reinterpret_cast<float *>(ptr) = (float) lua_tonumber(L, idx); break;
        case QMetaType::SChar: *reinterpret_cast<signed char *>(ptr) = (signed char) lua_tonumber(L, idx); break;

        case QMetaType::QObjectStar: *reinterpret_cast<QObject **>(ptr) = (QObject *) lqtL_toudata(L, idx, "QObject*");  break;

        #define CASE_TYPE(Type)\
            case QMetaType::Type: *reinterpret_cast<Type *>(ptr) = *(Type*) lqtL_convert(L, idx, #Type"*"); break;

        CASE_TYPE(QChar)
        CASE_TYPE(QString)
        CASE_TYPE(QStringList)
        CASE_TYPE(QByteArray)
        CASE_TYPE(QBitArray)
        CASE_TYPE(QDate)
        CASE_TYPE(QTime)
        CASE_TYPE(QDateTime)
        CASE_TYPE(QUrl)
        CASE_TYPE(QLocale)
        CASE_TYPE(QRect)
        CASE_TYPE(QRectF)
        CASE_TYPE(QSize)
        CASE_TYPE(QSizeF)
        CASE_TYPE(QLine)
        CASE_TYPE(QLineF)
        CASE_TYPE(QPoint)
        CASE_TYPE(QPointF)
        CASE_TYPE(QRegExp)
        CASE_TYPE(QEasingCurve)
        CASE_TYPE(QUuid)
        CASE_TYPE(QVariant)
        CASE_TYPE(QModelIndex)
        CASE_TYPE(QPersistentModelIndex)
        CASE_TYPE(QRegularExpression)
        CASE_TYPE(QJsonValue)
        CASE_TYPE(QJsonObject)
        CASE_TYPE(QJsonArray)
        CASE_TYPE(QJsonDocument)
        CASE_TYPE(QByteArrayList)
        CASE_TYPE(QVariantMap)
        CASE_TYPE(QVariantList)
        CASE_TYPE(QVariantHash)
        CASE_TYPE(QCborSimpleType)
        CASE_TYPE(QCborValue)
        CASE_TYPE(QCborArray)
        CASE_TYPE(QCborMap)

        #ifdef MODULE_qtgui
        // Gui types
        CASE_TYPE(QFont)
        CASE_TYPE(QPixmap)
        CASE_TYPE(QBrush)
        CASE_TYPE(QColor)
        CASE_TYPE(QPalette)
        CASE_TYPE(QIcon)
        CASE_TYPE(QImage)
        CASE_TYPE(QPolygon)
        CASE_TYPE(QRegion)
        CASE_TYPE(QBitmap)
        CASE_TYPE(QCursor)
        CASE_TYPE(QKeySequence)
        CASE_TYPE(QPen)
        CASE_TYPE(QTextLength)
        CASE_TYPE(QTextFormat)
        CASE_TYPE(QMatrix)
        CASE_TYPE(QTransform)
        CASE_TYPE(QMatrix4x4)
        CASE_TYPE(QVector2D)
        CASE_TYPE(QVector3D)
        CASE_TYPE(QVector4D)
        CASE_TYPE(QQuaternion)
        CASE_TYPE(QPolygonF)
        #endif // MODULE_qtgui

        // Widget types
        #ifdef MODULE_qtwidgets
        CASE_TYPE(QSizePolicy)
        #endif // MODULE_qtwidgets

        #undef CASE_TYPE

        // LastCoreType = QCborMap,
        // LastGuiType = QPolygonF,
        // User = 1024
        // Void = 43,
        // Nullptr = 51,
        // UnknownType = 0, 
        // VoidStar = 31,
        default: break;
    }
}

#include "lqt_metamethod.inl"

static const char * callTypeToString(QMetaObject::Call call)
{
    switch(call) {
        case QMetaObject::InvokeMetaMethod: return "InvokeMetaMethod";
        case QMetaObject::ReadProperty: return "ReadProperty";
        case QMetaObject::WriteProperty: return "WriteProperty";
        case QMetaObject::ResetProperty: return "ResetProperty";
        case QMetaObject::QueryPropertyDesignable: return "QueryPropertyDesignable";
        case QMetaObject::QueryPropertyScriptable: return "QueryPropertyScriptable";
        case QMetaObject::QueryPropertyStored: return "QueryPropertyStored";
        case QMetaObject::QueryPropertyEditable: return "QueryPropertyEditable";
        case QMetaObject::QueryPropertyUser: return "QueryPropertyUser";
        case QMetaObject::CreateInstance: return "CreateInstance";
        case QMetaObject::IndexOfMethod: return "IndexOfMethod";
        case QMetaObject::RegisterPropertyMetaType: return "RegisterPropertyMetaType";
        case QMetaObject::RegisterMethodArgumentMetaType: return "RegisterMethodArgumentMetaType";
    }
    return "???";
}

static int lqt_MetaCallProperty (lua_State *L
    , QObject *self
    , QObject *acceptor
    , QMetaObject::Call call
    , const char *name
    , int index
    , void **args
) {
    int callindex = 0, oldtop = 0;
    oldtop = lua_gettop(L);
    lqtL_pushudata(L, self, name);
    lua_getfield(L, -1, LQT_OBJPROPS);
    if(!lua_istable(L, -1)) {
        printf("NO LQT_OBJPROPS\n");
        lua_settop(L, oldtop);
        return -1;
    }

    lua_rawgeti(L, -1, index + 1);
    if(!lua_istable(L, -1)) {
        printf("NO LQT_OBJPROPS[index + 1]\n");
        lua_settop(L, oldtop);
        return -1;
    }

    // get property type, lua function index, see meta_property.lua
    lua_rawgeti(L, -1, 1);
    int type = lua_tointeger(L, -1);
    lua_pop(L, 1);

    int funcIndex = -1;
    int nparam = 0, nret = 0;
    switch(call) {
        case QMetaObject::ReadProperty: nret = 1; funcIndex = 3; break;
        case QMetaObject::WriteProperty: nparam = 1; funcIndex = 4; break;
        case QMetaObject::ResetProperty: funcIndex = 5; break;
        case QMetaObject::QueryPropertyDesignable: nret = 1; funcIndex = 6; break;
        case QMetaObject::QueryPropertyScriptable: nret = 1; funcIndex = 7; break;
        case QMetaObject::QueryPropertyStored: nret = 1; funcIndex = 8; break;
        case QMetaObject::QueryPropertyEditable: nret = 1; funcIndex = 9; break;
        case QMetaObject::QueryPropertyUser: nret = 1; funcIndex = 10; break;
        break;
        default: {
            lua_settop(L, oldtop);
            return -1;
        }
    }
    lua_rawgeti(L, -1, funcIndex);

    if(!lua_isfunction(L, -1)) {
        printf("NO LQT_OBJPROPS[index + 1][%d]\n", funcIndex);
        lua_settop(L, oldtop);
        return -1;
    }

    #ifdef VERBOSE_BUILD
    printf("MetaProperty self:%s, call:%s, name:%s, index:%d\n"
        , self->metaObject()->className()
        , callTypeToString(call)
        , name
        , index
    );
    #endif

    lqtL_pushqobject(L, self);

    if(call == QMetaObject::WriteProperty) {
        lqt_pushTypePtr(L, 0, (QMetaType::Type) type, nullptr, args[0]);
    }

    lua_call(L, nparam + 1, nret);

    switch(call) {
        case QMetaObject::ReadProperty: {
            lqt_getTypePtr(L, -1, (QMetaType::Type) type, args[0]);
            lua_pop(L, 1);
        } break;

        case QMetaObject::QueryPropertyDesignable:
        case QMetaObject::QueryPropertyScriptable:
        case QMetaObject::QueryPropertyStored:
        case QMetaObject::QueryPropertyEditable:
        case QMetaObject::QueryPropertyUser: {

            if(!lua_isboolean(L, -1)) {
                printf("self:%s, call:%s - must return a boolean value!\n"
                    , self->metaObject()->className()
                    , callTypeToString(call)
                );
            } else {
                bool *b = reinterpret_cast<bool*>(args[0]);
                *b = lua_toboolean(L, -1) == 1;
                lua_pop(L, 1);
            }
        } break;

        default:
            break;
    }

    lua_settop(L, oldtop);
    return -1;
}

int lqtL_qt_metacall (lua_State *L, QObject *self, QObject *acceptor,
        QMetaObject::Call call, const char *name,
        int index, void **args)
{
    #ifdef VERBOSE_BUILD
    printf("Metacall self:%s, acceptor:%s, call:%s, name:%s, index:%d\n"
        , self->metaObject()->className()
        , acceptor->metaObject()->className()
        , callTypeToString(call)
        , name
        , index
    );
    #endif

    switch(call) {
        case QMetaObject::InvokeMetaMethod:
            return lqt_InvokeMetaMethod(L, self, acceptor, call, name, index, args);
        case QMetaObject::ReadProperty:
        case QMetaObject::WriteProperty:
        case QMetaObject::ResetProperty:
        case QMetaObject::QueryPropertyDesignable:
        case QMetaObject::QueryPropertyScriptable:
        case QMetaObject::QueryPropertyStored:
        case QMetaObject::QueryPropertyEditable:
        case QMetaObject::QueryPropertyUser:
            return lqt_MetaCallProperty(L, self, acceptor, call, name, index, args);
        default:
            break;
    }
    return -1;
}
