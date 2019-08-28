set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(lfs)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/luafilesystem/src
)

set(lfs_src
	../../modules/src/luafilesystem/src/lfs.h
	../../modules/src/luafilesystem/src/lfs.c
)

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(lfs MODULE ${lfs_src})

target_link_libraries(lfs ${LUA_LIBS_FOR_MODULE})
set_target_properties(lfs PROPERTIES PREFIX "")
set_target_properties(lfs PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
