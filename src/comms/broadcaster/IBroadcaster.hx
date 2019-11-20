package comms.broadcaster;

interface IBroadcaster {
	var id:String;
	var value(get, null):Dynamic;
	function setCurrentValue():Void;
}
