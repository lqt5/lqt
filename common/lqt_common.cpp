/*
 * Copyright (c) 2007-2008 Mauro Iazzi
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
#include <iostream>
#include <cstdlib>
#include <cstring>

static void lqtL_getenumtable (lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_ENUMS);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_pushvalue(L, -1);
        lua_setfield(L, LUA_REGISTRYINDEX, LQT_ENUMS);
    }
}

static void lqtL_getpointertable (lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_POINTERS); // (1) get storage for pointers
    if (lua_isnil(L, -1)) { // (1) if there is not
        lua_pop(L, 1); // (0) pop the nil value
        lua_newtable(L); // (1) create a new one
        lua_newtable(L); // (2) create an empty metatable
        lua_pushstring(L, "v"); // (3) push the mode value: weak values are enough
        lua_setfield(L, -2, "__mode"); // (2) set the __mode field
        lua_setmetatable(L, -2); // (1) set it as the metatable
        lua_pushvalue(L, -1); // (2) duplicate the new pointer table
        lua_setfield(L, LUA_REGISTRYINDEX, LQT_POINTERS); // (1) put one copy as storage
    }
}

static void lqtL_getreftable (lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_REFS); // (1) get storage for pointers
    if (lua_isnil(L, -1)) { // (1) if there is not
        lua_pop(L, 1); // (0) pop the nil value
        lua_newtable(L); // (1) create a new one
        lua_newtable(L); // (2) create an empty metatable
        lua_pushstring(L, "v"); // (3) push the mode value: weak values are enough
        lua_setfield(L, -2, "__mode"); // (2) set the __mode field
        lua_setmetatable(L, -2); // (1) set it as the metatable
        lua_pushvalue(L, -1); // (2) duplicate the new pointer table
        lua_setfield(L, LUA_REGISTRYINDEX, LQT_REFS); // (1) put one copy as storage
    }
}

static void lqtL_getrefclasstable(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_REF_CLASS);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
        lua_pushvalue(L, -1);
        lua_setfield(L, LUA_REGISTRYINDEX, LQT_REF_CLASS);
    }
}

static int lqtL_callfunc(lua_State *L, int idx, const char *name, bool once_only) {

    if (!lua_isuserdata(L, idx) || lua_islightuserdata(L, idx)) return 0;
    const void *ptr = lua_touserdata(L, idx);
    lua_pushvalue(L, idx); // [object]
    lua_getfenv(L, -1); // [object, env]
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2); // []
        return 0;
    }
    lua_getfield(L, -1, name); // [object, env, func]
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 3); // []
        return 0;
    }

    // if call once, remove function from object's env table
    if (once_only) {
        // set field as false value
        lua_pushboolean(L, 0); // [object, env, func, false]
        lua_setfield(L, -4, name); // [object, env, func]
    }
    lua_remove(L, -2); // [object, func]

#if VERBOSE_BUILD
    printf("lqtL_callfunc %p %s %s\n"
        , ptr
        , name
        , once_only ? "[ONCE]" : ""
    );
#endif

    lua_insert(L, -2); // [func, object]
    if (lqtL_pcall(L, 1, 0, 0)) { // []
        lua_getglobal(L, "print");
        lua_insert(L, -2);
        lua_call(L, 1, 0);
        // return lua_error(L); // [errstr]
    }

    return 0;
}

void * lqtL_getref (lua_State *L, size_t sz, bool weak) {
    void *ret = NULL;
    lqtL_getreftable(L); // (1)
    ret = lua_newuserdata(L, sz); // (2)
    /*
       lua_newtable(L); // (3)
       lua_getglobal(L, "DEBUG"); // (4)
       lua_setfield(L, -2, "__gc"); // (3)
       lua_setmetatable(L, -2); // (2)
       */
    if (weak) {
        lua_rawseti(L, -2, 1+lua_objlen(L, -2)); // (1)
    } else {
        lua_pushinteger(L, 1+lua_objlen(L, -2)); // (3)
        lua_settable(L, -3); // (1)
    }
    lua_pop(L, 1);
    return ret;
}

bool * lqtL_toboolref (lua_State *L, int index) {
    bool tmp = lua_toboolean(L, index) == 1;
    bool *ret = (bool*)lqtL_getref(L, sizeof(bool), true);
    *ret = tmp;
    return ret;
}

int * lqtL_tointref (lua_State *L, int index) {
    int tmp = lua_tointeger(L, index);
    int *ret = (int*)lqtL_getref(L, sizeof(int), false);
    *ret = tmp;
    return ret;
}

void lqtL_pusharguments (lua_State *L, char **argv) {
    int i = 0;
    lua_newtable(L);
    for (i=0;*argv /* fix the maximum number? */;argv++,i++) {
        lua_pushstring(L, *argv);
        lua_rawseti(L, -2, i+1);
    }
    return;
}

char ** lqtL_toarguments (lua_State *L, int index) {
    char ** ret = (char**)lqtL_getref(L, sizeof(char*)*(lua_objlen(L, index)+1), false);
    const char *str = NULL;
    size_t strlen = 0;
    int i = 0;
    for (i=0;;i++) {
        lua_rawgeti(L, index, i+1);
        if (!lua_isstring(L, -1)) {
            str = NULL; strlen = 0;
            ret[i] = NULL;
            lua_pop(L, 1);
            break;
        } else {
            str = lua_tolstring(L, -1, &strlen);
            ret[i] = (char*)lqtL_getref(L, sizeof(char)*(strlen+1), false);
            strncpy(ret[i], str, strlen+1);
            lua_pop(L, 1);
        }
    }
    return ret;
}

int lqtL_createenum (lua_State *L, lqt_Enum e[], const char *n) {
    luaL_Reg empty[] = { { 0, 0 } };
    lqt_Enum *l = e;
    lqtL_getenumtable(L); // (1)
    lua_newtable(L); // (2)
    lua_pushvalue(L, -1); // (3)
    lua_setfield(L, -3, n); // (2)
    while ( (l->name!=0) ) { // (2)
        lua_pushstring(L, l->name); // (3)
        lua_pushinteger(L, l->value); // (4)
        lua_settable(L, -3); // (2)
        lua_pushinteger(L, l->value); // (3)
        lua_pushstring(L, l->name); // (4)
        lua_settable(L, -3); // (2)
        l++; // (2)
    }
    lua_pop(L, 2); // (0)
    l = e;

    int top = lua_gettop(L);

    const char *name = n;
    for (;;) {
        const char *pos = strchr(name, '.');
        if (pos == NULL)
            break;
        int len = pos - name;
        char *key = (char *) malloc(len + 1);
        memcpy(key, name, len);
        key[len] = '\0';
        name = pos + 1;

        lua_getfield(L, -1, key);
        if (!lua_istable(L, -1)) {
            lua_pop(L, 1);

            if (strcmp(key, "Qt")) {
                lua_newtable(L);
                lua_pushvalue(L, -1);
                lua_setfield(L, -3, key);
            }
        }

        free(key);
    }

    lua_newtable(L);
    while ( (l->name!=0) ) { // (1)
        lua_pushstring(L, l->name); // (2)
        lua_pushinteger(L, l->value); // (3)
        lua_settable(L, -3); // (1)
        lua_pushinteger(L, l->value); // (2)
        lua_pushstring(L, l->name); // (3)
        lua_settable(L, -3); // (1)

        if (!l->class_enum) {
            lua_pushstring(L, l->name); // (2)
            lua_pushinteger(L, l->value); // (3)
            lua_settable(L, -4);
        }

        l++; // (1)
    }
    lua_setfield(L, -2, name);

    lua_settop(L, top);

    return 0;
}

