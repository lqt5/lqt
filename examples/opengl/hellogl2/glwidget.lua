--[[*************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** self file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use self file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use self file under the terms of the BSD license
** as follows:
**
** 'Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, self list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, self list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from self software without specific prior written permission.
**
**
** self SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES LOSS OF USE,
** DATA, OR PROFITS OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF self SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'
**
** $QT_END_LICENSE$
**
***************************************************************************]]
local QtCore = require 'qtcore'
local QtGui = require 'qtgui'
local QtWidgets = require 'qtwidgets'
local QtOpengl = require 'qtopengl'

local Logo = require 'logo'

local Class = QtWidgets.QOpenGLWidget()

local function sizeof(t)
    if t == QtOpengl.GL_FLOAT then
        return 4
    end
    error('unknown sizeof type : ' .. tostring(t))
end

function Class:__static_init()
    self.m_transparent = false
    self:__addslot('setXRotation(int)', self.setXRotation)
    self:__addslot('setYRotation(int)', self.setYRotation)
    self:__addslot('setZRotation(int)', self.setZRotation)
    self:__addslot('cleanup()', self.cleanup)

    self:__addsignal('xRotationChanged(int)')
    self:__addsignal('yRotationChanged(int)')
    self:__addsignal('zRotationChanged(int)')
end

function Class.isTransparent()
    return Class.m_transparent
end

function Class.setTransparent(t)
    Class.m_transparent = t
end

function Class:minimumSizeHint()
    return QtCore.QSize(50, 50)
end

function Class:sizeHint()
    return QtCore.QSize(400, 400)
end

function Class:__init()
    self.m_xRot = 0
    self.m_yRot = 0
    self.m_zRot = 0

    self.m_core = QtGui.QSurfaceFormat.defaultFormat():profile() == 'CoreProfile'
    -- transparent causes the clear color to be transparent. Therefore, on systems that
    -- support it, the widget will become transparent apart from the logo.
    if self.m_transparent then
        local fmt = self:format()
        fmt:setAlphaBufferSize(8)
        self:setFormat(fmt)
    end

    self.m_lastPos = QtCore.QPoint()
    self.m_logo = Logo()
    self.m_vao = QtGui.QOpenGLVertexArrayObject()
    self.m_logoVbo = QtGui.QOpenGLBuffer.new()
    self.m_program = false
    self.m_projMatrixLoc = 0
    self.m_mvMatrixLoc = 0
    self.m_normalMatrixLoc = 0
    self.m_lightPosLoc = 0
    self.m_proj = QtGui.QMatrix4x4()
    self.m_camera = QtGui.QMatrix4x4()
    self.m_world = QtGui.QMatrix4x4()
end

function Class:__uninit()
    self:cleanup()
    self.m_logoVbo:delete()
end

local function qNormalizeAngle(angle)
    while angle < 0 do
        angle = angle + (360 * 16)
    end
    while angle > (360 * 16) do
        angle = angle - (360 * 16)
    end
    return angle
end

function Class:setXRotation(angle)
    local angle = qNormalizeAngle(angle)
    if angle ~= self.m_xRot then
        self.m_xRot = angle
        self:__emit('xRotationChanged', { 'int', angle })
        self:update()
    end
end

function Class:setYRotation(angle)
    local angle = qNormalizeAngle(angle)
    if angle ~= self.m_yRot then
        self.m_yRot = angle
        self:__emit('yRotationChanged', { 'int', angle })
        self:update()
    end
end

function Class:setZRotation(angle)
    local angle = qNormalizeAngle(angle)
    if angle ~= self.m_zRot then
        self.m_zRot = angle
        self:__emit('zRotationChanged', { 'int', angle })
        self:update()
    end
end

function Class:cleanup()
    if not self.m_program then
        return
    end
    self:makeCurrent()
    self.m_logoVbo:destroy()
    self.m_program:delete()
    self.m_program = false
    self:doneCurrent()
