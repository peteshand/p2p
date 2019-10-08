package comms.subscriber;

import notifier.MapNotifier3;
import comms.connection.IConnection;

@:access(comms.Comms)
class MapSubscriber<T> implements ISubscriber {
	var map:MapNotifier3<String, T>;
	var id:String;

	public function new(map:MapNotifier3<String, T>, id:String) {
		this.map = map;
		this.id = id;

		for (connection in Comms.connections) {
			addConnection(connection);
		}
	}

	public function addConnection(connection:IConnection) {
		connection.on(id + ",add", onAdd);
		connection.on(id + ",remove", onRemove);
	}

	function onAdd(payload:{key:String, value:T}) {
		map.set(payload.key, payload.value);
	}

	function onRemove(payload:{key:String}) {
		map.removeItem(payload.key);
	}
}