int lqtL_createenumlist (lua_State *L, lqt_Enumlist list[]) {
    while (list->enums!=0 && list->name!=0) {
        lqtL_createenum(L, list->enums, list->name); // (0)
        list++;
    }
    return 0;
}

int lqtL_createglobals (lua_State *L, luaL_Reg libs[]) {
    for(;;) {
        luaL_Reg *r = libs;
        if(r->name == NULL)
            break;
        lua_pushcfunction(L, r->func);
        lua_setfield(L, -2, r->name);
        libs++;
    }
    return 0;
}

static int lqtL_tostring (lua_State *L) {
    if (!lua_isuserdata(L, 1) || lua_islightuserdata(L, 1)) {
        lua_pushfstring(L, "%s: %p"
            , lua_typename(L, lua_type(L, 1))
            , lua_topointer(L, 1)
        );
        return 1;
    }
    lua_getmetatable(L, 1);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1); // (0)
        lua_pushfstring(L, "userdata: %p", lua_touserdata(L, 1));
        return 1;
    }
    lua_getfield(L, -1, "__type"); // (2)
    lua_remove(L, -2); // (1)
    if (!lua_isstring(L, -1)) {
        lua_pop(L, 1);
        lua_pushfstring(L, "userdata: %p", lua_touserdata(L, 1));
    } else {
        void *ud = lqtL_toudata(L, 1, lua_tostring(L, -1));

        lua_getfield(L, 1, "__name");
        if(lua_isstring(L, -1)) {
            lua_pushfstring(L, "(%s)", lua_tostring(L, -1));
            lua_remove(L, -2);
            lua_pushfstring(L, ": %p", ud);
            lua_concat(L, 3);
        } else {
            lua_pop(L, 1);
            lua_pushfstring(L, ": %p", ud);
            lua_concat(L, 2);
        }

    }
    return 1;
}

static int lqtL_gcfunc (lua_State *L) {
    lqtL_callfunc(L, 1, "__uninit", true);

    return lqtL_callfunc(L, 1, "__gc", false);
}

static void dumpStack(const char *msg, lua_State* l) {
    int i;
    int top = lua_gettop(l);
 
    printf("=== %s: %d {\n", msg, top);
 
    for (i = 1; i <= top; i++)
    {  /* repeat for each level */
        int t = lua_type(l, i);
        switch (t) {
            case LUA_TSTRING:  /* strings */
                printf("string: '%s'\n", lua_tostring(l, i));
                break;
            case LUA_TBOOLEAN:  /* booleans */
                printf("boolean %s\n",lua_toboolean(l, i) ? "true" : "false");
                break;
            case LUA_TNUMBER:  /* numbers */
                printf("number: %g\n", lua_tonumber(l, i));
                break;
            default:  /* other values */
                printf("%s: %p\n", lua_typename(l, t), lua_topointer(l, i));
                break;
        }
    }
    printf("} ===\n");  /* end the listing */
}

static int lqtL_newindexfunc (lua_State *L) {
    if (!lua_isuserdata(L, 1) && lua_islightuserdata(L, 1)) return 0;
    
    // first try a setter
    lua_getmetatable(L, 1);
    lua_pushliteral(L, "__set");
    lua_rawget(L, -2);
    if (lua_istable(L, -1)) {
        lua_pushvalue(L, 2);
        lua_gettable(L, -2);
        if (lua_isfunction(L, -1)) {
            lua_CFunction setter = lua_tocfunction(L, -1);
            if (!setter) return luaL_error(L, "Invalid setter %s", lua_tostring(L, 2));
            return setter(L);
        }
    }

    // then try marking a method override
    lua_settop(L, 4);
    lua_pushliteral(L, "__override");
    lua_rawget(L, -2);
    if (lua_iscfunction(L, -1) && lua_isfunction(L, 3)) {
        lua_CFunction addOverride = lua_tocfunction(L, -1);
        addOverride(L);
    }

    // anyway, use the environment table for the userdata as per-object storage
    lua_settop(L, 3); // (=3)
    lua_getfenv(L, 1); // (+1)
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1); // (+0)
        return 0;
    }
    lua_remove(L, 1); // (+0)
    lua_insert(L, 1); // (+0)
    lua_rawset(L, 1); // (-2)
    return 0;
}

int lqtL_getoverload (lua_State *L, int index, const char *name) {
    luaL_checkstack(L, 2, "no space to grow");
    if (lua_isuserdata(L, index) && !lua_islightuserdata(L, index)) {
        lua_getfenv(L, index); // (1)
        lua_getfield(L, -1, name); // (2)
        lua_remove(L, -2); // (1)
    } else {
        lua_pushnil(L); // (1)
    }
    return 1;
}

static int lqtL_indexfunc (lua_State *L) {
    int i = 1;
    if (lua_isuserdata(L, 1) && !lua_islightuserdata(L, 1)) {
        lua_getmetatable(L, 1);
        lua_pushliteral(L, "__get");
        lua_rawget(L, -2);
        if (lua_istable(L, -1)) {
            lua_pushvalue(L, 2);
            lua_gettable(L, -2);
            if (lua_isfunction(L, -1)) {
                lua_CFunction getter = lua_tocfunction(L, -1);
                if (!getter) return luaL_error(L, "Invalid getter %s", lua_tostring(L, 2));
                return getter(L);
            }
        }
        lua_settop(L, 2);
        lua_getfenv(L, 1); // (1)
        lua_pushvalue(L, 2); // (2)
        lua_gettable(L, -2); // (2)
        if (!lua_isnil(L, -1)) {
            lua_remove(L, -2);
            return 1;
        }
        lua_pop(L, 2); // (0)
    }
    lua_pushnil(L); // (+1)
    while (!lua_isnone(L, lua_upvalueindex(i))) { // (+1)
        lua_pop(L, 1); // (+0)
        lua_pushvalue(L, 2); // (+1)
        if (i==1) {
            lua_rawget(L, lua_upvalueindex(i)); // (+1)
        } else {
            lua_gettable(L, lua_upvalueindex(i)); // (+1)
        }
        if (!lua_isnil(L, -1)) break;
        i++;
    }
    return 1; // (+1)
}

