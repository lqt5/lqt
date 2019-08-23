#include "lqt_qt.hpp"
#include "lqt_embed.h"

void lqtL_embed(lua_State *L) {

    luaopen_embed_preload(L);
    luaopen_embed_main(L);
    {
        if(!lua_isfunction(L, -1))
            lua_error(L);

        lua_pushvalue(L, -3);
        lua_newtable(L);
        {
            lua_pushstring(L, LQT_OBJMETASTRING);
            lua_rawseti(L, -2, 1);
            lua_pushstring(L, LQT_OBJMETADATA);
            lua_rawseti(L, -2, 2);
            lua_pushstring(L, LQT_OBJSLOTS);
            lua_rawseti(L, -2, 3);
            lua_pushstring(L, LQT_OBJSIGS);
            lua_rawseti(L, -2, 4);
        }
        lua_pcall(L, 2, 1, 0);

        if(!lua_isboolean(L, -1))
            lua_error(L);
        lua_pop(L, 1);
    }
}
