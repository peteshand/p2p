package comms.connection;

import time.EnterFrame;
import comms.CommsMessage.CommsBatch;
import signals.Signal1;
import js.node.Net;
import js.node.net.Socket;
import js.node.net.Server;
import haxe.Json;

@:access(comms.Comms)
class TCPServerConnection implements IConnection {
	public var onBatch = new Signal1<CommsBatch>();
	public var connectionIndex:Int;
	public var comms:Comms;
	public var active:Bool = true;

	var serverPort:Int;
	var serverHost:String;

	var messages:Array<String> = [];
	var server:Server = null;
	var socket:Socket;
	var callbacks = new Array<{key:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void}>();

	var sending:Bool = false;

	public function new(serverPort:Int = 1337, serverHost:String = 'localhost') {
		this.serverPort = serverPort;
		this.serverHost = serverHost;

		createServer();

		onBatch.add(onBatchReceived);
		EnterFrame.add(tick);
	}

	function createServer() {
		trace("listen");
		server = Net.createServer(function(socket) {
			this.socket = socket;
			// socket.write('Echo server\r\n');
			// socket.pipe(socket);

			trace('server connected');
			socket.on('end', function() {
				trace('server disconnected');
				// socket.end();
			});
			socket.on('data', function(data) {
				var dataStr:String = data.toString();
				var items:Array<String> = dataStr.split("-|-");
				for (item in items) {
					if (item == "")
						continue;
					trace("SERVER: " + item);

					var batch:CommsBatch = null;
					try {
						batch = Json.parse(item);
					} catch (e:Dynamic) {
						trace("Batch Parsing Error: " + e);
						return;
					}

					if (batch.senderIds != null && batch.senderIds.indexOf(comms.instanceId) != -1) {
						// from self
						return;
					}
					// trace(value);
					onBatch.dispatch(batch);
				}
			});
			// socket.write('hello\r\n');
			// socket.pipe(socket);
		});

		trace("listen: " + serverPort);
		server.listen(serverPort, serverHost, function() { // 'listening' listener
			trace('server bound');

			// if (callback != null) {
			//	callback(true);
			// }
		});
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

			for (item in callbacks) {
				if (item.key == messsage.id) {
					var callback = item.callback;
					callback(payload.value, connectionIndex);
				}
			}
		}
	}

	public function send(batch:String):Bool {
		trace("send");
		messages.push(batch + "-|-");
		return true;
	}

	function tick() {
		if (messages.length == 0 || socket == null)
			return;
		sending = true;
		trace("sending");
		var batch = messages.shift();
		trace(batch);
		socket.write(batch, () -> {
			trace("server sent");
			sending = false;
		});
	}

	public function on(id:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void):Void {
		callbacks.push({
			key: id,
			callback: callback
		});
	}

	public function close():Void {
		//
	}
}
