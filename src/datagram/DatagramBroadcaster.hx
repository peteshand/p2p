package p2p.datagram;

import js.node.Dgram;
import p2p.P2P.P2PMessage;
import js.node.dgram.Socket;
import js.node.buffer.Buffer;
import haxe.Json;

class DatagramBroadcaster {
	var port = 33333;
	var host = '127.0.0.1';
	var buffer:Buffer;
	var client:Socket;

	public function new(host:String, port:Int) {
		this.host = host;
		this.port = port;

		// client = new Socket('udp4', messageCallback);
		client = Dgram.createSocket('udp4');
		// client.
	}

	// function messageCallback(buffer:Buffer, socketAdress:SocketAdress):Void {
	//
	// }

	public function send(message:P2PMessage):Void {
		buffer = new Buffer(Json.stringify(message));
		client.send(buffer, 0, buffer.length, port, host, (err, bytes) -> {
			if (err != null) {
				throw err;
			}
			trace('UDP message sent to ' + host + ':' + port);
			// client.close();
		});
		// function send(buf:Buffer, offset:Int, length:Int, port:Int, address:String, ?callback:Error->Int->Void):Void;
	}
}
