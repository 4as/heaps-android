package h2d;

/**
 * The extension of the default Heaps TextInput class, but with support for password mode.
 * Setting passwordMode = true, will turn all inputted text into stars, i.e. "******"
 */
class PasswordText extends TextInput {
	private var bPasswordMode:Bool;
	public function new(font:Font) {
		super(font);
	}
	
	public var passwordMode(get, set):Bool;
	function get_passwordMode():Bool { return bPasswordMode; }
	function set_passwordMode(value:Bool):Bool {
		if(bPasswordMode == value) return value;
		bPasswordMode = value;
		rebuild();
		return bPasswordMode;
	}
	
	override function initGlyphs(text:String, rebuild:Bool = true) {
		if(bPasswordMode) {
			super.initGlyphs(repeatString("*", text != null ? text.length : 0), rebuild);
		}
		else {
			super.initGlyphs(text, rebuild);
		}
	}
	
	override function focus() {
		interactive.focus();
		selectionRange = {start:0, length: 0};
		cursorIndex = text.length;
	}
	
	public function blur() {
		interactive.blur();
	}
	
	public static function repeatString(text:String, count:UInt):String {
		if (count == 0)	return "";
		
		var sb:StringBuf = new StringBuf();
		for (idx in 0...count) {
			sb.add(text);
		}
		return sb.toString();
	}
}