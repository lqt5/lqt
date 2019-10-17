Overview
========

lqt is a [Lua/luajit](http://www.lua.org) binding to the [Qt5 framework](https://www.qt.io/).
It is an automated binding generated from the modified version of [Qt headers](generator/schema), and covers almost
all classes and methods from supported Qt modules.

For more info, check the documentation, [mailing list](http://groups.google.com/group/lqt-bindings) or contact the authors:

 * Michal Kottman michal.kottman@gmail.com
 * Mauro Iazzi mauro.iazzi@gmail.com
 * Peter Kümmel syntheticpp@gmx.net
 * Saniko 116453813@qq.com

Features
--------

* automatically generated from modified version of Qt headers
* supported modules:
  * QtCore
  * QtNetwork
  * QtSql
  * QtPositioning
  * QtScript
  * QtQml
  * QtWebChannel
  * QtGui
  * QtWidgets
  * QtOpenGL
  * QtPrintSupport
  * QtUiTools
  * QtQuick
  * QtQuickWidgets
  * QtWebEngineCore
  * QtWebEngineWidgets
  * QtTest

* high API coverage - only a minimum of methods are not available
* C++/Qt features available:
  * method overloads
  * virtual methods (including abstract methods)
  * multiple inheritance
  * you can store additional Lua values in userdata - they act like Lua tables
  * several overloaded operators are supported
  * chosen templated classes are available, like `QList<QString>`
  * signal/slot mechanism - you can define custom slots in Lua
  * `QObject` derived objects are automatically cast to correct type thanks to Qt metaobject system
  * implicit conversion - i.e. write Lua strings where QString is expected, or numbers instead of QVariant
  * Qt `signal/slot` feature works well [test](test/test_signal.lua)
  * Also Qt `properties` are supported [test](test/test_property.lua)
* optional memory management - you can let the Lua GC destroy objects, or let Qt parent/child management do the work
* embed lua qt class system
  * `Class`  inherit from Qt C++ class [test](test/test_class.lua)
  * `isInstanceOf` check instance of a class [test](test/test_inherit.lua)
* lots of Qt offical examples lua version: [examples](examples)

History
-------

## lqt 0.9

* Public beta, most issues and API stabilized

Building lqt
------------

To compile lqt, you need:

* [CMake](http://www.cmake.org/cmake/resources/software.html)
* Qt `5.12.0` or above, download from [Qt offical site](https://www.qt.io/download)
* Compilers
    * On Windows: use `Microsoft Visual Studio 2017` or later version
    * On MacOS: use `XCode 11.0` or later version

You can get the latest source of lqt from https://github.com/lqt5/lqt .
When you have the sources.

# On Windows platform
Checkout sub module repos:
```bat
git submodule update --init --recursive --remote
```

Compile/install LuaJIT(required `msvc x64 command line environ`):
```bat
cd modules\src\LuaJIT\src
call msvcbuild.bat
```

Edit CMakeList.txt, change this line to your Qt install folder:
```cmake
    set(CMAKE_PREFIX_PATH D:/Qt/Qt5.13.0/5.13.0/msvc2017_64/lib/cmake)
```

Create an out-of-source build directory
(where the binaries will be built, I often use `build`):

```bat
md build
```

Then, use CMake to generate the msvc solution and run `cmake build`:
```bat
cmake -G "Visual Studio 15 2017 Win64" -H. -Bbuild
cmake --build build --target ALL_BUILD --config RelWithDebinfo -j4
```

# On MacOS platform
Checkout sub module repos:
```sh
git submodule update --init --recursive --remote
```

Compile/install LuaJIT:
```sh
cd modules/src/LuaJIT
sudo make install
```

Edit CMakeList.txt, change this line to your Qt install folder:
```cmake
    set(CMAKE_PREFIX_PATH ~/Qt/5.13.0/clang_64/lib/cmake/)
```

Then, use CMake to generate the Makefile and run `make` as usual:
```sh
    mkdir build; cd build
    cmake ..
    make -j4 # use parallel build with your number of cores/processors
```

Finish
------

The generated Lua binding libraries are created in the `lib` directory,
you can copy them to your `LUA_CPATH`.

Usage
-----

A quick example of "Hello World!" button with signal/slot handling:

```lua
    local QtCore = require 'qtcore'
    local QtGui = require 'qtgui'
    local QtWidgets = require 'qtwidgets'

    local app = QtWidgets.QApplication.new(select('#',...) + 1, {'lua', ...})

    local btn = QtWidgets.QPushButton.new("Hello World!")
    btn:connect('2pressed()', function(self)
        print("I'm about to close...")
        self:close()
    end)
    btn:setWindowTitle("A great example!")
    btn:resize(300,50)
    btn:show()

    app.exec()
```

For more examples, check out the `test` or `examples` folder and the `doc`
folder for documentation on detailed usage - memory management,
signal/slot handling, virtual method overloading, etc. Also, have
a look at the [examples](https://github.com/mkottman/lqt/wiki/Examples)
and feel free to add your own!

License
-------

* Copyright (c) 2007-2009 Mauro Iazzi
* Copyright (c) 2008-2009 Peter Kümmel
* Copyright (c) 2010-2011 Michal Kottman
* Copyright (c) 2019-2019 Saniko

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
