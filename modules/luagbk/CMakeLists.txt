set(CMAKE_LEGACY_CYGWIN_WIN32 0)
cmake_minimum_required(VERSION 2.6)
project(luagbk)

set(CMAKE_MACOSX_RPATH 1)

include_directories(${LUA_INCLUDE_DIRS}
	../../modules/src/luagbk
)

set(gbk_src
	../../modules/src/luagbk/ldbcs.h
	../../modules/src/luagbk/gbk.h
	../../modules/src/luagbk/lgbk.c
)

set(jis_src
	../../modules/src/luagbk/ldbcs.h
	../../modules/src/luagbk/jis.h
	../../modules/src/luagbk/ljis.c
)

set(pinyin_src
	../../modules/src/luagbk/pinyin.h
	../../modules/src/luagbk/lpinyin.c
)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUAMOD_API=LUALIB_API")

if (WIN32)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_BUILD_AS_DLL -fno-strict-aliasing")
endif()

link_directories(${LUA_LIBS_FOR_MODULE})

add_library(gbk MODULE ${gbk_src})

target_link_libraries(gbk ${LUA_LIBS_FOR_MODULE})
set_target_properties(gbk PROPERTIES PREFIX "")
set_target_properties(gbk PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)

add_library(jis MODULE ${jis_src})

target_link_libraries(jis ${LUA_LIBS_FOR_MODULE})
set_target_properties(jis PROPERTIES PREFIX "")
set_target_properties(jis PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)

add_library(pinyin MODULE ${pinyin_src})

target_link_libraries(pinyin ${LUA_LIBS_FOR_MODULE})
set_target_properties(pinyin PROPERTIES PREFIX "")
set_target_properties(pinyin PROPERTIES INSTALL_RPATH_USE_LINK_PATH TRUE)
