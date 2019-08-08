set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(lrdb)

set(CMAKE_MACOSX_RPATH 1)

# if(NOT MSVC)#-Wall nonsense on MSVC
#   add_definitions(-Wall -W)
#   add_definitions(-pedantic)
#   add_definitions(-Wno-variadic-macros)
#   add_definitions ("-Wno-unused-local-typedefs")
#   add_definitions ("-Wno-unknown-warning-option")
#   add_definitions("-std=c++11")
# endif(NOT MSVC)

include_directories(${LUA_INCLUDE_DIRS}
	../../depends/lrdb/include
	../../depends/lrdb/third_party/picojson
	../../depends/lrdb/third_party/asio/asio/include
)

set(lrdb_src
	main.cpp
)

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(lrdb MODULE ${lrdb_src})

target_link_libraries(lrdb ${LUA_LIBS_FOR_MODULE})
set_target_properties(lrdb PROPERTIES PREFIX "")
set_target_properties(lrdb PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
