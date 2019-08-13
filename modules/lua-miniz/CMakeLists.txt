set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(miniz)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../depends/lua-miniz
)

set(miniz_src
	# ../../depends/lua-miniz/miniz.c
	../../depends/lua-miniz/miniz.h
	../../depends/lua-miniz/lminiz.c
)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUAMOD_API=LUALIB_API")

if (WIN32)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_BUILD_AS_DLL -fno-strict-aliasing")
endif()

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(miniz MODULE ${miniz_src})

target_link_libraries(miniz ${LUA_LIBS_FOR_MODULE})
set_target_properties(miniz PROPERTIES PREFIX "")
set_target_properties(miniz PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
