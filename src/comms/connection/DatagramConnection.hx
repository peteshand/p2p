package comms.connection;

import comms.MulticastAddr;
import js.node.Dgram;
import comms.CommsMessage.CommsBatch;
import comms.connection.IConnection;
import comms.CommsMessage;
import comms.CommsPayload;
import js.node.dgram.Socket;
import js.node.buffer.Buffer;
import haxe.Json;
import haxe.Serializer;

@:access(comms.Comms)
class DatagramConnection implements IConnection {
	var port = 33333;
	var multicastAddr = "233.255.255.255";
	var callback:(bindsuccessful:Bool) -> Void;
	var buffer:Buffer;
	var socket:Socket;
	var callbacks = new Map<String, (payload:Dynamic) -> Void>();

	// var serializer:Serializer;

	public function new(port:Int = 33333, ?multicastAddr:MulticastAddr, callback:(bindsuccessful:Bool) -> Void = null) {
		this.port = port;
		if (multicastAddr == null)
			this.multicastAddr = MulticastAddr.DEFAULT_ADDRESS;
		else
			this.multicastAddr = multicastAddr;

		this.callback = callback;

		// serializer = new Serializer();

		socket = Dgram.createSocket({type: "udp4", reuseAddr: true});

		socket.on('message', onMessage);
		socket.on('error', onError);
		socket.on('listening', onListening);

		socket.bind(port);
	}

	// value:Event<Socket>, remote:Socket
	function onMessage(value, remote) {
		// trace(value);
		var batch:CommsBatch = null;
		try {
			batch = Json.parse(value);
		} catch (e:Dynamic) {
			trace("Parsing Error: " + e);
			return;
		}

		if (batch.senderId == Comms.instanceId) {
			// from self
			return;
		}
		for (messsage in batch.messages) {
			// trace("onMessage: " + remote.address + ':' + remote.port + ' - ' + messsage);
			// messsage.remoteHost = remote.address;
			// messsage.remotePort = Std.parseInt(remote.port);

			// trace("messsage.id = " + messsage.id);
			for (key in callbacks.keys()) {
				// trace("key = " + key);
				if (key == messsage.id) {
					var callback = callbacks.get(key);
					var payload:CommsPayload = Json.parse(messsage.payload);
					callback(payload.value);
				}
			}
		}
	}

	function onError(err) {
		trace("updtest: on error: " + err.stack);
		if (callback != null)
			callback(false);
	}

	function onListening() {
		socket.addMembership(multicastAddr);
		var address = socket.address();
		trace('UDP Server listening on ' + address.address + ":" + address.port);
		socket.setBroadcast(true);
		if (callback != null)
			callback(true);
	}

	public function on(id:String, callback:(payload:Dynamic) -> Void):Void {
		callbacks.set(id, callback);
	}

	public function send(batch:CommsBatch):Void {
		var str:String = Json.stringify(batch);

		// serializer.serialize(batch);

		// trace("send: " + host + ":" + port + " - " + str);
		//  trace("send: " + multicastAddr + ":" + port + " - " + str);
		// buffer = new Buffer(str);
		buffer = Buffer.allocUnsafe(str.length);
		buffer.write(str, 0, str.length, "utf8");

		// socket.send(buffer, 0, buffer.length, port, host, (err, bytes) -> {
		socket.send(buffer, 0, buffer.length, port, multicastAddr, (err, bytes) -> {
			if (err != null) {
				throw err;
			}
			// trace('UDP message sent to ' + host + ':' + port);
			// trace('UDP message sent to ' + multicastAddr + ':' + port);
			// socket.close();
		});
	}

	public function close():Void {
		// need to implement
	}
}
