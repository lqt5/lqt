set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(lpeglabel)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../depends/lpeglabel
)

set(lpeglabel_src
	../../depends/lpeglabel/lpcap.c
	../../depends/lpeglabel/lpcap.h
	../../depends/lpeglabel/lpcode.c
	../../depends/lpeglabel/lpcode.h
	../../depends/lpeglabel/lpprint.c
	../../depends/lpeglabel/lpprint.h
	../../depends/lpeglabel/lptree.c
	../../depends/lpeglabel/lptree.h
	../../depends/lpeglabel/lptypes.h
	../../depends/lpeglabel/lpvm.c
	../../depends/lpeglabel/lpvm.h
)

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(lpeglabel MODULE ${lpeglabel_src})

set_target_properties(lpeglabel PROPERTIES PREFIX "")
set_target_properties(lpeglabel PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
