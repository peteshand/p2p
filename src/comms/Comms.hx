package comms;

import keyboard.Key;
import keyboard.Keyboard;
import comms.CommsMessage.CommsBatch;
import delay.Delay;
import comms.broadcaster.*;
import comms.subscriber.*;
import comms.connection.IConnection;
import notifier.Notifier;
import notifier.MapNotifier;
import comms.notifier.*;
import haxe.Json;
import time.EnterFrame;
import haxe.Serializer;

class Comms {
	static var staticInstance:Comms;

	public static inline function init() {
		if (staticInstance == null) {
			staticInstance = new Comms();
		}
	}

	public static function install_(connection:IConnection) {
		Comms.init();
		staticInstance.install(connection);
	}

	public static function addBroadcast_<T>(id:String, ?map:MapNotifier<String, T>, ?notifier:Notifier<T>):Void {
		Comms.init();
		staticInstance.addBroadcast(id, map, notifier);
	}

	public static function addSubscriber_<T>(id:String, ?map:MapNotifier<String, T>, ?notifier:Notifier<T>):Void {
		Comms.init();
		staticInstance.addSubscriber(id, map, notifier);
	}

	public static function send_(id:String, payload:Dynamic = ""):Void {
		Comms.init();
		staticInstance.send(id, payload);
	}

	public static function on_(id:String, callback:(payload:Dynamic) -> Void):Void {
		Comms.init();
		staticInstance.on(id, callback);
	}

	public static function relay_<T>(id:String):Void {
		Comms.init();
		staticInstance.relay(id);
	}

	// var PAUSE_BROADCAST:Bool = false;
	// var CONNECTION_COUNT:Int = 0;
	var instanceId:Null<Float>;

	public var broadcasters = new Map<String, IBroadcaster>();
	public var subscribers = new Map<String, ISubscriber>();

	var connections:Array<IConnection> = [];
	var listeningToConnect:Bool = false;

	var messages:Array<CommsMessage> = [];
	var tickCount:Int = 0;

	// @:isVar public var selfListen(default, set):Bool = false;
	var batchSize:Int = 0;
	var sent_messages = new Map<String, String>();
	var received_messages = new Map<String, Dynamic>();

	var relayer:Relayer;

	public function new() {
		relayer = new Relayer(this);
	}

	public function install(connection:IConnection) {
		if (instanceId == null) {
			instanceId = Math.floor(Math.random() * 100000000000);
		}
		connection.comms = this;
		connection.connectionIndex = connections.length;
		connections.push(connection);

		for (subscriber in subscribers) {
			subscriber.addConnection(connection);
		}

		#if (debugComms && html5)
		Reflect.setProperty(js.Browser.window, 'sent_messages', sent_messages);
		Reflect.setProperty(js.Browser.window, 'received_messages', received_messages);
		#end

		/*if (!listeningToConnect) {
			listeningToConnect = true;
			on('connect', onPeerConect);
		}*/

		relayer.addConnection(connection);
		relayer.add("connect");

		connection.on('connect', (payload, connectionIndex) -> {
			trace("NEW CONNECTION -------------------------------------");
			onPeerConect();
		});
		Delay.killDelay(sendConnectMessage);
		Delay.byFrames(30, sendConnectMessage);

		Keyboard.onPress(Key.H, onPeerConect).ctrl(true).shift(true);
	}

	function onPeerConect() {
		for (broadcaster in broadcasters) {
			broadcaster.setCurrentValue();
		}
	}

	function sendConnectMessage() {
		send("connect", 0);
		EnterFrame.remove(tick);
		EnterFrame.add(tick);
	}

	public function addBroadcast<K, T>(id:String, ?map:MapNotifier<K, T>, ?notifier:Notifier<T>):Void {
		if (notifier != null)
			broadcasters.set(id, new NotifierBroadcaster<T>(this, notifier, id));
		if (map != null)
			broadcasters.set(id, new MapBroadcaster<K, T>(this, map, id));
	}

	public function addSubscriber<K, T>(id:String, ?map:MapNotifier<K, T>, ?notifier:Notifier<T>):Void {
		if (notifier != null)
			subscribers.set(id, new NotifierSubscriber<T>(this, notifier, id));
		if (map != null)
			subscribers.set(id, new MapSubscriber<K, T>(this, map, id));
	}

	// public function removeBroadcast(notifier:Notifier<Dynamic>, id:String):Void {}
	// public function removeSubscriber(notifier:Notifier<Dynamic>, id:String):Void {}

	public function send(id:String, payload:Dynamic = "", overrideById:Bool = true):Void {
		var message:CommsMessage = {
			id: id,
			payload: Json.stringify({value: payload})
		}
		var size:Int = Math.round(message.id.length + message.payload.length + 10);
		batchSize += size;
		if (batchSize > 500) {
			sendBatch();
		}
		#if (debugComms && html5)
		sent_messages.set(id, message.payload);
		#end
		if (overrideById) {
			for (i in 0...messages.length) {
				if (messages[i].id == id) {
					messages[i].payload = Json.stringify({value: payload});
					return;
				}
			}
		}
		messages.push(message);
	}

	public function on(id:String, callback:(payload:Dynamic) -> Void):Void {
		for (connection in connections) {
			connection.on(id, (payload, connectionIndex) -> {
				#if (debugComms && html5)
				received_messages.set(id, payload);
				#end
				callback(payload);
			});
		}
	}

	public function relay<T>(id:String):Void {
		relayer.add(id);
	}

	function tick() {
		if (tickCount++ % 2 != 0)
			return;
		sendBatch();
	}

	function sendBatch() {
		if (messages.length == 0) {
			return;
		}
		var batchStr:String = Json.stringify({
			senderIds: [instanceId],
			messages: messages
		});

		var serializedStr:String = Serializer.run({
			senderIds: [instanceId],
			messages: messages
		});
		// trace("batchStr.length = " + batchStr.length);
		// trace("serializedStr.length = " + serializedStr.length);

		// trace(batchStr);
		// trace(serializedStr);

		messages = [];
		batchSize = 0;
		for (connection in connections) {
			connection.send(batchStr);
		}
	}
}
