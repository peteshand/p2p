package comms;

import delay.Delay;
import comms.broadcaster.*;
import comms.subscriber.*;
import comms.connection.IConnection;
import notifier.Notifier;
import notifier.MapNotifier3;
import comms.notifier.*;
import haxe.Json;
import time.EnterFrame;

class Comms {
	static var instanceId:Null<Float>;
	static public var broadcasters = new Map<String, IBroadcaster>();
	static public var subscribers = new Map<String, ISubscriber>();
	static var connections:Array<IConnection> = [];
	static var listeningToConnect:Bool = false;

	static var messages:Array<CommsMessage> = [];

	// @:isVar public static var selfListen(default, set):Bool = false;

	public function new() {}

	public static function install(connection:IConnection) {
		if (instanceId == null) {
			instanceId = Math.floor(Math.random() * 100000000000);
		}
		Comms.connections.push(connection);

		for (subscriber in subscribers) {
			subscriber.addConnection(connection);
		}

		Delay.killDelay(sendConnectMessage);
		Delay.byFrames(30, sendConnectMessage);
	}

	static function sendConnectMessage() {
		if (!listeningToConnect) {
			listeningToConnect = true;
			on("connect", (value:Dynamic = null) -> {
				for (broadcaster in broadcasters) {
					broadcaster.setCurrentValue();
				}
			});
		}
		send("connect");
		EnterFrame.add(tick);
	}

	public static function addBroadcast<T>(id:String, ?map:MapNotifier3<String, T>, ?notifier:Notifier<T>):Void {
		if (notifier != null)
			broadcasters.set(id, new NotifierBroadcaster<T>(notifier, id));
		if (map != null)
			broadcasters.set(id, new MapBroadcaster<T>(map, id));
	}

	public static function addSubscriber<T>(id:String, ?map:MapNotifier3<String, T>, ?notifier:Notifier<T>):Void {
		if (notifier != null)
			subscribers.set(id, new NotifierSubscriber<T>(notifier, id));
		if (map != null)
			subscribers.set(id, new MapSubscriber<T>(map, id));
	}

	public static function removeBroadcast(notifier:Notifier<Dynamic>, id:String):Void {}

	public static function removeSubscriber(notifier:Notifier<Dynamic>, id:String):Void {}

	public static function send(id:String, payload:Dynamic = ""):Void {
		var message:CommsMessage = {
			id: id,
			payload: Json.stringify({value: payload})
		}
		messages.push(message);
	}

	public static function on(id:String, callback:(payload:Dynamic) -> Void):Void {
		for (connection in connections) {
			connection.on(id, callback);
		}
	}

	public static function relay<T>(id:String):Void {
		Comms.on(id, (payload) -> {
			Comms.send(id, payload);
		});
	}

	static function tick() {
		for (connection in connections) {
			connection.send({
				senderId: Comms.instanceId,
				messages: messages
			});
		}
		messages = [];
	}
}
