static int lqt_InvokeMetaMethod (lua_State *L
    , QObject *self
    , QObject *acceptor
    , QMetaObject::Call call
    , const char *name
    , int index
    , void **args
) {
    int callindex = 0, oldtop = 0;
    oldtop = lua_gettop(L);
    lqtL_pushudata(L, self, name); // (1)
    lua_getfield(L, -1, LQT_OBJSIGS); // (2)
    if (lua_isnil(L, -1)) {
        printf("\n");
        // TODO: determine what is wrong
        #ifdef VERBOSE_BUILD
        qDebug() << "Missing singal/slot" << name << lua_tostring(L,-1)
            << "on" << acceptor->objectName() << "with index" << callindex
        ;
        #endif
        lua_settop(L, oldtop);
        QMetaObject::activate(self, self->metaObject(), index, args);
    } else {
        //qDebug() << lua_gettop(L) << luaL_typename(L, -1);
        lua_rawgeti(L, -1, index + 1); // (3)
        if (!lua_istable(L, -1)) {
            #ifdef VERBOSE_BUILD
            qDebug() << "Found signal" << name << lua_tostring(L,-1)
                << "on" << acceptor->objectName() << "with index" << callindex
            ;
            #endif
            lua_settop(L, oldtop);
            QMetaObject::activate(self, self->metaObject(), index, args);
        } else {

            lua_rawgeti(L, -1, 1);
            QLatin1String self_slot_name(lua_tostring(L, -1));
            lua_pop(L, 1);

            lua_rawgeti(L, -1, 2);
            QLatin1String acceptor_slot_name(lua_tostring(L, -1));
            lua_pop(L, 1);

            lua_pop(L, 2); // (1)

            callindex = acceptor->metaObject()->indexOfSlot(acceptor_slot_name.data());
            if (callindex != -1) {
                #ifdef VERBOSE_BUILD
                qDebug() << "Found acceptor slot" << name << lua_tostring(L,-1)
                    << "on" << acceptor->metaObject()->className() << ":" << acceptor->objectName()
                    << "with index" << callindex
                    << "slot" << acceptor_slot_name
                ;
                #endif
                lua_getfield(L, -1, LQT_OBJSLOTS); // (2)
                lua_rawgeti(L, -1, index+1); // (3)
                lua_remove(L, -2); // (2)
                index = acceptor->qt_metacall(call, callindex, args);
                lua_settop(L, oldtop);
                return -1;
            }

            callindex = self->metaObject()->indexOfSlot(self_slot_name.data());
            if (callindex != -1) {
                #ifdef VERBOSE_BUILD
                qDebug() << "Found object slot" << name << lua_tostring(L,-1)
                    << "on" << self->metaObject()->className() << ":" << self->objectName()
                    << "with index" << callindex
                    << "slot" << self_slot_name
                ;
                #endif
                QMetaMethod method = self->metaObject()->method(callindex);

                lua_getfield(L, -1, LQT_OBJSLOTS); // (2)
                lua_rawgeti(L, -1, index + 1); // (3)
                lua_remove(L, -2); // (2)

                lqtL_pushqobject(L, self);

                for (int i = 0; i < method.parameterCount(); i++) {

                    void *ptr = args[i + 1];

                    #ifdef VERBOSE_BUILD
                    printf("Index:%d Type:%d ParamTypeName:%s ParamName:%s Ptr:%p\n"
                        , i
                        , method.parameterType(i)
                        , method.parameterTypes().at(i).constData()
                        , method.parameterNames().at(i).constData()
                        , ptr
                    );
                    #endif

                    QMetaType::Type type = (QMetaType::Type) method.parameterType(i);
                    lqt_pushTypePtr(L, i, type, method.parameterTypes().at(i).constData(), ptr);
                }

                if(lqtL_pcall(L, method.parameterCount() + 1, 0, 0) != 0) {
                    lua_error(L);
                }
            } else {
                #ifdef VERBOSE_BUILD
                qDebug() << "Missing object slot" << name << lua_tostring(L,-1)
                    << "on" << self->metaObject()->className() << ":" << self->objectName()
                    << "slot" << self_slot_name
                ;
                #endif
            }
        }
    }
    lua_settop(L, oldtop);
    return -1;
}
