// Copyright (C) 2013 Trevor McCauley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
// copies of the Software, and to permit persons to whom the Software is 
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
// SOFTWARE.

function TransformTool(container){
	this.container = container;
	this.target = null;
	
	// transform interaction
	// where interaction starts
	this.startMatrix = new Matrix();
	this.regStartU = 0.5;
	this.regStartV = 0.5;
	this.startX = 0;
	this.startY = 0;
	
	// trnasforms to apply
	this.preMatrix = new Matrix();
	this.postMatrix = new Matrix();
	
	// where interaction ends
	this.endMatrix = new Matrix();
	this.regEndU = 0.5;
	this.regEndV = 0.5;
	this.endX = 0;
	this.endY = 0;
	
	// transform UV delta
	this.dU = 0;
	this.dV = 0;
	
	// registration point in px
	this.regX = 0;
	this.regY = 0;
	
	// inverted matrices
	this.inv = new Matrix();
	
	// transform controls
	this.control = null;
	this.controls = [];
	
	// style guide for controls
	this.fillStyle = "#FFF";
	this.strokeStyle = "#08F";
	this.lineWidth = 2;
}

TransformTool.prototype.setTarget = function(target){
	if (this.target === target){
		return;
	}
	
	this.target = target;
	this.updateFromTarget();
}

TransformTool.prototype.updateFromTarget = function(){
	if (this.target && this.target.matrix){
		this.endMatrix.copyFrom(this.target.matrix);
		this.commit();
		this.updateRegistration();
		this.updateControls();
	}
};

TransformTool.prototype.setControls = function(controls){
	this.controls.length = 0;
	if (!controls || !controls.length){
		return;
	}
	var i = 0;
	var n = controls.length;
	for (i=0; i<n; i++){
		controls[i].tool = this;
		this.controls[i] = controls[i];
		this.controls[i].updatePosition();
	}
};

TransformTool.prototype.updateControls = function(){
	var i = 0;
	var n = this.controls.length;
	for (i=0; i<n; i++){
		this.controls[i].updatePosition();
	}
};

TransformTool.prototype.getControlAt = function(x, y){
	// walking in reverse order to find those 
	// drawn on top (later in list) first
	var i = this.controls.length;
	while(i--){
		if (this.controls[i].contains(x, y)){
			return this.controls[i];
		}
	}
	
	// control not found
	return null;
};

TransformTool.prototype.draw = function(){
	if (!this.shouldDraw()){
		return;
	}
	
	var i = 0;
	var n = this.controls.length;
	for (i=0; i<n; i++){
		this.controls[i].draw(this.container);
	}
};

TransformTool.prototype.shouldDraw = function(){
	return this.target != null;
};

TransformTool.prototype.start = function(x, y, control){
	if (!this.target){
		return false;
	}
	
	// commits and gives default state
	this.end();
	
	this.control = control || this.getControlAt(x, y);
	if (this.control){
		
		this.startX = x;
		this.startY = y;
		this.dU = 0;
		this.dV = 0;
		
		if (this.control.dynamicUV){
			// update the control point location
			// to match the mouse location at start
			var cx = x - this.startMatrix.x;
			var cy = y - this.startMatrix.y;
			this.control.u = (this.inv.a * cx + this.inv.c * cy)/this.target.width;
			this.control.v = (this.inv.d * cy + this.inv.b * cx)/this.target.height;
		}
		
		this.updateRegistration();
		
		return true;
	}
	
	return false;
};

TransformTool.prototype.move = function(x, y){
	this.updateMoveValues(x, y);
	
	if (this.control){
		this.applyControl();
		this.updateTransform();
		
		this.updateTarget();
		this.updateRegistration();
		this.updateControls();
	}
};

TransformTool.prototype.end = function(){
	this.commit();
	this.control = null;
};

