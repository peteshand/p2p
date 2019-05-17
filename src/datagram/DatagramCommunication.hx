package p2p.datagram;

import p2p.ICommunication;
import p2p.P2P.P2PMessage;

class DatagramCommunication implements ICommunication {
	public var host:String;
	public var port:Int;

	var broadcaster:DatagramBroadcaster;
	var subscriber:DatagramSubscriber;

	public function new(host:String = "127.0.0.1", port:Int = 33333) {
		this.host = host;
		this.port = port;

		broadcaster = new DatagramBroadcaster(host, port);
		// subscriber = new DatagramSubscriber(host, port);
	}

	public function send(message:P2PMessage):Void {
		broadcaster.send(message);
	}

	public function addListener(id:String, callback:(message:P2PMessage) -> Void):Void {
		// subscriber.addListener(id, callback);
	}
}