static int lqtL_pushindexfunc (lua_State *L, const char *name, lqt_Base *bases) {
    int upnum = 1;
    luaL_newmetatable(L, name); // (1)
    while (bases->basename!=NULL) {
        luaL_newmetatable(L, bases->basename); // (upnum)
        upnum++;
        bases++;
    }
    lua_pushcclosure(L, lqtL_indexfunc, upnum); // (1)
    return 1;
}

static int lqtL_local_ctor(lua_State*L) {
    lua_getfield(L, 1, "new"); // (+2)
    lua_replace(L, 1); // (+2)
    lua_call(L, lua_gettop(L)-1, LUA_MULTRET);// (X)
    lua_getfield(L, 1, "delete"); // (X+1)
    lua_setfield(L, 1, "__gc"); // (X)

    // local ctor object, remove ref from LQT_REF_CLASS
    {
        lua_getfield(L, 1, "__type");
        const char *name = lua_tostring(L, -1);
        lua_pop(L, 1);
        const void *ptr = lqtL_toudata(L, 1, name);

        lqtL_getrefclasstable(L);
        lua_pushlightuserdata(L, const_cast<void *>(ptr));
        lua_pushnil(L);
        lua_rawset(L, -3);
        lua_pop(L, 1);
    }

    return lua_gettop(L);
}

int lqtL_createclass (lua_State *L, const char *name, luaL_Reg *mt,
    luaL_Reg *getters, luaL_Reg *setters, lua_CFunction override,
    lqt_Base *bases)
{
    int len = 0;
    char *new_name = NULL;
    lqt_Base *bi = bases;
    luaL_newmetatable(L, name); // (1)
    luaL_register(L, NULL, mt); // (1)
    // setup offsets
    lua_pushstring(L, name); // (2) FIXME: remove
    lua_pushinteger(L, 0); // (3) FIXME: remove
    lua_settable(L, -3); // (1) FIXME: remove
    while (bi->basename!=NULL) {
        lua_pushstring(L, bi->basename); // (2) FIXME: remove
        lua_pushinteger(L, bi->offset); // (3) FIXME: remove
        lua_settable(L, -3); // (1) FIXME: remove
        bi++;
    }
    
    if (getters) {
        lua_newtable(L);
        luaL_register(L, NULL, getters);
        lua_setfield(L, -2, "__get");
    }
    if (setters) {
        lua_newtable(L);
        luaL_register(L, NULL, setters);
        lua_setfield(L, -2, "__set");
    }
    if (override) {
        lua_pushcfunction(L, override);
        lua_setfield(L, -2, "__override");
    }
    
    // set metafunctions
    lqtL_pushindexfunc(L, name, bases); // (2)
    lua_setfield(L, -2, "__index"); // (1)
    lua_pushcfunction(L, lqtL_newindexfunc); // (2)
    lua_setfield(L, -2, "__newindex"); // (1)
    lua_pushcfunction(L, lqtL_gcfunc); // (2)
    lua_setfield(L, -2, "__gc"); // (1)
    lua_pushcfunction(L, lqtL_tostring); // (1)
    lua_setfield(L, -2, "__tostring");
    lua_pushstring(L, name);
    lua_setfield(L, -2, "__type");
    // lua_pushcfunction(L, lqtL_local_ctor); // (3)
    // lua_setfield(L, -2, "__call"); // (2)

    // set it as its own metatable
    lua_pushvalue(L, -1); // (2)
    lua_setmetatable(L, -2); // (1)
    lua_pop(L, 1); // (0)
    // len = strlen(name);
    // new_name = (char*)malloc(len*sizeof(char));
    // strncpy(new_name, name, len);
    // new_name[len-1] = '\0';
    lua_newtable(L); // (1)
    luaL_register(L, NULL, mt); // (1)
    // free(new_name);
    // new_name = NULL;
    lua_newtable(L); // (2)
    lua_pushcfunction(L, lqtL_local_ctor); // (3)
    lua_setfield(L, -2, "__call"); // (2)
    lqtL_pushindexfunc(L, name, bases); // (2)
    lua_setfield(L, -2, "__index"); // (1)
    lua_setmetatable(L, -2); // (1)
    // lua_pop(L, 1); // (0)
    /*
    lua_pushlstring(L, name, strlen(name)-1); // (1)
    lua_newtable(L); // (2)
    luaL_newmetatable(L, name); // (3)
    lua_setmetatable(L, -2); // (2)
    // don't register again but use metatable
    //luaL_register(L, NULL, mt); // (2)
    lua_settable(L, LUA_GLOBALSINDEX); // (0)
    */
    return 0;
}

bool lqtL_isinteger (lua_State *L, int i) {
	if (lua_type(L, i)==LUA_TNUMBER) {
		return lua_tointeger(L, i)==lua_tonumber(L, i);
	} else {
		return false;
	}
}
bool lqtL_isnumber (lua_State *L, int i) {
    return lua_type(L, i)==LUA_TNUMBER;
}
bool lqtL_isstring (lua_State *L, int i) {
    return lua_type(L, i)==LUA_TSTRING;
}
bool lqtL_isboolean (lua_State *L, int i) {
    return lua_type(L, i)==LUA_TBOOLEAN;
}
bool lqtL_missarg (lua_State *L, int index, int n) {
    bool ret = true;
    int i = 0;
    for (i=index;i<index+n;i++) {
        if (!lua_isnoneornil(L, i)) {
            ret = false;
            break;
        }
    }
    return ret;
}

static void CS(lua_State *L) {
    std::cerr << "++++++++++" << std::endl;
    for (int i=1;i<=lua_gettop(L);i++) {
        std::cerr << luaL_typename(L, i) << " " << lua_touserdata(L, i) << std::endl;
    }
    std::cerr << "----------" << std::endl;
}

static void lqtL_ensurepointer (lua_State *L, const void *p) { // (+1)
    lqtL_getpointertable(L); // (1)
    lua_pushlightuserdata(L, const_cast<void*>(p)); // (2)
    lua_gettable(L, -2); // (2)
    if (lua_isnil(L, -1)) { // (2)
        lua_pop(L, 1); // (1)
        const void **pp = static_cast<const void**>(lua_newuserdata(L, sizeof(void*))); // (2)
        *pp = p; // (2)
        lua_newtable(L); // (3)
        lua_setfenv(L, -2); // (2)
        lua_pushlightuserdata(L, const_cast<void*>(p)); // (3)
        lua_pushvalue(L, -2); // (4)
        lua_settable(L, -4); // (2)
    } else {
        //const void **pp = static_cast<const void**>(lua_touserdata(L, -1)); // (2)
        //if (pp!=NULL) *pp = p; // (2)
    }
    // (2)
    lua_remove(L, -2); // (1)
}