TransformTool.prototype.updateMoveValues = function(x, y){
	this.endX = x;
	this.endY = y;
	
	var cx = this.endX - this.startX;
	var cy = this.endY - this.startY;
	
	// inline transformPoint to target local space
	this.dU = (this.inv.a * cx + this.inv.c * cy) / this.target.width;
	this.dV = (this.inv.d * cy + this.inv.b * cx) / this.target.height;
};

TransformTool.prototype.applyControl = function(){
	if (this.control){
		
		// for custom drawing methods, call
		// that method and skip standard drawing
		// if it returns false
		if (this.control.transformCallback !== null){
			if (!this.control.transformCallback(this.control)){
				return;
			}
		}
		
		// variables for working with position and size
		var x = 0;
		var y = 0;
		var w = this.target.width;
		var h = this.target.height;
		
		// difference between registration and control points
		var cu = this.control.u - this.regStartU;
		var cv = this.control.v - this.regStartV;
		
		// if the abs px difference is less than 0, normalize to
		// 1 (or -1) to prevent outrageous divisions by 0 or a
		// very small number resulting in oversized transforms
		if (cu > 0){
			if (cu*w < 1){
				cu = 1/w;
			}
		}else if (cu*w > -1){
			cu = -1/w;
		}
		
		if (cv > 0){
			if (cv*h < 1){
				cv = 1/h;
			}
		}else if (cv*h > -1){
			cv = -1/h;
		}
		
		// perform transform based on control type
		switch(this.control.type){
			
			case Control.SCALE:{
				x = (cu + this.dU)/cu;
				y = (cv + this.dV)/cv;
				this.preMatrix.scale(x, y);
				break;
			}
			
			case Control.SCALE_X:{
				x = (cu + this.dU)/cu;
				this.preMatrix.scale(x, 1);
				break;
			}
			
			case Control.SCALE_Y:{
				y = (cv + this.dV)/cv;
				this.preMatrix.scale(1, y);
				break;
			}
			
			case Control.SCALE_UNIFORM:{
				x = (cu + this.dU)/cu;
				y = (cv + this.dV)/cv;
				
				// find the ratio to make the scaling
				// uniform in both the x (w) and y (h) axes
				w = y ? Math.abs(x/y) : 0;
				h = x ? Math.abs(y/x) : 0;
				
				// for 0 scale, scale both axises to 0
				if (w === 0 || h === 0){
					x = 0;
					y = 0;
					
				// scale mased on the smaller ratio
				}else if (w > h){
					x *= h;
				}else{
					y *= w;
				}
				
				this.preMatrix.scale(x, y);
				break;
			}
			
			case Control.SKEW_X:{
				this.preMatrix.c = (w/h) * (this.dU/cv);
				break;
			}
			
			case Control.SKEW_Y:{
				this.preMatrix.b = (h/w) * (this.dV/cu);
				break;
			}
			
			case Control.ROTATE_SCALE:{
				// rotation in global space
				x = this.startX - this.regX;
				y = this.startY - this.regY;
				var ex = this.endX - this.regX;
				var ey = this.endY - this.regY;
				
				var angle = Math.atan2(ey, ex) - Math.atan2(y, x);
				this.postMatrix.rotate(angle);
				
				// determine scale factor from change
				// this is also done in global space
				// in matching with the rotation
				var s = Math.sqrt(x*x + y*y);
				if (s === 0){
					this.preMatrix.scale(0, 0);
				}else{
					s = Math.sqrt(ex*ex + ey*ey)/s;
					this.preMatrix.scale(s, s);
				}
				
				break;
			}
			
			case Control.ROTATE:{
				// rotation in global space
				x = Math.atan2(this.startY - this.regY, this.startX - this.regX);
				y = Math.atan2(this.endY - this.regY, this.endX - this.regX);
				this.postMatrix.rotate(y - x);
				break;
			}
			
			case Control.TRANSLATE:{
				// translate in global space
				this.postMatrix.translate(this.endX - this.startX, this.endY - this.startY);
				break;
			}
			
			case Control.REGISTRATION:{
				this.regEndU = this.regStartU + this.dU;
				this.regEndV = this.regStartV + this.dV;
				// reg UV isn't set until end()
				break;
			}
		}
	}
};