end

local vertexShaderSourceCore = [[#version 150
in vec4 vertex;
in vec3 normal;
out vec3 vert;
out vec3 vertNormal;
uniform mat4 projMatrix;
uniform mat4 mvMatrix;
uniform mat3 normalMatrix;
void main() {
   vert = vertex.xyz;
   vertNormal = normalMatrix * normal;
   gl_Position = projMatrix * mvMatrix * vertex;
}
]]

local fragmentShaderSourceCore = [[#version 150
in highp vec3 vert;
in highp vec3 vertNormal;
out highp vec4 fragColor;
uniform highp vec3 lightPos;
void main() {
   highp vec3 L = normalize(lightPos - vert);
   highp float NL = max(dot(normalize(vertNormal), L), 0.0);
   highp vec3 color = vec3(0.39, 1.0, 0.0);
   highp vec3 col = clamp(color * 0.2 + color * 0.8 * NL, 0.0, 1.0);
   fragColor = vec4(col, 1.0);
}
]]

local vertexShaderSource = [[attribute vec4 vertex;
attribute vec3 normal;
varying vec3 vert;
varying vec3 vertNormal;
uniform mat4 projMatrix;
uniform mat4 mvMatrix;
uniform mat3 normalMatrix;
void main() {
   vert = vertex.xyz;
   vertNormal = normalMatrix * normal;
   gl_Position = projMatrix * mvMatrix * vertex;
}
]]

local fragmentShaderSource = [[varying highp vec3 vert;
varying highp vec3 vertNormal;
uniform highp vec3 lightPos;
void main() {
   highp vec3 L = normalize(lightPos - vert);
   highp float NL = max(dot(normalize(vertNormal), L), 0.0);
   highp vec3 color = vec3(0.39, 1.0, 0.0);
   highp vec3 col = clamp(color * 0.2 + color * 0.8 * NL, 0.0, 1.0);
   gl_FragColor = vec4(col, 1.0);
}
]]

function Class:initializeGL()
    -- In this example the widget's corresponding top-level window can change
    -- several times during the widget's lifetime. Whenever this happens, the
    -- QOpenGLWidget's associated context is destroyed and a new one is created.
    -- Therefore we have to be prepared to clean up the resources on the
    -- aboutToBeDestroyed() signal, instead of the destructor. The emission of
    -- the signal will be followed by an invocation of initializeGL() where we
    -- can recreate all resources.
    self.connect(self:context(), SIGNAL 'aboutToBeDestroyed()', self, SLOT 'cleanup()')

    self.ogl = QtGui.QOpenGLFunctions()
    self.ogl:initializeOpenGLFunctions()

    self.ogl:glClearColor(0, 0, 0, self.m_transparent and 0 or 1)

    self.m_program = QtGui.QOpenGLShaderProgram.new()
    self.m_program:addShaderFromSourceCode(QtGui.QOpenGLShader.Vertex
        , self.m_core and vertexShaderSourceCore or vertexShaderSource
    )
    self.m_program:addShaderFromSourceCode(QtGui.QOpenGLShader.Fragment
        , self.m_core and fragmentShaderSourceCore or fragmentShaderSource
    )
    self.m_program:bindAttributeLocation('vertex', 0)
    self.m_program:bindAttributeLocation('normal', 1)
    self.m_program:link()

    self.m_program:bind()
    self.m_projMatrixLoc = self.m_program:uniformLocation('projMatrix')
    self.m_mvMatrixLoc = self.m_program:uniformLocation('mvMatrix')
    self.m_normalMatrixLoc = self.m_program:uniformLocation('normalMatrix')
    self.m_lightPosLoc = self.m_program:uniformLocation('lightPos')

    -- Create a vertex array object. In OpenGL ES 2.0 and OpenGL 2.x
    -- implementations this is optional and support may not be present
    -- at all. Nonetheless the below code works in all cases and makes
    -- sure there is a VAO when one is needed.
    self.m_vao:create()
    local vaoBinder = QtGui.QOpenGLVertexArrayObject_LQT_Binder(self.m_vao)

    -- Setup our vertex buffer object.
    self.m_logoVbo:create()
    self.m_logoVbo:bind()
    self.m_logoVbo:allocate(self.m_logo:constData(), self.m_logo:count() * sizeof(QtOpengl.GL_FLOAT))

    -- Store the vertex attribute bindings for the program.
    self:setupVertexAttribs()

    -- Our camera never changes in this example.
    self.m_camera:setToIdentity()
    self.m_camera:translate(0, 0, -1)

    -- Light position is fixed.
    self.m_program:setUniformValue(self.m_lightPosLoc, QtGui.QVector3D(0, 0, 70))

    self.m_program:release()

    vaoBinder:release()