void lqtL_register (lua_State *L, const void *p, const char *name) { // (+0)
    lqtL_ensurepointer(L, p);
    lua_pop(L, 1);

    if (name != NULL) {
#if VERBOSE_BUILD
        printf("lqtL_register %p %s\n", p, name);
#endif
        lqtL_getrefclasstable(L);
        lua_pushlightuserdata(L, const_cast<void*>(p));
        lqtL_pushudata(L, p, name);
        lua_rawset(L, -3);
        lua_pop(L, 1);
    }
}

void lqtL_unregister (lua_State *L, const void *p, const char *name) {
    if (name != NULL) {
#if VERBOSE_BUILD
        printf("lqtL_unregister %p %s\n", p, name);
#endif
        lqtL_getrefclasstable(L);
        {
            lua_pushlightuserdata(L, const_cast<void*>(p));
            lua_rawget(L, -2);
            if(lua_islightuserdata(L, -1) || lua_isuserdata(L, -1)) {

                lqtL_callfunc(L, -1, "__uninit", true);

                lua_pushnil(L);
                lua_setmetatable(L, -2);
            }
            lua_pop(L, 1);
        }
        {
            lua_pushlightuserdata(L, const_cast<void*>(p));
            lua_pushnil(L);
            lua_rawset(L, -3);
        }
        lua_pop(L, 1);
    }

    lqtL_getpointertable(L); // (1)
    lua_pushlightuserdata(L, const_cast<void*>(p)); // (2)
    lua_gettable(L, -2); // (2)
    if (lua_isuserdata(L, -1)) {
        const void **pp = static_cast<const void**>(lua_touserdata(L, -1)); // (2)
        *pp = 0;
    }
    lua_pop(L, 1); // (1)
    lua_pushlightuserdata(L, const_cast<void*>(p)); // (2)
    lua_pushnil(L); // (3)
    lua_settable(L, -3); // (1)
    lua_pop(L, 1); // (0)
}

