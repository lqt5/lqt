#ifdef EMSCRIPTEN
#include <emscripten.h>
#endif
#include <iostream>

#include "lrdb/server.hpp"

typedef std::unique_ptr<lrdb::server> server_ptr;

int lrdb_activate(lua_State* L) {
  server_ptr* server = (server_ptr*)lua_touserdata(L, lua_upvalueindex(1));
  if (lua_isnumber(L, 1)) {
    server->reset(new lrdb::server((int16_t)lua_tonumber(L, 1)));
  } else {
    server->reset(new lrdb::server(21110));
  }
  (*server)->reset(L);
  return 0;
}
int lrdb_deactivate(lua_State* L) {
  server_ptr* server = (server_ptr*)lua_touserdata(L, lua_upvalueindex(1));
  server->reset();
  return 0;
}
int lrdb_destruct(lua_State* L) {
  server_ptr* server = (server_ptr*)lua_touserdata(L, 1);
  server->~server_ptr();
  return 0;
}

#if defined(_WIN32) || defined(_WIN64)
extern "C" __declspec(dllexport)
#else
extern "C" __attribute__((visibility("default")))
#endif
    int luaopen_lrdb(lua_State* L) {
  //	luaL_dostring(L, "debug=nil");
  lua_createtable(L, 0, 3);
  int mod = lua_gettop(L);

  void* storage = lua_newuserdata(L, sizeof(server_ptr));
  new (storage) server_ptr();
  int sserver = lua_gettop(L);
  lua_createtable(L, 0, 1);
  lua_pushcclosure(L, &lrdb_destruct, 0);
  lua_setfield(L, -2, "__gc");
  lua_setmetatable(L, sserver);
  lua_pushvalue(L, sserver);
  lua_pushcclosure(L, &lrdb_activate, 1);
  lua_setfield(L, mod, "activate");
  lua_pushvalue(L, sserver);
  lua_pushcclosure(L, &lrdb_deactivate, 1);
  lua_setfield(L, mod, "deactivate");

  lua_pushvalue(L, mod);
  return 1;
}