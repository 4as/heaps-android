package hxd.mobile;

#if mobile
// The "package" name found in cpp/stubs.c file (look for #define HL_NAME(n) forus_##n). It can be whatever you want, as long as the two entries match.
@:hlNative("forus")
class AndroidTools
{
	public static function get_writable_directory():String {
		return null;
	}

	public static function request_text_input(message:String, defaultText:String, isPassword:Bool, maxLength:Int, callback:String->Void):Void {
		
	}

	public static function poll_text_input():Void {
		
	}
}
#end