static const char *lqtL_getQEventMetaType(const QEvent* event) {

    switch(event->type()) {
        case QEvent::None:  //Not an event.
            return "QEvent*";
        case QEvent::ActionAdded:   //A new action has been added (QActionEvent).
            return "QActionEvent*";
        case QEvent::ActionChanged: //An action has been changed (QActionEvent).
            return "QActionEvent*";
        case QEvent::ActionRemoved: //An action has been removed (QActionEvent).
            return "QActionEvent*";
        case QEvent::ActivationChange:  //A widget's top-level window activation state has changed.
            return "QEvent*";
        // case QEvent::ApplicationActivate:   //This enum has been deprecated. Use ApplicationStateChange instead.
        //     return "QEvent*";
        case QEvent::ApplicationActivated:  //This enum has been deprecated. Use ApplicationStateChange instead.
            return "QEvent*";
        case QEvent::ApplicationDeactivate: //This enum has been deprecated. Use ApplicationStateChange instead.
            return "QEvent*";
        case QEvent::ApplicationFontChange: //The default application font has changed.
            return "QEvent*";
        case QEvent::ApplicationLayoutDirectionChange:  //The default application layout direction has changed.
            return "QEvent*";
        case QEvent::ApplicationPaletteChange:  //The default application palette has changed.
            return "QEvent*";
        case QEvent::ApplicationStateChange:    //The state of the application has changed.
            return "QEvent*";
        case QEvent::ApplicationWindowIconChange:   //The application's icon has changed.
            return "QEvent*";
        case QEvent::ChildAdded:    //An object gets a child (QChildEvent).
            return "QChildEvent*";
        case QEvent::ChildPolished: //A widget child gets polished (QChildEvent).
            return "QChildEvent*";
        case QEvent::ChildRemoved:  //An object loses a child (QChildEvent).
            return "QChildEvent*";
        case QEvent::Clipboard: //The clipboard contents have changed.
            return "QEvent*";
        case QEvent::Close: //Widget was closed (QCloseEvent).
            return "QCloseEvent*";
        case QEvent::CloseSoftwareInputPanel:   //A widget wants to close the software input panel (SIP).
            return "QEvent*";
        case QEvent::ContentsRectChange:    //The margins of the widget's content rect changed.
            return "QEvent*";
        case QEvent::ContextMenu:   //Context popup menu (QContextMenuEvent).
            return "QContextMenuEvent*";
        case QEvent::CursorChange:  //The widget's cursor has changed.
            return "QEvent*";
        case QEvent::DeferredDelete:    //The object will be deleted after it has cleaned up (QDeferredDeleteEvent)
            return "QDeferredDeleteEvent*";
        case QEvent::DragEnter: //The cursor enters a widget during a drag and drop operation (QDragEnterEvent).
            return "QDragEnterEvent*";
        case QEvent::DragLeave: //The cursor leaves a widget during a drag and drop operation (QDragLeaveEvent).
            return "QDragLeaveEvent*";
        case QEvent::DragMove:  //A drag and drop operation is in progress (QDragMoveEvent).
            return "QDragMoveEvent*";
        case QEvent::Drop:  //A drag and drop operation is completed (QDropEvent).
            return "QDropEvent*";
        case QEvent::DynamicPropertyChange: //A dynamic property was added, changed, or removed from the object.
            return "QEvent*";
        case QEvent::EnabledChange: //Widget's enabled state has changed.
            return "QEvent*";
        case QEvent::Enter: //Mouse enters widget's boundaries (QEnterEvent).
            return "QEnterEvent*";
        // case QEvent::EnterEditFocus:    //An editor widget gains focus for editing. QT_KEYPAD_NAVIGATION must be defined.
        //     return "QEvent*";
        case QEvent::EnterWhatsThisMode:    //Send to toplevel widgets when the application enters "What's This?" mode.
            return "QEvent*";
        case QEvent::Expose:    //Sent to a window when its on-screen contents are invalidated and need to be flushed from the backing store.
            return "QEvent*";
        case QEvent::FileOpen:  //File open request (QFileOpenEvent).
            return "QFileOpenEvent*";
        case QEvent::FocusIn:   //Widget or Window gains keyboard focus (QFocusEvent).
            return "QFocusEvent*";
        case QEvent::FocusOut:  //Widget or Window loses keyboard focus (QFocusEvent).
            return "QFocusEvent*";
        case QEvent::FocusAboutToChange:    //Widget or Window focus is about to change (QFocusEvent)
            return "QFocusEvent*";
        case QEvent::FontChange:    //Widget's font has changed.
            return "QEvent*";
        case QEvent::Gesture:   //A gesture was triggered (QGestureEvent).
            return "QGestureEvent*";
        case QEvent::GestureOverride:   //A gesture override was triggered (QGestureEvent).
            return "QGestureEvent*";
        case QEvent::GrabKeyboard:  //Item gains keyboard grab (QGraphicsItem only).
            return "QGraphicsItem*";
        case QEvent::GrabMouse: //Item gains mouse grab (QGraphicsItem only).
            return "QGraphicsItem*";
        case QEvent::GraphicsSceneContextMenu:  //Context popup menu over a graphics scene (QGraphicsSceneContextMenuEvent).
            return "QGraphicsSceneContextMenuEvent*";
        case QEvent::GraphicsSceneDragEnter:    //The cursor enters a graphics scene during a drag and drop operation (QGraphicsSceneDragDropEvent).
            return "QGraphicsSceneDragDropEvent*";
        case QEvent::GraphicsSceneDragLeave:    //The cursor leaves a graphics scene during a drag and drop operation (QGraphicsSceneDragDropEvent).
            return "QGraphicsSceneDragDropEvent*";
        case QEvent::GraphicsSceneDragMove: //A drag and drop operation is in progress over a scene (QGraphicsSceneDragDropEvent).
            return "QGraphicsSceneDragDropEvent*";
        case QEvent::GraphicsSceneDrop: //A drag and drop operation is completed over a scene (QGraphicsSceneDragDropEvent).
            return "QGraphicsSceneDragDropEvent*";
        case QEvent::GraphicsSceneHelp: //The user requests help for a graphics scene (QHelpEvent).
            return "QHelpEvent*";
        case QEvent::GraphicsSceneHoverEnter:   //The mouse cursor enters a hover item in a graphics scene (QGraphicsSceneHoverEvent).
            return "QGraphicsSceneHoverEvent*";
        case QEvent::GraphicsSceneHoverLeave:   //The mouse cursor leaves a hover item in a graphics scene (QGraphicsSceneHoverEvent).
            return "QGraphicsSceneHoverEvent*";
        case QEvent::GraphicsSceneHoverMove:    //The mouse cursor moves inside a hover item in a graphics scene (QGraphicsSceneHoverEvent).
            return "QGraphicsSceneHoverEvent*";
        case QEvent::GraphicsSceneMouseDoubleClick: //Mouse press again (double click) in a graphics scene (QGraphicsSceneMouseEvent).
            return "QGraphicsSceneMouseEvent*";
        case QEvent::GraphicsSceneMouseMove:    //Move mouse in a graphics scene (QGraphicsSceneMouseEvent).
            return "QGraphicsSceneMouseEvent*";
        case QEvent::GraphicsSceneMousePress:   //Mouse press in a graphics scene (QGraphicsSceneMouseEvent).
            return "QGraphicsSceneMouseEvent*";
        case QEvent::GraphicsSceneMouseRelease: //Mouse release in a graphics scene (QGraphicsSceneMouseEvent).
            return "QGraphicsSceneMouseEvent*";
        case QEvent::GraphicsSceneMove: //Widget was moved (QGraphicsSceneMoveEvent).
            return "QGraphicsSceneMoveEvent*";
        case QEvent::GraphicsSceneResize:   //Widget was resized (QGraphicsSceneResizeEvent).
            return "QGraphicsSceneResizeEvent*";
        case QEvent::GraphicsSceneWheel:    //Mouse wheel rolled in a graphics scene (QGraphicsSceneWheelEvent).
            return "QGraphicsSceneWheelEvent*";
        case QEvent::Hide:  //Widget was hidden (QHideEvent).
            return "QHideEvent*";
        case QEvent::HideToParent:  //A child widget has been hidden.
            return "QEvent*";
        case QEvent::HoverEnter:    //The mouse cursor enters a hover widget (QHoverEvent).
            return "QHoverEvent*";
        case QEvent::HoverLeave:    //The mouse cursor leaves a hover widget (QHoverEvent).
            return "QHoverEvent*";
        case QEvent::HoverMove: //The mouse cursor moves inside a hover widget (QHoverEvent).
            return "QHoverEvent*";
        case QEvent::IconDrag:  //The main icon of a window has been dragged away (QIconDragEvent).
            return "QIconDragEvent*";
        case QEvent::IconTextChange:    //Widget's icon text has been changed. (Deprecated)
            return "QEvent*";
        case QEvent::InputMethod:   //An input method is being used (QInputMethodEvent).
            return "QInputMethodEvent*";
        case QEvent::InputMethodQuery:  //A input method query event (QInputMethodQueryEvent)
            return "QInputMethodQueryEvent*";
        case QEvent::KeyboardLayoutChange:  //The keyboard layout has changed.
            return "QEvent*";
        case QEvent::KeyPress:  //Key press (QKeyEvent).
            return "QKeyEvent*";
        case QEvent::KeyRelease:    //Key release (QKeyEvent).
            return "QKeyEvent*";
        case QEvent::LanguageChange:    //The application translation changed.
            return "QEvent*";
        case QEvent::LayoutDirectionChange: //The direction of layouts changed.
            return "QEvent*";
        case QEvent::LayoutRequest: //Widget layout needs to be redone.
            return "QEvent*";
        case QEvent::Leave: //Mouse leaves widget's boundaries.
            return "QEvent*";
        // case QEvent::LeaveEditFocus:    //An editor widget loses focus for editing. QT_KEYPAD_NAVIGATION must be defined.
        //     return "QEvent*";
        case QEvent::LeaveWhatsThisMode:    //Send to toplevel widgets when the application leaves "What's This?" mode.
            return "QEvent*";
        case QEvent::LocaleChange:  //The system locale has changed.
            return "QEvent*";
        case QEvent::NonClientAreaMouseButtonDblClick:  //A mouse double click occurred outside the client area (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::NonClientAreaMouseButtonPress: //A mouse button press occurred outside the client area (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::NonClientAreaMouseButtonRelease:   //A mouse button release occurred outside the client area (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::NonClientAreaMouseMove:    //A mouse move occurred outside the client area (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::MacSizeChange: //The user changed his widget sizes (macOS only).
            return "QEvent*";
        case QEvent::MetaCall:  //An asynchronous method invocation via QMetaObject::invokeMethod().
            return "QEvent*";
        case QEvent::ModifiedChange:    //Widgets modification state has been changed.
            return "QEvent*";
        case QEvent::MouseButtonDblClick:   //Mouse press again (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::MouseButtonPress:  //Mouse press (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::MouseButtonRelease:    //Mouse release (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::MouseMove: //Mouse move (QMouseEvent).
            return "QMouseEvent*";
        case QEvent::MouseTrackingChange:   //The mouse tracking state has changed.
            return "QEvent*";
        case QEvent::Move:  //Widget's position changed (QMoveEvent).
            return "QMoveEvent*";
        case QEvent::NativeGesture: //The system has detected a gesture (QNativeGestureEvent).
            return "QNativeGestureEvent*";
        case QEvent::OrientationChange: //The screens orientation has changes (QScreenOrientationChangeEvent).
            return "QScreenOrientationChangeEvent*";
        case QEvent::Paint: //Screen update necessary (QPaintEvent).
            return "QPaintEvent*";
        case QEvent::PaletteChange: //Palette of the widget changed.
            return "QEvent*";
        case QEvent::ParentAboutToChange:   //The widget parent is about to change.
            return "QEvent*";
        case QEvent::ParentChange:  //The widget parent has changed.
            return "QEvent*";
        case QEvent::PlatformPanel: //A platform specific panel has been requested.
            return "QEvent*";
        case QEvent::PlatformSurface:   //A native platform surface has been created or is about to be destroyed (QPlatformSurfaceEvent).
            return "QPlatformSurfaceEvent*";
        case QEvent::Polish:    //The widget is polished.
            return "QEvent*";
        case QEvent::PolishRequest: //The widget should be polished.
            return "QEvent*";
        case QEvent::QueryWhatsThis:    //The widget should accept the event if it has "What's This?" help (QHelpEvent).
            return "QHelpEvent*";
        case QEvent::ReadOnlyChange:    //Widget's read-only state has changed (since Qt 5.4).
            return "QEvent*";
        case QEvent::RequestSoftwareInputPanel: //A widget wants to open a software input panel (SIP).
            return "QEvent*";
        case QEvent::Resize:    //Widget's size changed (QResizeEvent).
            return "QResizeEvent*";
        case QEvent::ScrollPrepare: //The object needs to fill in its geometry information (QScrollPrepareEvent).
            return "QScrollPrepareEvent*";
        case QEvent::Scroll:    //The object needs to scroll to the supplied position (QScrollEvent).
            return "QScrollEvent*";
        case QEvent::Shortcut:  //Key press in child for shortcut key handling (QShortcutEvent).
            return "QShortcutEvent*";
        case QEvent::ShortcutOverride:  //Key press in child, for overriding shortcut key handling (QKeyEvent). When a shortcut is about to trigger, ShortcutOverride is sent to the active window. This allows clients (e.g. widgets) to signal that they will handle the shortcut themselves, by accepting the event. If the shortcut override is accepted, the event is delivered as a normal key press to the focus widget. Otherwise, it triggers the shortcut action, if one exists.
            return "QKeyEvent*";
        case QEvent::Show:  //Widget was shown on screen (QShowEvent).
            return "QShowEvent*";
        case QEvent::ShowToParent:  //A child widget has been shown.
            return "QEvent*";
        case QEvent::SockAct:   //Socket activated, used to implement QSocketNotifier.
            return "QEvent*";
        case QEvent::StateMachineSignal:    //A signal delivered to a state machine (QStateMachine::SignalEvent).
            return "QStateMachine_LQT_SignalEvent*";
        case QEvent::StateMachineWrapped:   //The event is a wrapper for, i.e., contains, another event (QStateMachine::WrappedEvent).
            return "QStateMachine_LQT_WrappedEvent*";
        case QEvent::StatusTip: //A status tip is requested (QStatusTipEvent).
            return "QStatusTipEvent*";
        case QEvent::StyleChange:   //Widget's style has been changed.
            return "QEvent*";
        case QEvent::TabletMove:    //Wacom tablet move (QTabletEvent).
            return "QTabletEvent*";
        case QEvent::TabletPress:   //Wacom tablet press (QTabletEvent).
            return "QTabletEvent*";
        case QEvent::TabletRelease: //Wacom tablet release (QTabletEvent).
            return "QTabletEvent*";
        case QEvent::TabletEnterProximity:  //Wacom tablet enter proximity event (QTabletEvent), sent to QApplication.
            return "QTabletEvent*";
        case QEvent::TabletLeaveProximity:  //Wacom tablet leave proximity event (QTabletEvent), sent to QApplication.
            return "QTabletEvent*";
        case QEvent::TabletTrackingChange:  //The Wacom tablet tracking state has changed (since Qt 5.9).
            return "QTabletEvent*";
        case QEvent::ThreadChange:  //The object is moved to another thread. This is the last event sent to this object in the previous thread. See QObject::moveToThread().
            return "QEvent*";
        case QEvent::Timer: //Regular timer events (QTimerEvent).
            return "QTimerEvent*";
        case QEvent::ToolBarChange: //The toolbar button is toggled on macOS.
            return "QEvent*";
        case QEvent::ToolTip:   //A tooltip was requested (QHelpEvent).
            return "QHelpEvent*";
        case QEvent::ToolTipChange: //The widget's tooltip has changed.
            return "QEvent*";
        case QEvent::TouchBegin:    //Beginning of a sequence of touch-screen or track-pad events (QTouchEvent).
            return "QTouchEvent*";
        case QEvent::TouchCancel:   //Cancellation of touch-event sequence (QTouchEvent).
            return "QTouchEvent*";
        case QEvent::TouchEnd:  //End of touch-event sequence (QTouchEvent).
            return "QTouchEvent*";
        case QEvent::TouchUpdate:   //Touch-screen event (QTouchEvent).
            return "QTouchEvent*";
        case QEvent::UngrabKeyboard:    //Item loses keyboard grab (QGraphicsItem only).
            return "QEvent*";
        case QEvent::UngrabMouse:   //Item loses mouse grab (QGraphicsItem, QQuickItem).
            return "QEvent*";
        case QEvent::UpdateLater:   //The widget should be queued to be repainted at a later time.
            return "QEvent*";
        case QEvent::UpdateRequest: //The widget should be repainted.
            return "QEvent*";
        case QEvent::WhatsThis: //The widget should reveal "What's This?" help (QHelpEvent).
            return "QHelpEvent*";
        case QEvent::WhatsThisClicked:  //A link in a widget's "What's This?" help was clicked.
            return "QEvent*";
        case QEvent::Wheel: //Mouse wheel rolled (QWheelEvent).
            return "QWheelEvent*";
        case QEvent::WinEventAct:   //A Windows-specific activation event has occurred.
            return "QEvent*";
        case QEvent::WindowActivate:    //Window was activated.
            return "QEvent*";
        case QEvent::WindowBlocked: //The window is blocked by a modal dialog.
            return "QEvent*";
        case QEvent::WindowDeactivate:  //Window was deactivated.
            return "QEvent*";
        case QEvent::WindowIconChange:  //The window's icon has changed.
            return "QEvent*";
        case QEvent::WindowStateChange: //The window's state (minimized, maximized or full-screen) has changed (QWindowStateChangeEvent).
            return "QWindowStateChangeEvent*";
        case QEvent::WindowTitleChange: //The window title has changed.
            return "QEvent*";
        case QEvent::WindowUnblocked:   //The window is unblocked after a modal dialog exited.
            return "QEvent*";
        case QEvent::WinIdChange:   //The window system identifer for this native widget has changed.
            return "QEvent*";
        case QEvent::ZOrderChange:  //The widget's z-order has changed. This event is never sent to top level windows.
            return "QEvent*";
        default:
            return "QEvent*";
    }
}

