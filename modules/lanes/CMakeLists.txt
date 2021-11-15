set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.8.12)
project(lanes)

set(CMAKE_MACOSX_RPATH 1)

add_custom_target(generate_lanes_embed
	COMMAND ${LUA_CMD}
		"${CMAKE_SOURCE_DIR}/modules/lanes/embed.lua" 
		"${CMAKE_SOURCE_DIR}/modules/lanes" 
		"${CMAKE_SOURCE_DIR}/modules/src/lanes" 
		${EXTRA_LUA_OPTIONS}
	COMMENT "Generating lanes embed script code"
	VERBATIM)

include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/lanes/src
)

set(lanes_src
	../../modules/lanes/embed.c
	../../modules/src/lanes/src/cancel.c
	../../modules/src/lanes/src/cancel.h
	../../modules/src/lanes/src/compat.c
	../../modules/src/lanes/src/compat.h
	../../modules/src/lanes/src/deep.c
	../../modules/src/lanes/src/deep.h
	../../modules/src/lanes/src/keeper.c
	../../modules/src/lanes/src/keeper.h
	../../modules/src/lanes/src/lanes.c
	../../modules/src/lanes/src/lanes.h
	../../modules/src/lanes/src/lanes_private.h
	../../modules/src/lanes/src/linda.c
	../../modules/src/lanes/src/macros_and_utils.h
	../../modules/src/lanes/src/platform.h
	../../modules/src/lanes/src/threading.c
	../../modules/src/lanes/src/threading.h
	../../modules/src/lanes/src/threading_osx.h
	../../modules/src/lanes/src/tools.c
	../../modules/src/lanes/src/tools.h
	../../modules/src/lanes/src/uniquekey.h
	../../modules/src/lanes/src/universe.c
	../../modules/src/lanes/src/universe.h
)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_LIB")

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(lanes MODULE ${lanes_src})
add_dependencies(lanes generate_lanes_embed)

target_link_libraries(lanes ${LUA_LIBS_FOR_MODULE})
set_target_properties(lanes PROPERTIES PREFIX "")
set_target_properties(lanes PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
