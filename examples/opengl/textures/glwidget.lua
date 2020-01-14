--[[*************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
***************************************************************************]]
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'
local QtOpenGL = require 'qtopengl'

local PROGRAM_VERTEX_ATTRIBUTE = 0
local PROGRAM_TEXCOORD_ATTRIBUTE = 1

local Class = QtCore.Class('GLWidget', QtWidgets.QOpenGLWidget) {}

local function sizeof(t)
    if t == QtOpenGL.GL_FLOAT then
        return 4
    end
    error('unknown sizeof type : ' .. tostring(t))
end

function Class:__static_init()
    self:__addsignal('clicked()')
end

function Class:__init()
    self.clearColor = QtGui.QColor('black')
    self.lastPos = QtCore.QPoint()
    self.xRot = 0
    self.yRot = 0
    self.zRot = 0
    self.textures = {} -- [6]
    self.program = false
    self.vbo = QtGui.QOpenGLBuffer.new()
    self.gl = QtGui.QOpenGLFunctions()
end

function Class:__uninit()
    self:makeCurrent()
    self.vbo:destroy()
    for _,tex in ipairs(self.textures) do
        tex:delete()
    end
    self.program:delete()
    self:doneCurrent()
end

function Class:minimumSizeHint()
    return QtCore.QSize(50, 50)
end

function Class:sizeHint()
    return QtCore.QSize(200, 200)
end

function Class:rotateBy(xAngle, yAngle, zAngle)
    self.xRot = self.xRot + xAngle
    self.yRot = self.yRot + yAngle
    self.zRot = self.zRot + zAngle
    self:update()
end

function Class:setClearColor(color)
    self.clearColor = color
    self:update()
end

function Class:initializeGL()
    self.gl:initializeOpenGLFunctions()

    self:makeObject()

    self.gl:glEnable(QtOpenGL.GL_DEPTH_TEST)
    self.gl:glEnable(QtOpenGL.GL_CULL_FACE)

    local vshader = QtGui.QOpenGLShader.new(QtGui.QOpenGLShader.Vertex, self)
    local vsrc = [[attribute highp vec4 vertex;
    attribute mediump vec4 texCoord;
    varying mediump vec4 texc;
    uniform mediump mat4 matrix;
    void main(void)
    {
        gl_Position = matrix * vertex;
        texc = texCoord;
    }]]
    vshader:compileSourceCode(vsrc)

    local fshader = QtGui.QOpenGLShader.new(QtGui.QOpenGLShader.Fragment, self)
    local fsrc = [[uniform sampler2D texture;
    varying mediump vec4 texc;
    void main(void)
    {
        gl_FragColor = texture2D(texture, texc.st);
    }]]
    fshader:compileSourceCode(fsrc)

    self.program = QtGui.QOpenGLShaderProgram.new()
    self.program:addShader(vshader)
    self.program:addShader(fshader)

    self.program:bindAttributeLocation('vertex', PROGRAM_VERTEX_ATTRIBUTE)
    self.program:bindAttributeLocation('texCoord', PROGRAM_TEXCOORD_ATTRIBUTE)
    self.program:link()

    self.program:bind()
    self.program:setUniformValue('texture', 0)
end

function Class:paintGL()
    self.gl:glClearColor(self.clearColor:redF()
        , self.clearColor:greenF()
        , self.clearColor:blueF()
        , self.clearColor:alphaF()
    )
    self.gl:glClear(QtOpenGL.GL_COLOR_BUFFER_BIT + QtOpenGL.GL_DEPTH_BUFFER_BIT)

    local m = QtGui.QMatrix4x4()
    m:ortho(-0.5, 0.5, 0.5, -0.5, 4.0, 15.0)
    m:translate(0.0, 0.0, -10.0)
    m:rotate(self.xRot / 16.0, 1.0, 0.0, 0.0)
    m:rotate(self.yRot / 16.0, 0.0, 1.0, 0.0)
    m:rotate(self.zRot / 16.0, 0.0, 0.0, 1.0)

    self.program:setUniformValue('matrix', m)
    self.program:enableAttributeArray(PROGRAM_VERTEX_ATTRIBUTE)
    self.program:enableAttributeArray(PROGRAM_TEXCOORD_ATTRIBUTE)
    self.program:setAttributeBuffer(PROGRAM_VERTEX_ATTRIBUTE, QtOpenGL.GL_FLOAT, 0, 3, 5 * sizeof(QtOpenGL.GL_FLOAT))
    self.program:setAttributeBuffer(PROGRAM_TEXCOORD_ATTRIBUTE, QtOpenGL.GL_FLOAT, 3 * sizeof(QtOpenGL.GL_FLOAT), 2, 5 * sizeof(QtOpenGL.GL_FLOAT));

    for i,tex in ipairs(self.textures) do
        tex:bind()
        self.gl:glDrawArrays(QtOpenGL.GL_TRIANGLE_FAN, (i - 1) * 4, 4)
    end
end

function Class:resizeGL(width, height)
    local side = math.floor(math.min(width, height))
    self.gl:glViewport(math.floor((width - side) / 2), math.floor((height - side) / 2), side, side)
end

function Class:mousePressEvent(event)
    self.lastPos = event:pos()
end

function Class:mouseMoveEvent(event)
    local dx = event:x() - self.lastPos:x()
    local dy = event:y() - self.lastPos:y()

    if QtCore.testFlag(event:buttons(), 'LeftButton') then
        self:rotateBy(8 * dy, 8 * dx, 0);
    elseif QtCore.testFlag(event:buttons(), 'RightButton') then
        self:rotateBy(8 * dy, 0, 8 * dx);
    end

    self.lastPos = event:pos()
end

function Class:mouseReleaseEvent(event)
    self:__emit('clicked')
end

function Class:makeObject()
    local coords = {
        { {  1, -1, -1 }, { -1, -1, -1 }, { -1,  1, -1 }, {  1,  1, -1 } },
        { {  1,  1, -1 }, { -1,  1, -1 }, { -1,  1,  1 }, {  1,  1,  1 } },
        { {  1, -1,  1 }, {  1, -1, -1 }, {  1,  1, -1 }, {  1,  1,  1 } },
        { { -1, -1, -1 }, { -1, -1,  1 }, { -1,  1,  1 }, { -1,  1, -1 } },
        { {  1, -1,  1 }, { -1, -1,  1 }, { -1, -1, -1 }, {  1, -1, -1 } },
        { { -1, -1,  1 }, {  1, -1,  1 }, {  1,  1,  1 }, { -1,  1,  1 } },
    }

    for i = 1,6 do
        self.textures[i] = QtGui.QOpenGLTexture.new(
            QtGui.QImage(
                QtCore.QString('images/side%1.png'):arg(tostring(i))
            ):mirrored()
        )
    end

    local vertData = QtCore.QVector_float_()
    for i = 1,6 do
        for j = 1,4 do
            -- vertex position
            vertData:append(0.2 * coords[i][j][1])
            vertData:append(0.2 * coords[i][j][2])
            vertData:append(0.2 * coords[i][j][3])
            -- texture coordinate
            vertData:append((j == 1 or j == 4) and 1 or 0)
            vertData:append((j == 1 or j == 2) and 1 or 0)
        end
    end

    self.vbo:create()
    self.vbo:bind()
    self.vbo:allocate(vertData:constData(), vertData:count() * sizeof(QtOpenGL.GL_FLOAT))
end

return Class
