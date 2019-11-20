package comms.broadcaster;

import notifier.MapNotifier3;

@:access(comms.Comms)
class MapBroadcaster<T> implements IBroadcaster {
	var map:MapNotifier3<String, T>;
	var comms:Comms;

	public var id:String;
	public var value(get, null):Dynamic;

	public function new(comms:Comms, map:MapNotifier3<String, T>, id:String) {
		this.comms = comms;
		this.id = id;
		this.map = map;

		map.onAdd.add(onAdd);
		map.onChange.add(onChange);
		map.onRemove.add(onRemove);
	}

	function onAdd(key:String, value:T) {
		send(id + ",add", key, value);
	}

	function onChange(key:String, value:T) {
		send(id + ",add", key, value);
	}

	function onRemove(key:String) {
		send(id + ",remove", key, null);
	}

	function send(commsKey:String, key:String, value:T) {
		// if (!comms.PAUSE_BROADCAST) {
		comms.send(commsKey, {key: key, value: value});
		// }
		// for (connection in comms.connections) {
		//	connection.send(commsKey, {key: key, value: value});
		// }
	}

	public function setCurrentValue():Void {
		for (item in map.keyValueIterator()) {
			send(id + ",add", item.key, item.value);
		}
	}

	function get_value():Dynamic {
		return map.value;
	}
}
