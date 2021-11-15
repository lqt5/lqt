set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.8.12)
project(lpeglabel)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/lpeglabel
)

set(lpeglabel_src
	../../modules/src/lpeglabel/lpcap.c
	../../modules/src/lpeglabel/lpcap.h
	../../modules/src/lpeglabel/lpcode.c
	../../modules/src/lpeglabel/lpcode.h
	../../modules/src/lpeglabel/lpprint.c
	../../modules/src/lpeglabel/lpprint.h
	../../modules/src/lpeglabel/lptree.c
	../../modules/src/lpeglabel/lptree.h
	../../modules/src/lpeglabel/lptypes.h
	../../modules/src/lpeglabel/lpvm.c
	../../modules/src/lpeglabel/lpvm.h
)

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(lpeglabel MODULE ${lpeglabel_src})

target_link_libraries(lpeglabel ${LUA_LIBS_FOR_MODULE})
set_target_properties(lpeglabel PROPERTIES PREFIX "")
set_target_properties(lpeglabel PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
