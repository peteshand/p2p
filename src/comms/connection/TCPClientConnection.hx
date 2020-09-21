package comms.connection;

import time.EnterFrame;
import haxe.Json;
import comms.CommsMessage.CommsBatch;
import signals.Signal1;
import js.node.Net;
import js.node.net.Socket;
import js.node.net.Server;
import notifier.Notifier;

@:access(comms.Comms)
class TCPClientConnection implements IConnection {
	public var onBatch = new Signal1<CommsBatch>();
	public var connectionIndex:Int;
	public var comms:Comms;
	public var active:Bool = true;

	var callbacks = new Array<{key:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void}>();

	var serverPort:Int;
	var serverHost:String = '127.0.0.1';

	var client:Socket = null;
	var server:Server = null;

	var messages:Array<String> = [];
	var sending:Bool = false;

	var createTime:Null<Float> = null;
	var connected:Bool = false;
	var disconnectedSeconds = new Notifier<Null<Int>>(null);
	var instanceId(get, null):Null<Float>;

	public function new(serverPort:Int = 1337, serverHost:String) {
		this.serverPort = serverPort;
		this.serverHost = serverHost;

		createClient();

		onBatch.add(onBatchReceived);
		EnterFrame.add(tick);

		disconnectedSeconds.add((value:Null<Int>) -> {
			if (value > 4) {
				createClient();
			}
		});
	}

	function createClient() {
		createTime = Date.now().getTime();

		if (client != null) {
			// TODO: clean up old client
			client.destroy();
		}
		connected = false;
		try {
			trace("listen: " + serverPort + ", " + serverHost);
			client = Net.connect(serverPort, serverHost, function() { // 'connect' listener
				trace('client connected');
				connected = true;
				// client.write('world!\r\n');
			});
		} catch (e:Dynamic) {
			trace(e);
			connected = false;
			return;
		}

		client.on('data', onData);
		client.on('error', function(e:Dynamic) {
			trace('client error');
			trace(e);
		});
		client.on('end', function() {
			trace('client disconnected');
		});
		client.on('close', function() {
			trace('client close');
			connected = false;
		});
		client.on('drain', function() {
			trace('client drain');
		});
	}

	function onData(data:Dynamic) {
		// trace('CLIENT: ' + data.toString());
		var batch:CommsBatch = null;

		var dataStr:String = data.toString();
		if (dataStr == null)
			return;
		var items:Array<String> = dataStr.split("-|-");
		for (item in items) {
			if (item == "")
				continue;
			try {
				batch = Json.parse(item);
			} catch (e:Dynamic) {
				trace("Batch Parsing Error: " + e);
				return;
			}

			if (batch.senderIds != null && batch.senderIds.indexOf(instanceId) != -1) {
				// from self
				return;
			}
			// trace(value);
			onBatch.dispatch(batch);
		}
		// trace(dataStr);
	}

	function get_instanceId() {
		if (comms == null)
			return null;
		return comms.instanceId;
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
		messages.push(batch + "-|-");
		return true;
	}

	function tick() {
		if (!connected && active) {
			var dif:Float = Date.now().getTime() - createTime;
			disconnectedSeconds.value = Math.floor(dif / 1000);
			return;
		}

		if (messages.length == 0 || sending == true)
			return;
		sending = true;
		var batch = messages.shift();
		client.write(batch, () -> {
			// trace("client sent");
			// trace(batch);
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
