package comms.broadcaster;

import notifier.MapNotifier;

@:access(comms.Comms)
class MapBroadcaster<K, T> implements IBroadcaster {
	var map:MapNotifier<K, T>;
	var comms:Comms;

	public var id:String;
	public var value(get, null):Dynamic;

	public function new(comms:Comms, map:MapNotifier<K, T>, id:String) {
		this.comms = comms;
		this.id = id;
		this.map = map;

		map.onAdd.add(onAdd);
		map.onChange.add(onChange);
		map.onRemove.add(onRemove);
	}

	function onAdd(key:K, value:T) {
		send(id + ",add", key, value);
	}

	function onChange(key:K, value:T) {
		send(id + ",add", key, value);
	}

	function onRemove(key:K) {
		send(id + ",remove", key, null);
	}

	function send(commsKey:String, key:K, value:T) {
		// if (!comms.PAUSE_BROADCAST) {
		comms.send(commsKey, {key: key, value: value}, false);
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

	function get_value():Map<K, T> {
		return map.value;
	}
}
