#include "lqt_qt.hpp"

#define MAX_ARGUMENTS 16

bool lqtL_isGenericArgument(lua_State *L, int i) {

    int type = lua_type(L, i);

    switch(type) {
        case LUA_TTABLE: {
            // GenericArgument tuple
            //  { type, value }
            int len = lua_objlen(L, i);
            if (len > 0 && len <= 2)
                return true;
        } break;
        case LUA_TBOOLEAN:
        case LUA_TNUMBER:
        case LUA_TSTRING:
            return true;
        case LUA_TLIGHTUSERDATA:
        case LUA_TUSERDATA: {
            // lqt userdata
            lua_getmetatable(L, i);
            if(lua_istable(L, -1)) {
                lua_getfield(L, -1, "__type");
                if(lua_isstring(L, -1)) {
                    lua_pop(L, 2);
                    return true;
                }
                lua_pop(L, 1);
            }
            lua_pop(L, 1);
        } break;
    }

    lua_getglobal(L, "tostring");
    lua_pushvalue(L, i);
    lua_call(L, 1, 1);
    const char *s = lua_tostring(L, -1);
    lua_pop(L, 1);

    luaL_error(L, "Argument[%d] %s cannot convert to GenericArgument!", i, s);

    return false;
}

static QGenericArgument lqt_convertTupleArgument(lua_State *L, int i) {

    lua_rawgeti(L, i, 1);
    const char *tuple_type = luaL_checkstring(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, i, 2);
    if(strcmp(tuple_type, "int") == 0 && lua_isnumber(L, -1)) {
        static int tuple_ints[MAX_ARGUMENTS];
        int& tuple_val = tuple_ints[i];
        tuple_val = lua_tointeger(L, -1);
        lua_pop(L, 1);
        return QGenericArgument("int", &tuple_val);
    }
    else if(lqtL_isudata(L, -1, tuple_type)) {
        static void* tuple_ptr[MAX_ARGUMENTS];
        tuple_ptr[i] = lqtL_toudata(L, -1, tuple_type);
        lua_pop(L, 1);
        return QGenericArgument(tuple_type, &tuple_ptr[i]);
    }
    else {
        luaL_error(L, "Unknown tuple argument type : %s", tuple_type);
    }

    return QGenericArgument();
}

static QGenericArgument lqt_convertUserdata(lua_State *L, int i, const char *type, void *ptr) {

    if(type == nullptr || ptr == nullptr) {
        return QGenericArgument();
    }

    #define CASE_VARIANT_TYPE(...)\
        else if(strcmp(type, #__VA_ARGS__"*") == 0) {\
            __VA_ARGS__ const& arg = *static_cast<__VA_ARGS__ *>(lqtL_toudata(L, i, #__VA_ARGS__"*"));\
            return QGenericArgument(#__VA_ARGS__, &arg);\
        }

    #ifndef QT_NO_DATASTREAM
        CASE_VARIANT_TYPE(QDataStream)
    #endif // QT_NO_DATASTREAM

    CASE_VARIANT_TYPE(QByteArray)
    CASE_VARIANT_TYPE(QBitArray)
    CASE_VARIANT_TYPE(QString)
    CASE_VARIANT_TYPE(QLatin1String)
    CASE_VARIANT_TYPE(QDate)
    CASE_VARIANT_TYPE(QTime)
    CASE_VARIANT_TYPE(QDateTime)
    CASE_VARIANT_TYPE(QList<QVariant>)
    CASE_VARIANT_TYPE(QMap<QString,QVariant>)
    CASE_VARIANT_TYPE(QHash<QString,QVariant>)

    #ifndef QT_NO_GEOM_VARIANT
        CASE_VARIANT_TYPE(QSize)
        CASE_VARIANT_TYPE(QSizeF)
        CASE_VARIANT_TYPE(QPoint)
        CASE_VARIANT_TYPE(QPointF)
        CASE_VARIANT_TYPE(QLine)
        CASE_VARIANT_TYPE(QLineF)
        CASE_VARIANT_TYPE(QRect)
        CASE_VARIANT_TYPE(QRectF)
    #endif // QT_NO_GEOM_VARIANT

    CASE_VARIANT_TYPE(QLocale)
    #ifndef QT_NO_REGEXP
        CASE_VARIANT_TYPE(QRegExp)
    #endif // QT_NO_REGEXP

    #if QT_CONFIG(regularexpression)
        CASE_VARIANT_TYPE(QRegularExpression)
    #endif // QT_CONFIG(regularexpression)

    #ifndef QT_BOOTSTRAPPED
        CASE_VARIANT_TYPE(QUrl)
        CASE_VARIANT_TYPE(QEasingCurve)
        CASE_VARIANT_TYPE(QUuid)
        CASE_VARIANT_TYPE(QJsonValue)
        CASE_VARIANT_TYPE(QJsonObject)
        CASE_VARIANT_TYPE(QJsonArray)
        CASE_VARIANT_TYPE(QJsonDocument)
    #endif // QT_BOOTSTRAPPED

    #if QT_CONFIG(itemmodel)
        CASE_VARIANT_TYPE(QModelIndex)
        CASE_VARIANT_TYPE(QPersistentModelIndex)
    #endif

    #undef CASE_TYPE

    static void* pointers[MAX_ARGUMENTS];
    pointers[i] = ptr;
    return QGenericArgument(type, &pointers[i]);
}

QGenericArgument lqtL_getGenericArgument(lua_State *L, int i) {

    if(i >= MAX_ARGUMENTS)
        luaL_error(L, "Argument index %d out of range %d !", i, MAX_ARGUMENTS);

    int oldtop = lua_gettop(L);

    int type = lua_type(L, i);
    switch(type) {
        case LUA_TTABLE: {
            // Tuple GenericArgument
            //  { type, value }
            return lqt_convertTupleArgument(L, i);
        }

        case LUA_TBOOLEAN: {
            static bool booleans[MAX_ARGUMENTS];
            booleans[i] = lua_toboolean(L, i) == 1;
            return QGenericArgument("bool", &booleans[i]);
        }

        case LUA_TNUMBER: {
            static lua_Number numbers[MAX_ARGUMENTS];
            numbers[i] = lua_tonumber(L, i);
            return QGenericArgument("double", &numbers[i]);
        }

        case LUA_TSTRING: {
            QString const& arg = *static_cast<QString*>(lqtL_convert(L, i, "QString*"));
            lua_pop(L, 1);
            return QGenericArgument("QString", &arg);
        }

        case LUA_TLIGHTUSERDATA:
        case LUA_TUSERDATA: {
            lua_getmetatable(L, i);
            if(lua_istable(L, -1)) {
                lua_getfield(L, -1, "__type");
                if(lua_isstring(L, -1)) {

                    const char *type = lua_tostring(L, -1);
                    void *ptr = lqtL_toudata(L, i, type);
                    lua_pop(L, 2);

                    return lqt_convertUserdata(L, i, type, ptr);
                }
                lua_pop(L, 1);
            }
            lua_pop(L, 1);
        } break;
    }

    lua_getglobal(L, "tostring");
    lua_pushvalue(L, i);
    lua_call(L, 1, 1);
    const char *s = lua_tostring(L, -1);
    lua_pop(L, 1);

    luaL_error(L, "Invalid GenericArgument [%d] %s", i, s);
    return QGenericArgument();
}