TransformTool.prototype.updateRegistration = function(){
	var x = this.regEndU * this.target.width;
	var y = this.regEndV * this.target.height;
	var m = this.endMatrix;
	this.regX = m.x + m.a * x + m.c * y;
	this.regY = m.y + m.d * y + m.b * x;
};

TransformTool.prototype.updateTransform = function(){
	
	// apply transforms (pre, post)
	this.endMatrix.identity();
	this.endMatrix.concat(this.preMatrix);
	this.endMatrix.concat(this.startMatrix);
	
	// next, the post transform is concatenated on top
	// of the previous result, but for the post transform,
	// translation (x,y) values are not transformed. They're
	// saved with the respective post transform offset, then 
	// reassigned after concatenating the post transformation
	var x = this.endMatrix.x + this.postMatrix.x;
	var y = this.endMatrix.y + this.postMatrix.y;
	
	// finally, concatenate post transform on to final
	this.endMatrix.concat(this.postMatrix);
	
	// reassign saved tx and ty values with the 
	// included registration offset
	this.endMatrix.x = x;
	this.endMatrix.y = y;
	
	// shift for registration not being in (0,0)
	this.applyRegistrationOffset();
	
	// reset transforms
	this.preMatrix.identity();
	this.postMatrix.identity();
};

TransformTool.prototype.applyRegistrationOffset = function(){
	
	if (this.regEndU !== 0 || this.regEndV !== 0){
		// registration offset
		// local registration location
		var x = this.regEndU * this.target.width;
		var y = this.regEndV * this.target.height;
		// delta tansform by start matrix
		var rx = this.startMatrix.a * x + this.startMatrix.c * y;
		var ry = this.startMatrix.d * y + this.startMatrix.b * x;
		// subtract delta transform end matrix
		rx -= this.endMatrix.a * x + this.endMatrix.c * y;
		ry -= this.endMatrix.d * y + this.endMatrix.b * x;
		// shift by remaining
		this.endMatrix.translate(rx, ry);
	}
};

TransformTool.prototype.updateTarget = function(){
	if (this.target && this.target.matrix && !this.target.matrix.equals(this.endMatrix)){
		this.target.matrix.copyFrom(this.endMatrix);
		if (this.target.changed !== null){
			this.target.changed();
		}
	}
};

TransformTool.prototype.commit = function(){
	// registration
	this.regStartU = this.regEndU;
	this.regStartV = this.regEndV;
	
	// transform
	this.startMatrix.copyFrom(this.endMatrix);
	this.sanitizeStartMatrix(); // prevent by-0 errors
	
	// update inversion matrix
	this.inv.copyFrom(this.startMatrix);
	this.inv.invert();
};

TransformTool.prototype.sanitizeStartMatrix = function(){
	if (!this.target){
		return;
	}
	
	if (this.startMatrix.a === 0 && this.startMatrix.b === 0){
		this.startMatrix.a = 1/this.target.width;
	}
	
	if (this.startMatrix.d === 0 && this.startMatrix.c === 0){
		this.startMatrix.d = 1/this.target.height;
	}
};

/**
 * Interface for Transform targets.
 */
function Transformable(width, height, matrix, owner){
	this.width = width || 0; // Number
	this.height = height || 0; // Number
	this.matrix = matrix || new Matrix(1,0,0,1,0,0); // Matrix
	this.owner = owner; // *
	this.changed = null; // Function
}

function Control(type, u, v, offsetX, offsetY, size){
	this.tool = null;
	this.type = type;
	
	this.x = 0;
	this.y = 0;
	
	this.offsetX = offsetX || 0;
	this.offsetY = offsetY || 0;
	
	this.hitTestTarget = false;
	this.size = size || 15;
	this.shape = null;
	this.setDefaultShape();
	
	this.u = u;
	this.v = v;
	this.dynamicUV = false;
	
	this.drawCallback = null;
	this.transformCallback = null;
}

