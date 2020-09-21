package comms.connection;

import comms.CommsMessage.CommsBatch;
import comms.MulticastAddr;
import signals.Signal1;

interface IConnection {
	var onBatch:Signal1<CommsBatch>;
	var connectionIndex:Int;
	var comms:Comms;
	var active:Bool;
	function send(batch:String):Bool;
	function on(id:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void):Void;
	function close():Void;
}
