#  Copyright (c) 2008 Peter Kuemmel 
#  
#  Permission is hereby granted, free of charge, to any person
#  obtaining a copy of this software and associated documentation
#  files (the "Software"), to deal in the Software without
#  restriction, including without limitation the rights to use,
#  copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following
#  conditions:
#  
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#  OTHER DEALINGS IN THE SOFTWARE.
cmake_minimum_required(VERSION 2.6)

project(cpptoxml)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY  ${CMAKE_BINARY_DIR}/bin) 

find_package(Qt4 REQUIRED)
set(QT_USE_QTCORE 1) 
include(${QT_USE_FILE})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/. 
					${CMAKE_CURRENT_SOURCE_DIR}/parser
					${CMAKE_CURRENT_SOURCE_DIR}/parser/rpp)
					
add_definitions(-DRXX_ALLOCATOR_INIT_0)

file(GLOB parser_src ${CMAKE_CURRENT_SOURCE_DIR}/parser/*.cpp) 

add_executable(cpptoxml ${parser_src}
						${CMAKE_CURRENT_SOURCE_DIR}/main.cpp 
						${CMAKE_CURRENT_SOURCE_DIR}/parser/rpp/preprocessor.cpp)

target_link_libraries(cpptoxml ${QT_LIBRARIES} ${QT_QTMAIN_LIBRARY})


