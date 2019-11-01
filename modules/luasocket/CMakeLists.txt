set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(socket)

set(CMAKE_MACOSX_RPATH 1)

add_custom_target(generate_luasocket_embed
	COMMAND ${LUA_CMD}
		"${CMAKE_SOURCE_DIR}/modules/luasocket/embed.lua" 
		"${CMAKE_SOURCE_DIR}/modules/luasocket" 
		"${CMAKE_SOURCE_DIR}/modules/src/luasocket" 
		${EXTRA_LUA_OPTIONS}
	COMMENT "Generating luasocket embed script code"
	VERBATIM)


include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/luasocket/src
)

set(socket_src
	../../modules/luasocket/embed.c
	../../modules/src/luasocket/src/auxiliar.c
	../../modules/src/luasocket/src/auxiliar.h
	../../modules/src/luasocket/src/buffer.c
	../../modules/src/luasocket/src/buffer.h
	../../modules/src/luasocket/src/compat.c
	../../modules/src/luasocket/src/compat.h
	../../modules/src/luasocket/src/except.c
	../../modules/src/luasocket/src/except.h
	../../modules/src/luasocket/src/inet.c
	../../modules/src/luasocket/src/inet.h
	../../modules/src/luasocket/src/io.c
	../../modules/src/luasocket/src/io.h
	../../modules/src/luasocket/src/luasocket.c
	../../modules/src/luasocket/src/luasocket.h
	../../modules/src/luasocket/src/mime.c
	../../modules/src/luasocket/src/mime.h
	../../modules/src/luasocket/src/options.c
	../../modules/src/luasocket/src/options.h
	../../modules/src/luasocket/src/pierror.h
	../../modules/src/luasocket/src/select.c
	../../modules/src/luasocket/src/select.h
	../../modules/src/luasocket/src/serial.c
	../../modules/src/luasocket/src/socket.h
	../../modules/src/luasocket/src/tcp.c
	../../modules/src/luasocket/src/tcp.h
	../../modules/src/luasocket/src/timeout.c
	../../modules/src/luasocket/src/timeout.h
	../../modules/src/luasocket/src/udp.c
	../../modules/src/luasocket/src/udp.h
)

link_directories(${LUA_LIBS_FOR_MODULE})

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_LIB -DLUASOCKET_NODEBUG")

if (WIN32)
	set(socket_platform_src
		../../modules/src/luasocket/src/wsocket.c
		../../modules/src/luasocket/src/wsocket.h
	)
else()
	set(socket_platform_src
		../../modules/src/luasocket/src/unix.c
		../../modules/src/luasocket/src/unix.h
		../../modules/src/luasocket/src/unixdgram.c
		../../modules/src/luasocket/src/unixdgram.h
		../../modules/src/luasocket/src/unixstream.c
		../../modules/src/luasocket/src/unixstream.h
		../../modules/src/luasocket/src/usocket.c
		../../modules/src/luasocket/src/usocket.h
	)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUNIX_HAS_SUN_LEN")
endif()

add_library(socket MODULE ${socket_src} ${socket_platform_src})
add_dependencies(socket generate_luasocket_embed)

target_link_libraries(socket ${LUA_LIBS_FOR_MODULE})
set_target_properties(socket PROPERTIES PREFIX "")
set_target_properties(socket PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
