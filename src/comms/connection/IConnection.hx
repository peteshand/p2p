package comms.connection;

import comms.CommsMessage.CommsBatch;
import comms.MulticastAddr;

interface IConnection {
	// var port:Int;
	// var multicastAddr:MulticastAddr;
	function send(batch:CommsBatch):Void;
	function on(id:String, callback:(payload:Dynamic) -> Void):Void;
	function close():Void;
}