void lqtL_pushudata (lua_State *L, const void *p, const char *name) {
    bool already = false;
    
    if (p == NULL) {
        lua_pushnil(L); // (1)
        return;
    }
    
    lqtL_ensurepointer(L, p); // (1)
    if (lua_getmetatable(L, -1)) {
        // (2)
        lua_pop(L, 1); // (1)
        lua_getfield(L, -1, name); // (2)
        already = lua_toboolean(L, -1) == 1; // (2)
        lua_pop(L, 1); // (1)
    } else {
        // (1)
    }
    if (!already) {
        if (!strcmp(name, "QEvent*"))
            name = lqtL_getQEventMetaType(static_cast<const QEvent*>(p));

        luaL_newmetatable(L, name); // (2)
        lua_setmetatable(L, -2); // (1)
    }
    return;
}

void lqtL_passudata (lua_State *L, const void *p, const char *name) {
    lqtL_pushudata(L, p, name);
    // used only when passing temporaries - should be deleted afterwards
    lua_getfield(L, -1, "delete");
    lua_setfield(L, -2, "__gc");
    return;
}

void lqtL_copyudata (lua_State *L, const void *p, const char *name) {
    luaL_newmetatable(L, name);
    lua_pushstring(L, "new");
    lua_rawget(L, -2);
    if (lua_isnil(L, -1)) {
        std::cerr << "cannot copy " << name << std::endl;
        lua_pop(L, 2);
        lua_pushnil(L);
    } else {
        lua_remove(L, -2);
        lqtL_pushudata(L, p, name);
        if (lqtL_pcall(L, 1, 1, 0)) {
            std::cerr << "error copying " << name << std::endl;
            lua_pop(L, 1);
            lua_pushnil(L);
        }
        // Enable autodeletion for copied stuff
        lua_getfield(L, -1, "delete");
        lua_setfield(L, -2, "__gc");
    }
    return;
}