Control.SCALE = 1;
Control.SCALE_X = 2;
Control.SCALE_Y = 3;
Control.SCALE_UNIFORM = 4;
Control.ROTATE = 5;
Control.TRANSLATE = 6;
Control.REGISTRATION = 7;
Control.SKEW_X = 8;
Control.SKEW_Y = 9;
Control.BORDER = 10;
Control.TARGET = 11;
Control.ROTATE_SCALE = 12;

Control.SHAPE_CIRCLE = 1;
Control.SHAPE_SQUARE = 2;

Control.prototype.setDefaultShape = function(){
	
	switch(this.type){
		
		case Control.ROTATE:
		case Control.ROTATE_SCALE:
		case Control.REGISTRATION:{
			this.shape = Control.SHAPE_CIRCLE;
			break;
		}
		
		case Control.SCALE:
		case Control.SCALE_UNIFORM:
		case Control.SCALE_X:
		case Control.SCALE_Y:
		case Control.SKEW_X:
		case Control.SKEW_Y:{
			this.shape = Control.SHAPE_SQUARE;
			break;
		}
		case Control.BORDER:{
			this.shape = Control.SHAPE_BORDER;
			break;
		}
	}
};

Control.prototype.updatePosition = function(){
	if (!this.tool || !this.tool.target){
		return;
	}
	
	if (this.type === Control.REGISTRATION){
		this.x = this.tool.regX;
		this.y = this.tool.regY;
		return;
	}
	
	var m = this.tool.endMatrix;
	
	// matrix transform for UV
	var w = this.tool.target.width * this.u;
	var h = this.tool.target.height * this.v;
	this.x = m.x + m.a * w + m.c * h;
	this.y = m.y + m.d * h + m.b * w;
	
	// offset
	var angle = 0;
	if (this.offsetX){
		angle = m.getRotationX();
		this.x += this.offsetX * Math.cos(angle);
		this.y += this.offsetX * Math.sin(angle);
	}
	if (this.offsetY){
		angle = m.getRotationY();
		this.x += this.offsetY * Math.sin(angle);
		this.y += this.offsetY * Math.cos(angle);
	}
};

Control.prototype.draw = function(ctx){
	
	// for custom drawing methods, call
	// that method and skip standard drawing
	// if it returns false
	if (this.drawCallback !== null){
		if (!this.drawCallback(this, ctx)){
			return;
		}
	}
	
	// do not draw for non-positive sizes
	if (this.size <= 0){
		return;
	}
	
	var x = 0;
	var y = 0;
	
	ctx.save();
	ctx.beginPath();
	
	ctx.fillStyle = this.tool.fillStyle;
	ctx.strokeStyle = this.tool.strokeStyle;
	ctx.lineWidth = this.tool.lineWidth;
	
	switch(this.shape){
		
		case Control.SHAPE_CIRCLE:{
			ctx.arc(this.x,this.y,this.size/2,0,Math.PI*2);
			ctx.fill();
			ctx.stroke();
			break;
		}
		
		case Control.SHAPE_SQUARE:{
			x = (this.x - this.size/2)|0;
			y = (this.y - this.size/2)|0;
			ctx.fillRect(x, y, this.size, this.size);
			ctx.strokeRect(x, y, this.size, this.size);
			break;
		}
		
		case Control.SHAPE_BORDER:{
			// render to half pixel for hard lines
			ctx.fillStyle = "";
			var t = this.tool.target;
			var m = this.tool.endMatrix;
			
			ctx.moveTo(m.x, m.y);
			x = m.x + m.a * t.width;
			y = m.y + m.b * t.width;
			ctx.lineTo(x, y);
			x = m.x + m.a * t.width + m.c * t.height;
			y = m.y + m.d * t.height + m.b * t.width;
			ctx.lineTo(x, y);
			x = m.x + m.c * t.height;
			y = m.y + m.d * t.height;
			ctx.lineTo(x, y);
			ctx.lineTo(m.x, m.y);
			ctx.stroke();
			break;
		}
		
		default:{
			// no draw
			break;
		}
	}
	
	ctx.restore();
};

