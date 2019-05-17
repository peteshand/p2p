package p2p;

import notifier.Notifier;
import haxe.Json;

class P2P {
	static public var broadcasters = new Map<String, Broadcaster>();
	static public var subscribers = new Map<String, Subscriber>();
	static var communication:ICommunication;

	// static public var to:String;
	// static public var secondWindow:Window;

	public function new() {}

	public static function install(communication:ICommunication) {
		P2P.communication = communication;
	}

	public static function addBroadcast(notifier:Notifier<Dynamic>, id:String):Void {
		if (P2P.communication == null) {
			trace("P2P.install(...) needs to be called before you can add broadcasters");
			return;
		}
		broadcasters.set(id, new Broadcaster(notifier, id));
	}

	public static function addSubscriber(notifier:Notifier<Dynamic>, id:String):Void {
		if (P2P.communication == null) {
			trace("P2P.install(...) needs to be called before you can add subscribers");
			return;
		}
		subscribers.set(id, new Subscriber(notifier, id));
	}

	public static function removeBroadcast(notifier:Notifier<Dynamic>, id:String):Void {}

	public static function removeSubscriber(notifier:Notifier<Dynamic>, id:String):Void {}

	// static public function unbind(id:String, transmit:Bool=true, receive:Bool=true)
	// public static function send(id:String, payload:Dynamic=null):Void
	// public static function on(id:String, callback:Dynamic -> Void):Void
}

@:access(p2p.P2P)
class Broadcaster {
	var notifier:Notifier<Dynamic>;
	var id:String;

	public function new(notifier:Notifier<Dynamic>, id:String) {
		this.id = id;
		this.notifier = notifier;

		notifier.add(setCurrentValue);
	}

	public function setCurrentValue():Void {
		var message:P2PMessage = {
			id: id,
			payload: notifier.value
		}
		P2P.communication.send(message);
	}
}

@:access(p2p.P2P)
class Subscriber {
	var notifier:Notifier<Dynamic>;

	public function new(notifier:Notifier<Dynamic>, id:String) {
		this.notifier = notifier;

		P2P.communication.addListener(id, onMessage);
	}

	function onMessage(message:P2PMessage) {
		notifier.value = message.payload;
	}
}

typedef P2PMessage = {
	id:String,
	payload:Dynamic
}