void *lqtL_toudata (lua_State *L, int index, const char *name) {
    void *ret = 0;
    if (lua_isnil(L, index) && strchr(name, '*')) return ret;
    if (!lqtL_testudata(L, index, name)) return 0;
    void **pp = static_cast<void**>(lua_touserdata(L, index));
    ret = *pp;
    lua_getfield(L, index, name);
    ret = (void*)(lua_tointeger(L, -1) + (char*)ret);
    lua_pop(L, 1);
    return ret;
}

void lqtL_eraseudata (lua_State *L, int index, const char *name) {
    void *ret = 0;
    if (name!=NULL && !lqtL_testudata(L, index, name)) return;
    void **pp = static_cast<void**>(lua_touserdata(L, index));
    void *p = *pp;
    *pp = 0;
    lqtL_getpointertable(L); // (1)
    lua_pushlightuserdata(L, p); // (2)
    lua_pushnil(L); // (3)
    lua_settable(L, -3); // (1)
    lua_pop(L, 1);
    return;
}

bool lqtL_testudata (lua_State *L, int index, const char *name) {
    if (lua_isnil(L, index) && strchr(name, '*')) return true;
    if (!lua_isuserdata(L, index) || lua_islightuserdata(L, index)) return false;

    lua_getmetatable(L, index);
    if(!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return false;
    }
    lua_pop(L, 1);

    lua_getfield(L, index, name);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        return false;
    }
    lua_pop(L, 1);
    return true;
}

const char * lqtL_pushtrace(lua_State *L) {
    lua_getglobal(L, "debug");
    lua_getfield(L, -1, "traceback");
    lua_remove(L, -2);
    lua_call(L, 0, 1);
    return lua_tostring(L, -1);
}

void lqtL_pushenum (lua_State *L, int value, const char *name) {
    lqtL_getenumtable(L);
    lua_getfield(L, -1, name);
    lua_remove(L, -2);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        lua_pushnil(L);
        return;
    }
    lua_pushnumber(L, value);
    lua_gettable(L, -2);
    lua_remove(L, -2);
}

bool lqtL_isenum (lua_State *L, int index, const char *name) {
    bool ret = false;
    if (!lua_isstring(L, index)) return false;
    lqtL_getenumtable(L);
    lua_getfield(L, -1, name);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        return false;
    }
    lua_remove(L, -2);
    lua_pushvalue(L, index);
    lua_gettable(L, -2);
    ret = !lua_isnil(L, -1);
    lua_pop(L, 2);
    return ret;
}

int lqtL_toenum (lua_State *L, int index, const char *name) {
    int ret = -1;
    // index = LQT_TOPOSITIVE(L, index);
    lqtL_getenumtable(L); // (1)
    lua_getfield(L, -1, name); // (2)
    if (lua_isnil(L, -1)) {
        lua_pop(L, 2); //(0)
        return 0;
    }
    lua_pushvalue(L, index); // (3)
    lua_gettable(L, -2); // (3)
    if (lqtL_isinteger(L, -1)) {
        ret = lua_tointeger(L, -1); // (3)
    } else {
        ret = lua_tointeger(L, index); // (3)
    }
    lua_pop(L, 3); // (0)
    return ret;
}

int lqtL_getflags (lua_State *L, int index, const char *name) {
    int ret = 0;
    int eindex = 0;
    int i = 1;
    if (lqtL_isinteger(L, index)) return lua_tointeger(L, index);
    if (!lua_istable(L, index)) return 0;
    lqtL_getenumtable(L); // (1)
    lua_getfield(L, -1, name); // (2)
    if (!lua_istable(L, -1)) {
        // (2)
        lua_pop(L, 2);
        return 0;
    }
    // (2)
    lua_remove(L, -2); // (1)
    eindex = lua_gettop(L);
    for (i=1;;i++) { // (1)
        lua_rawgeti(L, index, i); // (2)
        if (lua_type(L, -1)!=LUA_TSTRING) {
            lua_pop(L, 1); // (1)
            break;
        } else {
            lua_gettable(L, eindex); // (2)
            ret = ret | (int)lua_tointeger(L, -1);
            lua_pop(L, 1); // (1)
        }
    }
    // (1)
    lua_pop(L, 1); // (0)
    return ret;
}

