package hxd.mobile;

import h2d.Interactive;
import h2d.PasswordText;
import h2d.TextInput;

/**
 * Helper class for handling input on mobile Android devices.
 * Call initialize() to register callbacks for software keyboard events.
 * Putting focus on a TextInput object will cause the software keyboard to appear by injecting a dynamic Java text field over the game.
 */
class AndroidInput {
	private static final hxdFocus:Interactive = new Interactive(1, 1);
	private static var hxdInput:TextInput = null;
	
	public static function initialize() {
		TextInput.showSoftwareKeyboard = onShow;
		TextInput.hideSoftwareKeyboard = onHide;
	}
	
	private static function onShow(input:TextInput):Void {
		hxdInput = input;
		hxdInput.getScene().addChild(hxdFocus);
		var password = hxdInput is PasswordText ? cast(hxdInput, PasswordText).passwordMode : false;
#if mobile
		AndroidTools.request_text_input("Input", hxdInput.text, password, 20, finish);
		Main.addUpdateLoop(onPoll);
#end
	}

	private static function onHide(input:TextInput):Void {
		if (hxdInput == null) return;
		
		hxdInput.getScene().removeChild(hxdFocus);
#if mobile
		Main.removeUpdateLoop(onPoll);
#end
	}
	
#if mobile
	private static function onPoll(dt:Float) {
		AndroidTools.poll_text_input();
	}
	
	private static function finish(result:String):Void {
		if( result != null ) {
			hxdInput.text = result;
		}
		hxdFocus.focus();
		onHide(hxdInput);
	}
#end
}