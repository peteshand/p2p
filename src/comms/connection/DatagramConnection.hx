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
import signals.Signal1;

@:access(comms.Comms)
class DatagramConnection implements IConnection {
	public var connectionIndex:Int;
	public var comms:Comms;

	var port = 33333;
	var multicastAddr = "233.255.255.255";
	var callback:(bindsuccessful:Bool) -> Void;
	var buffer:Buffer;
	var socket:Socket;
	var callbacks = new Map<String, (payload:Dynamic, connectionIndex:Int) -> Void>();

	public var onBatch = new Signal1<CommsBatch>();

	public function new(port:Int = 33333, ?multicastAddr:MulticastAddr, callback:(bindsuccessful:Bool) -> Void = null) {
		this.port = port;
		// connectionIndex = comms.CONNECTION_COUNT++;
		if (multicastAddr == null)
			this.multicastAddr = MulticastAddr.DEFAULT_ADDRESS;
		else
			this.multicastAddr = multicastAddr;

		this.callback = callback;

		socket = Dgram.createSocket({type: "udp4", reuseAddr: true});

		socket.on('message', onMessage);
		socket.on('error', onError);
		socket.on('listening', onListening);

		socket.bind(port);

		onBatch.add(onBatchReceived);
	}

	function onMessage(value, remote) {
		var batch:CommsBatch = null;
		try {
			batch = Json.parse(value);
		} catch (e:Dynamic) {
			trace("Batch Parsing Error: " + e);
			return;
		}

		if (batch.senderIds != null && batch.senderIds.indexOf(comms.instanceId) != -1) {
			// from self
			return;
		}
		onBatch.dispatch(batch);
	}

	function onBatchReceived(batch:CommsBatch) {
		for (messsage in batch.messages) {
			if (messsage.id == '')
				continue;
			var payload:CommsPayload = null;
			try {
				payload = Json.parse(messsage.payload);
			} catch (e:Dynamic) {
				trace("Payload Parsing Error: " + e);
				continue;
			}

			for (key in callbacks.keys()) {
				if (key == messsage.id) {
					var callback = callbacks.get(key);
					callback(payload.value, connectionIndex);
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

	public function on(id:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void):Void {
		callbacks.set(id, callback);
	}

	public function send(batch:String):Void {
		// if (batch.indexOf('"{"value":"SendMessage: object Comms not found!') != -1) {
		//	trace("here");
		// }
		buffer = Buffer.allocUnsafe(batch.length);
		if (batch.length > 1472) {
			trace("ERROR: batch to large");
		}
		// trace("length = " + batch.length);
		// trace("batch = " + batch);
		buffer.write(batch, 0, batch.length, "utf8");

		socket.send(buffer, 0, buffer.length, port, multicastAddr, (err, bytes) -> {
			if (err != null) {
				trace(err);
			}
		});
	}

	public function close():Void {
		// need to implement
	}
}
