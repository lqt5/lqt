function App(){
	this.canvas = document.getElementById("canvas");
	this.ctx = this.canvas.getContext("2d");
	
	this.displayList = [];
	this.tool = new TransformTool(this.ctx);
	
	this.bindHandlers();
	
	this.loader = new ImagesLoader(this.handleImagesLoaded);
	this.loader.load([
		"images/dunny.png",
		"images/fatcap.png",
		"images/piggy.png"
	]);
}

App.create = function(){
	App.instance = new App();
	return App.instance;
}
App.instance = null;

App.prototype.bindHandlers = function(){
	// instance-specific event handlers bound to this
	this.up = this.up.bind(this);
	this.down = this.down.bind(this);
	this.move = this.move.bind(this);
	this.render = this.render.bind(this);
	this.handleImagesLoaded = this.handleImagesLoaded.bind(this);
	this.handleDrawSelected = this.handleDrawSelected.bind(this);
};

App.prototype.handleImagesLoaded = function(){
	this.addPictures();
	this.setupTool();
	
	// selects pictures on mouse down
	this.canvas.addEventListener(Mouse.START, this.down);
	
	// draws initial screen
	this.render();
};

App.prototype.addPictures = function(){
	var offx = 150;
	var offy = 100;
	
	var i = 0;
	var n = this.loader.images.length;
	for (i=0; i<n; i++){
		this.displayList.push(new Picture(this.loader.images[i], i*offx, i*offy));
	}
};

App.prototype.setupTool = function(){
	var controls = this.getCustomControls();
	this.tool.setControls(controls);	
};

App.prototype.getCustomControls = function(){
	var translater = new Control(Control.TRANSLATE);
	// translate control is "selected" by clicking
	// on the target's shape, not the control point
	translater.hitTestTarget = true;

	var targetContent = new Control(Control.TARGET);
	// setup a callback to draw the selected picture
	// within the stack of controls
	targetContent.drawCallback = this.handleDrawSelected;
	
	return [
		new Control(Control.ROTATE, 0,0, 0,0, 30),
		new Control(Control.ROTATE, 0,1, 0,0, 30),
		new Control(Control.ROTATE, 1,0, 0,0, 30),
		new Control(Control.ROTATE, 1,1, 0,0, 30),
		targetContent, // renders target between controls
		translater,
		new Control(Control.BORDER),
		new Control(Control.REGISTRATION, .5,.5, 0,0, 10),
		new Control(Control.SKEW_Y, 0,.5, 0,0, 10),
		new Control(Control.SCALE_X, 1,.5, 0,0, 10),
		new Control(Control.SKEW_X, .5,0, 0,0, 10),
		new Control(Control.SCALE_Y, .5,1, 0,0, 10),
		new Control(Control.SCALE, 0,0, 0,0, 10),
		new Control(Control.SCALE, 0,1, 0,0, 10),
		new Control(Control.SCALE, 1,0, 0,0, 10),
		new Control(Control.SCALE, 1,1, 0,0, 10),
		new Control(Control.ROTATE_SCALE, 1,0, 15,-15, 10),
		new Control(Control.SCALE_UNIFORM, 1,1, 15,15, 10),
		new Control(Control.ROTATE, .5,0, 0,-20)
	];
};

App.prototype.down = function(event){
	
	Mouse.get(event, this.canvas);
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
		this.canvas.addEventListener(Mouse.MOVE, this.move);
		document.addEventListener(Mouse.END, this.up);
	}
	
	requestAnimationFrame(this.render);
	event.preventDefault();
};

App.prototype.move = function(event){
	
	Mouse.get(event, this.canvas);
	this.applyDynamicControls(event);
	this.tool.move(Mouse.x, Mouse.y);
	
	requestAnimationFrame(this.render);
	event.preventDefault();
};

App.prototype.up = function(event){
	
	this.tool.end();
	
	this.canvas.removeEventListener(Mouse.MOVE, this.move);
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
		t = pic.transform;
		
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
	
	this.clear();
	this.drawDisplayList();
	
	// assumes tool and tool target is
	// always drawn on top of rest of the 
	// display list (after drawDisplayList())
	
	// set styles to be used by tool drawings
	this.ctx.fillStyle = "#FFF";
	this.ctx.strokeStyle = "#08F";
	this.ctx.lineWidth = 2;
	this.tool.draw();
	
};

App.prototype.clear = function(){
	console.log('this.ctx.setTransform:',this.ctx.setTransform)
	this.ctx.setTransform(1,0,0,1,0,0); // reset (identity)
	this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
};

App.prototype.handleDrawSelected = function(control, ctx){
	control.tool.target.owner.draw(ctx);
	return false;
};

App.prototype.drawDisplayList = function(){
	var targetControl = this.findControlByType(Control.TARGET);
	var i = 0;
	var n = this.displayList.length;
	for (i=0; i<n; i++){
		// let the TARGET control draw the selected image
		// so it can be layered within the controls
		// otherwise draw the other images here
		if (!targetControl || this.tool.target !== this.displayList[i].transform){
			this.displayList[i].draw(this.ctx);
		}
	}
};

/**
 * Display list item showing a picture
 */
function Picture(image, x, y){
	this.image = image;
	var m = new Matrix(1,0,0,1,x,y);
	this.transform = new Transformable(image.width, image.height, m, this);
};

Picture.prototype.draw = function(ctx){
	ctx.save();
	var m = this.transform.matrix;
	ctx.setTransform(m.a,m.b,m.c,m.d, m.x,m.y);
	ctx.drawImage(this.image, 0, 0); // transform handles position
	ctx.restore();
};
