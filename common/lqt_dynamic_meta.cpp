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

// static const uint qt_meta_data_LqtSlotAcceptor[] = {
//  // content:
//        8,       // revision
//        0,       // classname
//        0,    0, // classinfo
//        6,   14, // methods
//        0,    0, // properties
//        0,    0, // enums/sets
//        0,    0, // constructors
//        0,       // flags
//        0,       // signalCount
//  // slots: name, argc, parameters, tag, flags
//              1,    1,   44,    2, 0x0a /* Public */,
//              1,    0,   47,    2, 0x0a /* Public */,
//              1,    1,   48,    2, 0x0a /* Public */,
//              1,    2,   51,    2, 0x0a /* Public */,
//              1,    1,   56,    2, 0x0a /* Public */,
//              1,    1,   59,    2, 0x0a /* Public */,
//  // slots: parameters
//  // return_type      param_types[argc] string_index[args]
//     QMetaType::Void, QMetaType::QObjectStar,    3,
//     QMetaType::Void,
//     QMetaType::Void, QMetaType::LongLong,    3,
//     QMetaType::Void, QMetaType::Int, QMetaType::LongLong,    3,    4,
//     QMetaType::Void, QMetaType::QString,    3,
//     QMetaType::Void, QMetaType::Int,    3,
//        0        // eod
// };        

// #define QT_MOC_LITERAL(idx, ofs, len) \
//     Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
//     qptrdiff(offsetof(qt_meta_stringdata_LqtSlotAcceptor_t, stringdata0) + ofs \
//         - idx * sizeof(QByteArrayData)) \
//     )

// struct qt_meta_stringdata_LqtSlotAcceptor_t {
//  QByteArrayData data[5];
//  char stringdata0[34];
// };

// static struct qt_meta_stringdata_LqtSlotAcceptor_t qt_meta_stringdata_LqtSlotAcceptor = {
//     {
//                // idx, ofs, len
//      QT_MOC_LITERAL(0, 0, 15), // "LqtSlotAcceptor"
//      QT_MOC_LITERAL(1, 16, 6), // "__slot"
//      QT_MOC_LITERAL(2, 23, 0), // ""
//      QT_MOC_LITERAL(3, 24, 4), // "arg1"
//      QT_MOC_LITERAL(4, 29, 4) // "arg2"
//     },
//     "LqtSlotAcceptor\0__slot\0\0arg1\0arg2"
// };

// #undef QT_MOC_LITERAL

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
    unsigned int *p = (unsigned int *) lua_newuserdata(L, (n + 1) * sizeof(unsigned int));
    p[n] = 0;

    for (int i = 1; i <= n; i++) {
        lua_rawgeti(L, idx - 1, i);
        p[i - 1] = lua_tointeger(L, -1);
        lua_pop(L, 1);
    }
    lua_remove(L, idx - 1);

    // printf("dump lqtL_touintarray data, size = %d\n", (int) n);
    // dump(p, n);

    return p;
}

static QByteArrayData* lqlL_tostringdata (lua_State *L, int idx) {

    // struct qt_meta_stringdata {
    //     QByteArrayData data[5];
    //     char stringdata0[34];
    // };

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

    QByteArrayData *p = (QByteArrayData *) lua_newuserdata(L
        , data_size + stringdata0_len
    );

    // Skip QByteArrayData data[n];
    char *stringdata0 = ((char *) p) + data_size;

    n = 0;
    size_t offset = data_size;
    foreach(QString literal, literals) {
        const char *s = literal.toUtf8().constData();
        size_t sz = strlen(s);

        QByteArrayData *array = &p[n++];
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

        // printf("StringData is : %s\n", (const char *) array->data());
        // printf("Array: %ld %d %ld %d\n", n - 1, array->size, array->offset, offset);
    }

    // printf("Dump stringdata\n");
    // dump((unsigned char *)p, data_size + stringdata0_len);

    return p;
}

const QMetaObject& lqlL_getMetaObject (lua_State *L
    , const char *name
    , const QObject *object
    , QMetaObject& meta_data
    , const QMetaObject& super_data
) {
    lqtL_pushudata(L, object, name);
    {
        lua_getfield(L, -1, LQT_OBJMETASTRING);
        if (lua_isnil(L, -1)) {
               lua_pop(L, 2);
               return super_data;
        }
        lua_getfield(L, -2, LQT_OBJMETADATA);

        // qDebug() << QString("Copying qmeta object for slots in %1").arg(name);
        // printf("Dump qt_meta_stringdata_LqtSlotAcceptor\n");
        // dump((unsigned char *) &qt_meta_stringdata_LqtSlotAcceptor, sizeof(qt_meta_stringdata_LqtSlotAcceptor));
        // printf("Dump qt_meta_data_LqtSlotAcceptor\n");
        // dump((unsigned char *)qt_meta_data_LqtSlotAcceptor
        //     , sizeof(qt_meta_data_LqtSlotAcceptor) / sizeof(qt_meta_data_LqtSlotAcceptor[0])
        // );

        // struct { // private data
        //     const QMetaObject *superdata;
        //     const QByteArrayData *stringdata;
        //     const uint *data;
        //     typedef void (*StaticMetacallFunction)(QObject *, QMetaObject::Call, int, void **);
        //     StaticMetacallFunction static_metacall;
        //     const QMetaObject * const *relatedMetaObjects;
        //     void *extradata; //reserved for future use
        // } d;
        meta_data.d.superdata = &super_data;
        meta_data.d.data = lqtL_touintarray(L, -1);
        meta_data.d.stringdata = lqlL_tostringdata(L, -2);
        meta_data.d.static_metacall = nullptr;
        meta_data.d.relatedMetaObjects = nullptr;
        meta_data.d.extradata = nullptr;

        // printf("%p %p\n", meta_data.d.stringdata, meta_data.d.data);

        // store converted userdata/arraydata to object env table
        lua_setfield(L, -3, "*" LQT_OBJMETADATA);
        lua_setfield(L, -2, "*" LQT_OBJMETASTRING);
    }
    lua_pop(L, 1);
    //qDebug() << (lua_gettop(L) - oldtop);
    return meta_data;
    // return super_data;
}