end

function Class:paintGL()
    self.ogl:glClear(QtOpengl.GL_COLOR_BUFFER_BIT + QtOpengl.GL_DEPTH_BUFFER_BIT)
    self.ogl:glEnable(QtOpengl.GL_DEPTH_TEST)
    self.ogl:glEnable(QtOpengl.GL_CULL_FACE)

    self.m_world:setToIdentity()
    self.m_world:rotate(180.0 - (self.m_xRot / 16.0), 1, 0, 0)
    self.m_world:rotate(self.m_yRot / 16.0, 0, 1, 0)
    self.m_world:rotate(self.m_zRot / 16.0, 0, 0, 1)

    local vaoBinder = QtGui.QOpenGLVertexArrayObject_LQT_Binder(self.m_vao)
    self.m_program:bind()
    self.m_program:setUniformValue(self.m_projMatrixLoc, self.m_proj)
    self.m_program:setUniformValue(self.m_mvMatrixLoc, QtGui.MUL(self.m_camera, self.m_world))
    local normalMatrix = QtGui.QMatrix3x3(self.m_world:normalMatrix())
    self.m_program:setUniformValue(self.m_normalMatrixLoc, normalMatrix)

    self.ogl:glDrawArrays(QtOpengl.GL_TRIANGLES, 0, self.m_logo:vertexCount())

    self.m_program:release()
    vaoBinder:release()
end

function Class:resizeGL(width, height)
    self.m_proj:setToIdentity()
    self.m_proj:perspective(45.0, width / height, 0.01, 100.0)
end

function Class:mousePressEvent(event)
    self.m_lastPos = event:pos()
end

function Class:mouseMoveEvent(event)
    local dx = event:x() - self.m_lastPos:x()
    local dy = event:y() - self.m_lastPos:y()

    local buttons = event:buttons()
    if buttons.LeftButton then
        self:setXRotation(self.m_xRot + 8 * dy)
        self:setYRotation(self.m_yRot + 8 * dx)
    elseif buttons.RightButton then
        self:setXRotation(self.m_xRot + 8 * dy)
        self:setZRotation(self.m_zRot + 8 * dx)
    end
    self.m_lastPos = event:pos()
end

function Class:setupVertexAttribs()
    local ffi = require 'ffi'

    self.m_logoVbo:bind()
    local f = QtGui.QOpenGLContext.currentContext():functions()
    f:glEnableVertexAttribArray(0)
    f:glEnableVertexAttribArray(1)
    f:glVertexAttribPointer(0
        , 3
        , QtOpengl.GL_FLOAT
        , QtOpengl.GL_FALSE
        , 6 * sizeof(QtOpengl.GL_FLOAT)
        , nil
    )
    f:glVertexAttribPointer(1
        , 3
        , QtOpengl.GL_FLOAT
        , QtOpengl.GL_FALSE
        , 6 * sizeof(QtOpengl.GL_FLOAT)
        , ffi.cast('const void *', 3 * sizeof(QtOpengl.GL_FLOAT))
    )
    self.m_logoVbo:release()
end

return Class:class()