Control.prototype.contains = function(x, y){
	if (this.hitTestTarget){
		var t = this.tool.target;
		return t.matrix.containsPoint(x, y, t.width, t.height);
		
	}else{
		
		var cx = Math.abs(this.x - x);
		var cy = Math.abs(this.y - y);
		var sr = this.size/2;
		if (cx < sr && cy < sr){
			return true;
		}
	}
	
	return false;
};

var ControlSet = {};
ControlSet.controlClass = Control;
ControlSet.getStandard = function(){
	var translater = new this.controlClass(Control.TRANSLATE);
	translater.hitTestTarget = true;
	
	return [
		new this.controlClass(Control.BORDER),
		translater,
		new this.controlClass(Control.ROTATE, 0,0, 0,0, 10),
		new this.controlClass(Control.ROTATE, 0,1, 0,0, 10),
		new this.controlClass(Control.ROTATE, 1,0, 0,0, 10),
		new this.controlClass(Control.ROTATE, 1,1, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 0,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 1,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,0, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,1, 0,0, 10)
	];	
};

ControlSet.getScaler = function(){
	var translater = new this.controlClass(Control.TRANSLATE);
	translater.hitTestTarget = true;
	
	return [
		new this.controlClass(Control.BORDER),
		translater,
		new this.controlClass(Control.SCALE, 0,0, 0,0, 10),
		new this.controlClass(Control.SCALE, 0,1, 0,0, 10),
		new this.controlClass(Control.SCALE, 1,0, 0,0, 10),
		new this.controlClass(Control.SCALE, 1,1, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 0,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 1,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,0, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,1, 0,0, 10)
	];	
};

ControlSet.getUniformScaler = function(){
	var translater = new this.controlClass(Control.TRANSLATE);
	translater.hitTestTarget = true;
	
	return [
		new this.controlClass(Control.BORDER),
		translater,
		new this.controlClass(Control.SCALE_UNIFORM, 0,0, 0,0, 10),
		new this.controlClass(Control.SCALE_UNIFORM, 0,1, 0,0, 10),
		new this.controlClass(Control.SCALE_UNIFORM, 1,0, 0,0, 10),
		new this.controlClass(Control.SCALE_UNIFORM, 1,1, 0,0, 10)
	];	
};


ControlSet.getScalerWithRotate = function(){
	var translater = new this.controlClass(Control.TRANSLATE, 0, 0, 0, 0, -1);
	// translate control is "selected" by clicking
	// on the target's shape, not the control point
	translater.hitTestTarget = true;
	
	return [
		new this.controlClass(Control.BORDER),
		translater,
		new this.controlClass(Control.ROTATE, .5,0, 0,-20, 10),
		new this.controlClass(Control.SCALE, 0,0, 0,0, 10),
		new this.controlClass(Control.SCALE, 0,1, 0,0, 10),
		new this.controlClass(Control.SCALE, 1,0, 0,0, 10),
		new this.controlClass(Control.SCALE, 1,1, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 0,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_X, 1,.5, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,0, 0,0, 10),
		new this.controlClass(Control.SCALE_Y, .5,1, 0,0, 10)
	];	
};

ControlSet.getDynamic = function(){
	var dyn = new this.controlClass(Control.TRANSLATE);
	dyn.dynamicUV = true;
	dyn.hitTestTarget = true;
	
	return [
		new this.controlClass(Control.BORDER),
		dyn
	];	
};

function Matrix(a,b,c,d,x,y){
	this.a = (a != null) ? a : 1;
	this.b = b || 0;
	this.c = c || 0;
	this.d = (d != null) ? d : 1;
	this.x = x || 0;
	this.y = y || 0;
}

// used as a single object pool for 
// some matrix operations
Matrix.temp = new Matrix();

Matrix.prototype.toString = function(){
	return "matrix("+this.a+","+this.b+","+this.c+","+this.d+","
		+this.x+","+this.y+")";
};

