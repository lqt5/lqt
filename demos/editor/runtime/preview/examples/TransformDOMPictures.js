function App(){
	
	this.dom = document.getElementById("dom");
	var toolElem = document.getElementById("svg-tool");
	this.tool = new DOMTransformTool(toolElem);
	
	this.displayList = [
		new Picture(document.getElementById("dunny"),0,0),
		new Picture(document.getElementById("fatcap"),150,100),
		new Picture(document.getElementById("piggy"),300,200),
		new Picture(document.getElementById("text-box"),450,300)
	];
	toolElem.style.zIndex = this.displayList.length;
	
	this.setupTool();
	
	this.bindHandlers();
	
	// selects pictures on mouse down
	this.dom.addEventListener(Mouse.START, this.down);
	
	// draws initial screen
	this.render();
}

App.create = function(){
	App.instance = new App();
	return App.instance;
}
App.instance = null;

App.prototype.bindHandlers = function(){
	// instance-specific event handlers bound to this
	console.log('this:',this)
	this.up = this.up.bind(this);
	this.down = this.down.bind(this);
	this.move = this.move.bind(this);
	this.render = this.render.bind(this);
};

App.prototype.setupTool = function(){
	ControlSet.controlClass = DOMControl;
	var controls = this.getCustomControls();
	this.tool.setControls(controls);	
};

App.prototype.getCustomControls = function(){
	var translater = new DOMControl(Control.TRANSLATE);
	// translate control is "selected" by clicking
	// on the target's shape, not the control point
	translater.hitTestTarget = true;
	
	var targetContent = new DOMControl(Control.TARGET);
	return [
		new DOMControl(Control.ROTATE, 0,0, 0,0, 30),
		new DOMControl(Control.ROTATE, 0,1, 0,0, 30),
		new DOMControl(Control.ROTATE, 1,0, 0,0, 30),
		new DOMControl(Control.ROTATE, 1,1, 0,0, 30),
		targetContent, // renders target between controls
		translater,
		new DOMControl(Control.BORDER),
		new DOMControl(Control.REGISTRATION, .5,.5, 0,0, 10),
		new DOMControl(Control.SKEW_Y, 0,.5, 0,0, 10),
		new DOMControl(Control.SCALE_X, 1,.5, 0,0, 10),
		new DOMControl(Control.SKEW_X, .5,0, 0,0, 10),
		new DOMControl(Control.SCALE_Y, .5,1, 0,0, 10),
		new DOMControl(Control.SCALE, 0,0, 0,0, 10),
		new DOMControl(Control.SCALE, 0,1, 0,0, 10),
		new DOMControl(Control.SCALE, 1,0, 0,0, 10),
		new DOMControl(Control.SCALE, 1,1, 0,0, 10),
		new DOMControl(Control.ROTATE_SCALE, 1,0, 15,-15, 10),
		new DOMControl(Control.SCALE_UNIFORM, 1,1, 15,15, 10),
		new DOMControl(Control.ROTATE, .5,0, 0,-20)
	];
};

App.prototype.down = function(event){
	
	Mouse.get(event, this.dom);
	var controlled = this.tool.start(Mouse.x, Mouse.y);
	
	// if tool wasnt selected and being controlled
	// attempt to make a new selection at this location
	if (!controlled && this.selectImage(Mouse.x, Mouse.y)){
		// selection occurred
		// force select the translate control
		// to be able to start moving right away
		controlled = this.tool.start(Mouse.x, Mouse.y, this.findControlByType(Control.TRANSLATE)); 
	}
	
	if (controlled){
		// events for moving selection
		this.dom.addEventListener(Mouse.MOVE, this.move);
		document.addEventListener(Mouse.END, this.up);
	}
	
	requestAnimationFrame(this.render);
	event.preventDefault();
};

App.prototype.move = function(event){
	
	Mouse.get(event, this.dom);
	this.applyDynamicControls(event);
	this.tool.move(Mouse.x, Mouse.y);
	
	requestAnimationFrame(this.render);
	event.preventDefault();
};