//#include <QDebug>

void lqtL_pushflags (lua_State *L, int value, const char *name) {
    int index = 1;
    lua_newtable(L); // (1) return value
    lqtL_getenumtable(L); // (2)
    lua_getfield(L, -1, name); // (3)
    lua_remove(L, -2); // (2) stack: ret, enumtable
    lua_pushnil(L); // (3) first index
    while (lua_next(L, -2) != 0) { // (4) stack: ret, enumtable, index, value
        //if (lua_isnumber(L, -2)) {
            //qDebug() << ((void*)lua_tointeger(L, -2))
                //<< ((void*)value) << (void*)(lua_tointeger(L, -2)&value)
                //<< ((lua_tointeger(L, -2)&value)==lua_tointeger(L, -2)) << lua_tostring(L, -1);
        //}
        if (lua_isnumber(L, -2) &&
                ((lua_tointeger(L, -2)&value)==lua_tointeger(L, -2))) {
            // (4) if index is the value
            lua_rawseti(L, -4, index); // (3) the string is put into the ret table
            index = index + 1; // (3) the size of the ret table has increased
        } else {
            lua_pop(L, 1); // (3) pop the value
        }
    }
    // (2) lua_next pops the vale and pushes nothing at the end of the iteration
    // (2) stack: ret, enumtable
    lua_pop(L, 1); // (1) stack: ret
    return;
}

int lqtL_pcall_debug_default (lua_State *L, int narg, int nres, int err) {
    int status = 0;
    std::cerr << "entering a pcall" << std::endl;
    status = lua_pcall(L, narg, nres, err);
    std::cerr << "pcall finished with status " << status << std::endl;
    return status;
}

int lqtL_pcall_debug (lua_State *L, int narg, int nres, int err) {
    int status = 0;
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_PCALL);
    lqt_PCallPtr pcall = (lqt_PCallPtr)lua_touserdata(L, -1);
    lua_pop(L, 1);
    if (pcall) {
        status = pcall(L, narg, nres, err);
    } else {
        status = lqtL_pcall_debug_default(L, narg, nres, err);
    }
    return status;
}

void lqtL_pushudatatype (lua_State *L, int index) {
    if (!lua_isuserdata(L, index) || lua_islightuserdata(L, index)) {
        lua_pushstring(L, luaL_typename(L, index));
    } else {
        lua_getfield(L, index, "__type");
        if (lua_isnil(L, -1)) {
            lua_pop(L, 1);
            lua_pushstring(L, luaL_typename(L, index));
        }
    }
}

const char * lqtL_getarglist (lua_State *L) {
    int args = lua_gettop(L);
    lua_checkstack(L, args * 2);
    lua_pushliteral(L, "");
    for(int i = 1; i <= args; i++) {
        lqtL_pushudatatype(L, i);
        if (i<args)
            lua_pushliteral(L, ", ");
    }
    lua_concat(L, 2*args - 1);
    return lua_tostring(L, -1);
}

const char * lqtL_source(lua_State *L, int idx) {
    static char buf[1024]; // TODO: try something better
    lua_Debug ar = {0};
    lua_pushvalue(L, idx);
    lua_getinfo(L, ">S", &ar);
    if (ar.source[0] != '@') {
        sprintf(buf, "%s", ar.source);
    } else {
        sprintf(buf, "%s %s:%d", ar.name, ar.source, ar.linedefined);
    }
    return buf;
}

bool lqtL_is_super(lua_State *L, int idx) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_SUPER);
    void *super = lua_touserdata(L, -1);
    void *comp = lua_touserdata(L, idx);
    bool ret = lua_equal(L, -1, idx);
    lua_pop(L, 1);
    return ret;
}

void lqtL_register_super(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, LQT_SUPER);
    if (lua_isnil(L, -1)) {
        void *ud = lua_newuserdata(L, sizeof(int));
        lua_setfield(L, LUA_REGISTRYINDEX, LQT_SUPER);
    }
    lua_pop(L, 1);
}

// returns true if the value at index `n` can be converted to `to_type`
bool lqtL_canconvert(lua_State *L, int n, const char *to_type) {
    if (lqtL_testudata(L, n, to_type))
        return true;
    int oldtop = lua_gettop(L);
    luaL_getmetatable(L, to_type);
    if (lua_isnil(L, -1)) {
        lua_settop(L, oldtop);
        return false;
    }
    lua_getfield(L, -1, "__test");
    if (lua_isnil(L, -1)) {
        lua_settop(L, oldtop);
        return false;
    }
    lqt_testfunc func = (lqt_testfunc) lua_touserdata(L, -1);
    lua_settop(L, oldtop);
    return func(L, n);
}

// converts the value at index `n` to `to_type` and returns a pointer to it
void *lqtL_convert(lua_State *L, int n, const char *to_type) {
    if (lqtL_testudata(L, n, to_type))
        return lqtL_toudata(L, n, to_type);
    int oldtop = lua_gettop(L);
    luaL_getmetatable(L, to_type);
    if (lua_isnil(L, -1)) {
        lua_settop(L, oldtop);
        return NULL;
    }
    lua_getfield(L, -1, "__convert");
    if (lua_isnil(L, -1)) {
        lua_settop(L, oldtop);
        return NULL;
    }
    lqt_convertfunc func = (lqt_convertfunc) lua_touserdata(L, -1);
    lua_settop(L, oldtop);
    return func(L, n);
}

void lqtL_selfcheck(lua_State *L, void *self, const char *name) {
  if (NULL==self) {
    lua_pushfstring(L, "Instance of %s has already been deleted in:\n", name);
    lqtL_pushtrace(L);
    lua_concat(L, 2);
    lua_error(L);
  }
}

bool lqtL_ispointer(lua_State *L, int idx) {
    return lua_isnil(L, idx)
        || lua_islightuserdata(L, idx)
        // || lua_isuserdata(L, idx)
        // luajit cdata
        || lua_type(L, idx) == 10;
}

void *lqtL_topointer(lua_State *L, int idx) {
    // luajit cdata
    if(lua_type(L, idx) == 10) {
        void **ptr = const_cast<void **> ((const void **) lua_topointer(L, idx));
        return *ptr;
    }
    else if(lua_isnil(L, idx))
        return NULL;
    else
        return lua_touserdata(L, idx);
}

void lqtL_pushpointer(lua_State *L, void *ptr) {
    if(ptr == NULL)
        lua_pushnil(L);
    else
        lua_pushlightuserdata(L, ptr);
}