Matrix.prototype.equals = function(m){
	if (this.a === m.a
	&&  this.b === m.b
	&&  this.c === m.c
	&&  this.d === m.d
	&&  this.x === m.x
	&&  this.y === m.y){
		return true;
	}
	return false;
};

Matrix.prototype.identity = function(){
	this.a = 1;
	this.b = 0;
	this.c = 0;
	this.d = 1;
	this.x = 0;
	this.y = 0;
};

Matrix.prototype.clone = function(){
	return new Matrix(
		this.a,
		this.b,
		this.c,
		this.d,
		this.x,
		this.y
	);
};

Matrix.prototype.copyFrom = function(m){
	this.a = m.a;
	this.b = m.b;
	this.c = m.c;
	this.d = m.d;
	this.x = m.x;
	this.y = m.y;
};

Matrix.prototype.rotate = function(angle){
	var u = Math.cos(angle);
	var v = Math.sin(angle);
	
	var temp = this.a;
	this.a = u * this.a - v * this.b;
	this.b = v * temp + u * this.b;
	temp = this.c;
	this.c = u * this.c - v * this.d;
	this.d = v * temp + u * this.d;
	temp = this.x;
	this.x = u * this.x - v * this.y;
	this.y = v * temp + u * this.y;
};

Matrix.prototype.translate = function(x, y){
	this.x += x;
	this.y += y;
};

Matrix.prototype.concat = function(m){
	var a = this.a * m.a;
	var b = 0;
	var c = 0;
	var d = this.d * m.d;
	var x = this.x * m.a + m.x;
	var y = this.y * m.d + m.y;
	
	if (this.b !== 0 || this.c !== 0 || m.b !== 0 || m.c !== 0) {
		a += this.b * m.c;
		d += this.c * m.b;
		b += this.a * m.b + this.b * m.d;
		c += this.c * m.a + this.d * m.c;
		x += this.y * m.c;
		y += this.x * m.b;
	}
	
	this.a = a;
	this.b = b;
	this.c = c;
	this.d = d;
	this.x = x;
	this.y = y;
};

Matrix.prototype.invert = function() {
	if (this.b === 0 && this.c === 0 && this.a !== 0 && this.d !== 0) {
		
		this.a = 1/this.a;
		this.d = 1/this.d;
		this.b = 0;
		this.c = 0; 
		this.x = -this.a*this.x;
		this.y = -this.d*this.y;
		
	}else{

		var det = this.a*this.d - this.b*this.c;
		if (det === 0) {
			this.identity();
			return;
		}
		det = 1/det;
		
		var temp = this.a;
		this.a = this.d * det;
		this.b = -this.b * det;
		this.c = -this.c * det;
		this.d = temp * det;
		
		temp = this.y;
		this.y = -(this.b * this.x + this.d * this.y);
		this.x = -(this.a * this.x + this.c * temp);
	}
};

Matrix.prototype.getRotationX = function(){
	return Math.atan2(this.b, this.a);
};

Matrix.prototype.getRotationY = function(){
	return Math.atan2(this.c, this.d);
};

Matrix.prototype.getTransformedX = function(x, y){
	return this.x + this.a * x + this.c * y;
};

Matrix.prototype.getTransformedY = function(x, y){
	return this.y + this.d * y + this.b * x;
};

Matrix.prototype.scale = function(x, y) {
	this.a *= x;
	this.b *= y;
	this.c *= x;
	this.d *= y;
	this.x *= x;
	this.y *= y;
};

Matrix.prototype.containsPoint = function(x, y, w, h) {
	// find mouse in local target space
	// and check within bounds of that area
	var inv = Matrix.temp; // use pooled Matrix to reduce allocations
	inv.copyFrom(this);
	inv.invert();
	
	var tx = inv.x + inv.a * x + inv.c * y;
	var ty = inv.y + inv.d * y + inv.b * x;
	// compare locations in non-transformed space (inverted)
	if (tx >= 0 && tx <= w && ty >= 0 && ty <= h){
		return true;
	}
	
	return false;
};