App.prototype.up = function(event){
	
	this.tool.end();
	
	this.dom.removeEventListener(Mouse.MOVE, this.move);
	document.removeEventListener(Mouse.END, this.up);
	
	requestAnimationFrame(this.render);
	event.preventDefault();
};

App.prototype.applyDynamicControls = function(event){
	// if dynamic, set controls based on 
	// keyboard keys
	var dyn = this.getDynamicControl();
	if (dyn){
		if (event.ctrlKey){
			if (event.shiftKey){
				dyn.type = Control.ROTATE_SCALE;
			}else{
				dyn.type = Control.ROTATE;
			}
		}else if (event.shiftKey){
			dyn.type = Control.SCALE;
		}else{
			dyn.type = Control.TRANSLATE;
		}
	}
};

App.prototype.getDynamicControl = function(){
	var i = 0;
	var n = this.tool.controls.length;
	for (i=0; i<n; i++){
		if (this.tool.controls[i].dynamicUV){
			return this.tool.controls[i];
		}
	}
	return null;
};

App.prototype.findControlByType = function(type){
	var i = 0;
	var n = this.tool.controls.length;
	for (i=0; i<n; i++){
		if (this.tool.controls[i].type == type){
			return this.tool.controls[i];
		}
	}
	return null;
}

App.prototype.selectImage = function(x, y){
	var pic = null;
	var t = null;
	
	// walk backwards selecting top-most first
	var i = this.displayList.length;
	while (i--){
		pic = this.displayList[i];
		
		console.log('pic:',pic)
		t = pic.transform;
		console.log(t)
		console.log(t.matrix.containsPoint(x, y, t.width, t.height))
		if (t.matrix.containsPoint(x, y, t.width, t.height)){
			if (this.tool.target !== t){
				
				// select
				this.tool.setTarget(t);
				// reorder for layer rendering
				this.displayList.splice(i,1);
				this.displayList.push(pic);
				return true;
			}
			
			// already selected
			return false;
		}
	}
	
	// deselect
	this.tool.setTarget(null);
	return false;
};

App.prototype.render = function(){
	this.drawDisplayList();
	this.tool.draw();
};


App.prototype.drawDisplayList = function(){
	var i = 0;
	var n = this.displayList.length;
	for (i=0; i<n; i++){
		this.displayList[i].image.style.zIndex = i;
		this.displayList[i].draw();
	}
};

/**
 * Display list item showing a picture
 */
function Picture(image, x, y){
	this.image = image;
	var m = new Matrix(1,0,0,1,x,y);
	var w = image.width || image.clientWidth;
	var h = image.height || image.clientHeight;
	
	console.log('this:',this)
	this.transform = new Transformable(w, h, m, this);
	
	var origin = "0 0";
	var style = image.style;
	if (typeof style.transformOrigin !== "undefined"){
		style.transformOrigin = origin;
		
	}else if (typeof style.webkitTransformOrigin !== "undefined"){
		style.webkitTransformOrigin = origin;
	}else if (typeof style.msTransformOrigin !== "undefined"){
		style.msTransformOrigin = origin;
	}else if (typeof style.MozTransformOrigin !== "undefined"){
		style.MozTransformOrigin = origin;
	}else if (typeof style.OTransformOrigin !== "undefined"){
		style.OTransformOrigin = origin;
	}
};

Picture.prototype.draw = function(){
	var trans = this.transform.matrix.toString();
	var style = this.image.style;
	
	if (typeof style.transform !== "undefined"){
		style.transform = trans;
		
	}else if (typeof style.webkitTransform !== "undefined"){
		style.webkitTransform = trans;
	}else if (typeof style.msTransform !== "undefined"){
		style.msTransform = trans;
	}else if (typeof style.MozTransform !== "undefined"){
		style.MozTransform = trans;
	}else if (typeof style.OTransform !== "undefined"){
		style.OTransform = trans;
	}
};