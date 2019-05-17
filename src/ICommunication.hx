package p2p;

import p2p.P2P.P2PMessage;

interface ICommunication {
	var host:String;
	var port:Int;
	function send(message:P2PMessage):Void;
	function addListener(id:String, callback:(message:P2PMessage) -> Void):Void;
}
