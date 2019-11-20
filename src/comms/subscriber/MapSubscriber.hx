package comms.subscriber;

import notifier.MapNotifier3;
import comms.connection.IConnection;

@:access(comms.Comms)
class MapSubscriber<K, T> implements ISubscriber {
	var map:MapNotifier3<K, T>;
	var id:String;
	var comms:Comms;

	public function new(comms:Comms, map:MapNotifier3<K, T>, id:String) {
		this.comms = comms;
		this.map = map;
		this.id = id;

		for (connection in comms.connections) {
			addConnection(connection);
		}
	}

	public function addConnection(connection:IConnection) {
		connection.on(id + ",add", onAdd);
		connection.on(id + ",remove", onRemove);
	}

	function onAdd(payload:{key:K, value:T}, connectionIndex:Int) {
		// comms.PAUSE_BROADCAST = true;
		comms.received_messages.set(id + ",add", payload);
		map.set(payload.key, payload.value);
		// comms.PAUSE_BROADCAST = false;
	}

	function onRemove(payload:{key:K}, connectionIndex:Int) {
		// comms.PAUSE_BROADCAST = true;
		comms.received_messages.set(id + ",remove", "");
		map.removeItem(payload.key);
		// comms.PAUSE_BROADCAST = false;
	}
}
