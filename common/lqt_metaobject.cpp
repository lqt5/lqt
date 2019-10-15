/*
 * Copyright (c) 2007-2019 Mauro Iazzi, Saniko
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#include "lqt_common.hpp"

// #define VERBOSE_BUILD

#define LQT_OBJMETADATA_STORE ("*" LQT_OBJMETADATA)
#define LQT_OBJMETASTRING_STORE ("*" LQT_OBJMETASTRING)

template<typename T, int column = 16>
void dump(T *data, size_t len) {

    for(size_t i = 0; i < len; i++) {

        printf("%d, ", data[i]);

        if(i % column == column - 1)
            printf("\n");
    }
    printf("\n");
}

static unsigned int * lqtL_touintarray (lua_State *L, int idx) {

    size_t n = lua_objlen(L, idx);
    // n(uint) + uint[n] + eod(uint)
    unsigned int *p = (unsigned int *) lua_newuserdata(L, (n + 2) * sizeof(unsigned int));
    // record array size
    p[0] = n;
    // eod
    p[n] = 0;
#ifdef VERBOSE_BUILD
    printf("lqtL_touintarray n=%d\n", n);
#endif
    for (int i = 1; i <= n; i++) {
        lua_rawgeti(L, idx - 1, i);
        p[i] = lua_tointeger(L, -1);
        lua_pop(L, 1);
    }
    lua_remove(L, idx - 1);
#ifdef VERBOSE_BUILD
    printf("dump lqtL_touintarray data, size = %d\n", (int) n);
    dump(p, n);
#endif
    return &p[1];
}

static QByteArrayData* lqlL_tostringdata (lua_State *L, int idx) {

    size_t n = lua_objlen(L, idx);

    QStringList literals;
    size_t stringdata0_len = 0;
    for (int i = 1; i <= n; i++) {
        lua_rawgeti(L, idx, i);
        const char *literal = lua_tostring(L, -1);
        literals.push_back(literal);
        stringdata0_len += (strlen(literal) + 1);
        lua_pop(L, 1);
    }
    lua_remove(L, idx);

    size_t data_size = sizeof(QByteArrayData) * n;

    // n(uint) + QByteArrayData[n] + stringdata0[]
    unsigned int *p = (unsigned int *) lua_newuserdata(L
        , sizeof(unsigned int) + data_size + stringdata0_len
    );
    // record literal size
    p[0] = literals.size();

    QByteArrayData *data = (QByteArrayData *) &p[1];

    // Skip QByteArrayData data[n];
    char *stringdata0 = ((char *) data) + data_size;

    n = 0;
    size_t offset = data_size;
    foreach(QString literal, literals) {
        QByteArray utf8 = literal.toUtf8();
        const char *s = utf8.constData();
        size_t sz = strlen(s);

        QByteArrayData *array = &data[n++];
        // call QByteArrayData constructor
        //  TODO: call QByteArrayData destructor when free?
        new (array) QByteArrayData();

        array->ref.atomic.store(-1);
        array->size = sz;
        array->alloc = 0;
        array->capacityReserved = 0;
        array->offset = offset;

        offset += (sz + 1) - sizeof(QByteArrayData);

        memcpy(stringdata0, s, sz);
        stringdata0[sz] = '\0';
        stringdata0 += (sz + 1);

#ifdef VERBOSE_BUILD
        printf("StringData is : %s\n", (const char *) array->data());
        printf("Array: %ld %d %ld %d\n", n - 1, array->size, array->offset, offset);
#endif
    }

#ifdef VERBOSE_BUILD
    printf("Dump stringdata\n");
    dump((unsigned char *)p, data_size + stringdata0_len);
#endif

    return data;
}

static bool lqtL_is_meta_dirty(lua_State *L
    , uint data_len
    , uint stringdata_len
) {
    // printf("lqtL_is_meta_dirty %d %d\n", data_len, stringdata_len);

    lua_getfield(L, -3, LQT_OBJMETADATA_STORE);
    if (!lua_isuserdata(L, -1))
    {
        lua_pop(L, 1);
        return true;
    }
    uint *p = (uint *) lua_touserdata(L, -1);
    // printf("data: %d %d\n", p[0], data_len);
    if (p[0] != data_len)
    {
        lua_pop(L, 1);
        return true;
    }
    lua_pop(L, 1);

    lua_getfield(L, -3, LQT_OBJMETASTRING_STORE);
    if (!lua_isuserdata(L, -1))
    {
        lua_pop(L, 1);
        return true;
    }
    p = (uint *) lua_touserdata(L, -1);
    // printf("stringdata: %d %d\n", p[0], stringdata_len);
    if (p[0] != stringdata_len)
    {
        lua_pop(L, 1);
        return true;
    }
    lua_pop(L, 1);

    return false;
}

static QMetaObject& lqtL_get_metaobject (lua_State *L, int index) {

    lua_getfield(L, index, "__metaObject");

    QMetaObject* ret = nullptr;
    // If meta-object was created(at class.lua - classDef.__metaObject), use created class meta object
    //  else create new meta object
    if (!lua_isnil(L, -1) && lqtL_isudata(L, -1, "QMetaObject*")) {

        ret = static_cast<QMetaObject*>(lqtL_toudata(L, -1, "QMetaObject*"));
        lua_pop(L, 1);

    } else {

        lua_pop(L, 1);
        ret = new QMetaObject();
        lqtL_pushudata(L, ret, "QMetaObject*");
        lua_setfield(L, index, "__metaObject");
    }

    return *ret;
}

const QMetaObject& lqtL_qt_metaobject (lua_State *L
    , const char *name
    , const QObject *object
    , const QMetaObject& super_data
) {
    int oldtop = lua_gettop(L);
    lqtL_pushudata(L, object, name);

    lua_getfield(L, -1, LQT_OBJMETASTRING);
    if (lua_isnil(L, -1)) {
           lua_pop(L, 2);
           return super_data;
    }
    lua_getfield(L, -2, LQT_OBJMETADATA);

    QMetaObject &meta_data = lqtL_get_metaobject(L, -3);

    meta_data.d.superdata = &super_data;

    if(!lqtL_is_meta_dirty(L, lua_objlen(L, -1), lua_objlen(L, -2))) {
        lua_pop(L, 2);

        // get stored previous generated data
        lua_getfield(L, -1, LQT_OBJMETASTRING_STORE);
        lua_getfield(L, -2, LQT_OBJMETADATA_STORE);

        // use previous generated metadata
        //  skip length(uint32)
        unsigned int *ptr = (unsigned int *) lua_touserdata(L, -1);
        meta_data.d.data = ptr + 1;

        // use previous generated stringdata
        //  skip length(uint32)
        ptr = (unsigned int *) lua_touserdata(L, -2);
        meta_data.d.stringdata = (QByteArrayData *) (ptr + 1);

        // pop stored data
        lua_pop(L, 2);
    } else {
        // generatoe new metadata/stringdata
        meta_data.d.data = lqtL_touintarray(L, -1);
        meta_data.d.stringdata = lqlL_tostringdata(L, -2);
        // store converted userdata/arraydata to object's env table
        lua_setfield(L, -3, LQT_OBJMETASTRING_STORE);
        lua_setfield(L, -2, LQT_OBJMETADATA_STORE);
    }
    meta_data.d.static_metacall = nullptr;
    meta_data.d.relatedMetaObjects = nullptr;
    meta_data.d.extradata = nullptr;
    // printf("%p %p\n", meta_data.d.stringdata, meta_data.d.data);

    lua_settop(L, oldtop);
    //qDebug() << (lua_gettop(L) - oldtop);
    return meta_data;
}
