package comms.broadcaster;

interface IBroadcaster {
	var id:String;
	var value(get, null):Dynamic;
	function setCurrentValue():Void;
	function addGuard(guard:(id:Dynamic, value:Dynamic) -> Bool):Void;
}
