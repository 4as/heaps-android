import h2d.PasswordText;
import h2d.Font;
import h2d.TextInput;
import hxd.Res;
import h2d.Interactive;
import h2d.Mask;
import h2d.Bitmap;
import hxd.Event;
import h2d.Scene.ScaleModeAlign;
import hxd.Window;

class Main extends hxd.App {
	private final arrLoops:Array<Float->Void> = new Array<Float->Void>();
	private var hxdWindow:Window;
	
	override function init() {
		super.init();
		
		hxdWindow = Window.getInstance();
		hxdWindow.title = "Heaps example";
		
		engine.backgroundColor = 0x00000000;
		
		s2d.scaleMode = ScaleMode.LetterBox(hxdWindow.width, hxdWindow.height, false, ScaleModeAlign.Center, ScaleModeAlign.Center);
		s2d.camera.clipViewport = true;
		
#if js
		hxd.js.MobileInput.initialze();
#elseif mobile
		hxd.mobile.AndroidInput.initialize();
#end

		var img:Bitmap = new Bitmap( Res.play.toTile() );
		var but:Interactive = new Interactive(img.tile.width, img.tile.height);
		but.addChild(img);
		but.onClick = onClicked;
		but.x = (hxdWindow.width * 0.5) - (img.tile.width*0.5);
		but.y = (hxdWindow.height * 0.5) - (img.tile.height*0.5) - 70;
		s2d.addChild(but);
		
		var fnt:Font = Res.aldo.toSdfFont(32, MultiChannel, 0.5, 0);
		var txt:TextInput = new TextInput(fnt);
		txt.text = "Click 'PLAY' to play a sound:";
		txt.textColor = 0xeaeaea;
		txt.x = (hxdWindow.width * 0.5) - (txt.textWidth * 0.5);
		txt.y = but.y - 50;
		s2d.addChild(txt);
		
		var txt2:TextInput = new TextInput(fnt);
		txt2.text = "Test standard input and password fields:";
		txt2.textColor = 0xeaeaea;
		txt2.x = (hxdWindow.width * 0.5) - (txt2.textWidth * 0.5);
		txt2.y = but.y + 120;
		s2d.addChild(txt2);
		
		var input:TextInput = new TextInput(fnt);
		input.text = "Name";
		input.x = (hxdWindow.width * 0.5) - (input.textWidth * 0.5);
		input.y = txt2.y + 50;
		s2d.addChild(input);
		
		var pass:PasswordText = new PasswordText(fnt);
		pass.passwordMode = true;
		pass.text = "Password";
		pass.x = (hxdWindow.width * 0.5) - (pass.textWidth * 0.5);
		pass.y = input.y + 50;
		s2d.addChild(pass);

		s2d.camera.clipViewport = true;
		new Mask(hxdWindow.width, hxdWindow.height, s2d);
	}
	
	override function update(dt:Float):Void {
		super.update(dt);
		
		for(l in arrLoops) {
			l(dt);
		}
	}
	
	private function onClicked(ev:Event) {
		Res.button2.play();
	}
	
	public static var INSTANCE:Main;
	
	static function main() {
		// Embed method is the easiest choice to work with for Android builds
		hxd.Res.initEmbed();
		INSTANCE = new Main();
	}
	
	// Provides access to reciving update calls from global context.
	// Required to handle Android input (software keyboards).
	public static function addUpdateLoop(callback:Float->Void) {
		INSTANCE.arrLoops.push(callback);
	}
	
	public static function removeUpdateLoop(callback:Float->Void) {
		INSTANCE.arrLoops.remove(callback);
	}
	
	/**
	 * Gets a full, writable path for a file. The result can be directly used with the Heaps Save.save() method.
	 * Android provides a specific directory for your application where you can save your files. Save.save() doesn't do it for you automatically, hence this helper function.
	 * @param filename A fully qualified path to a writable file.
	 */
	public static function getFilePath(filename:String) {
		#if mobile
		var path:String = hxd.mobile.AndroidTools.get_writable_directory() + "/" + filename;
		#else
		var path:String = filename;
		#end
		return path;
	}
}

