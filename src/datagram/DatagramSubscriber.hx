package p2p.datagram;

import js.node.Dgram;
import js.node.dgram.Socket;
import p2p.P2P.P2PMessage;
import haxe.Json;

class DatagramSubscriber {
	var server:Socket;
	var callbacks = new Map<String, (message:P2PMessage) -> Void>();

	public function new(host:String, port:Int) {
		server = Dgram.createSocket('udp4');
		server.on('listening', () -> {
			var address = server.address();
			trace('UDP Server listening on ' + address.address + ":" + address.port);
		});
		server.on('message', (value, remote) -> {
			var messsage:P2PMessage = Json.parse(value);
			trace(remote.address + ':' + remote.port + ' - ' + messsage);
			for (key in callbacks.keys()) {
				trace("key = " + key);
				if (key == messsage.id) {
					var callback = callbacks.get(key);
					callback(messsage);
				}
			}
		});
		server.bind(port, host);
	}

	public function addListener(id:String, callback:(message:P2PMessage) -> Void):Void {
		callbacks.set(id, callback);
	}
}
