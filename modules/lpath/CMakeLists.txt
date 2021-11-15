set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.8.12)
project(lpath)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/lua-lpath
)

set(lpath_src
	../../modules/src/lpath/lpath.c
)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUAMOD_API=LUALIB_API")

if (WIN32)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_BUILD_AS_DLL -fno-strict-aliasing")
endif()

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(path MODULE ${lpath_src})

target_link_libraries(path ${LUA_LIBS_FOR_MODULE})
set_target_properties(path PROPERTIES PREFIX "")
set_target_properties(path PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
