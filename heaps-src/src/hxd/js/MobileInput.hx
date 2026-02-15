package hxd.js;

import h2d.PasswordText;
import h2d.Interactive;
import h2d.TextInput;

/**
 * Helper class for handling input on mobile devices in web enviroment (i.e. targeting JavaScript)
 * Call initialize() to register callbacks for software keyboard events.
 * Putting focus on a TextInput object will cause the software keyboard to appear by injecting a dynamic JS text field over the game.
 */
class MobileWebInput {
	private static final hxdFocus:Interactive = new Interactive(1, 1);
	private static var hxdInput:TextInput = null;
	
	public static function isMobile():Bool {
		#if !js
		return false;
		#else
		var ua = js.Browser.navigator.userAgent.toLowerCase();

		var isMobileUA =
			ua.indexOf("android") != -1 ||
			ua.indexOf("iphone") != -1 ||
			ua.indexOf("ipad") != -1 ||
			ua.indexOf("ipod") != -1 ||
			ua.indexOf("mobile") != -1 ||
			(ua.indexOf("macintosh") != -1 && js.Browser.navigator.maxTouchPoints > 1);

		return isMobileUA;
		#end
	}

	public static function initialze():Void {
		if( !isMobile() ) return;
		TextInput.showSoftwareKeyboard = onShow;
		TextInput.hideSoftwareKeyboard = onHide;
	}

	private static function onShow(input:TextInput):Void {
		hxdInput = input;
		hxdInput.getScene().addChild(hxdFocus);
		var password = hxdInput is PasswordText ? cast(hxdInput, PasswordText).passwordMode : false;
#if js
		show(hxdInput.text, "Type here...", password);
#end
	}

	private static function onHide(input:TextInput):Void {
		if (hxdInput == null) return;
		
		hxdInput.getScene().removeChild(hxdFocus);
#if js
		hide();
#end
	}

#if js
	private static var jsOverlay:js.html.DivElement = null;
	private static var jsInput:js.html.InputElement = null;

	private static function show(initial:String, placeholder:String, isPassword:Bool = false):Void {
		hide();

		var doc = js.Browser.document;

		/* ---------------- Overlay ---------------- */

		jsOverlay = doc.createDivElement();
		jsOverlay.style.position = "fixed";
		jsOverlay.style.left = "0";
		jsOverlay.style.top = "0";
		jsOverlay.style.width = "100vw";
		jsOverlay.style.height = "100vh";
		jsOverlay.style.backgroundColor = "black";
		jsOverlay.style.opacity = "0.5";
		jsOverlay.style.zIndex = "9998";

		doc.body.appendChild(jsOverlay);

		/* ---------------- Input ---------------- */

		jsInput = doc.createInputElement();
		jsInput.type = isPassword ? "password" : "text";
		jsInput.value = initial;
		jsInput.placeholder = placeholder;
		jsInput.maxLength = 20;

		// Layout
		jsInput.style.position = "fixed";
		jsInput.style.left = "0px";
		jsInput.style.top = "0px";
		jsInput.style.width = "100vw";
		jsInput.style.height = "40px";

		// Appearance
		jsInput.style.backgroundColor = "black";
		jsInput.style.color = "white";
		jsInput.style.border = "none";
		jsInput.style.outline = "none";
		jsInput.style.padding = "0";
		jsInput.style.margin = "0";

		// Text alignment
		jsInput.style.textAlign = "center";
		jsInput.style.fontSize = "20px"; // ≥16px avoids mobile zoom
		jsInput.style.fontFamily = "sans-serif";

		jsInput.style.zIndex = "9999";

		/* --------- ASCII-only input filter --------- */

		jsInput.oninput = function(_) {
			// Keep only ASCII characters (32–126)
			var filtered = new StringBuf();
			for (i in 0...jsInput.value.length) {
				var c = jsInput.value.charCodeAt(i);
				if (c >= 32 && c <= 126) {
					filtered.addChar(c);
				}
			}
			var result = filtered.toString();
			if (result != jsInput.value) {
				jsInput.value = result;
			}
		};

		/* -------------- Confirm / Finish -------------- */

		jsInput.onkeydown = function(e:js.html.KeyboardEvent) {
			if (e.key == "Enter") {
				e.preventDefault();
				finish();
			}
		};

		jsInput.onblur = function(_) {
			finish();
		};

		doc.body.appendChild(jsInput);

		// Delay focus slightly for iOS Safari
		js.Browser.window.setTimeout(function() {
			jsInput.focus();
		}, 50);
		
		jsInput.focus();
	}

	private static function hide():Void {
		if (jsInput == null) return;
		
		jsInput.onblur = null;
		jsInput.onkeydown = null;
		jsInput.oninput = null;
		js.Browser.document.body.removeChild(jsInput);
		js.Browser.document.body.removeChild(jsOverlay);

		jsInput = null;
		jsOverlay = null;
	}

	private static function finish():Void {
		if( jsInput == null ) return;
		hxdInput.text = jsInput.value;
		hxdFocus.focus();
		hide();
	}
#end
}
