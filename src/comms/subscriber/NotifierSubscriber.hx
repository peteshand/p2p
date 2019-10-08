package comms.subscriber;

import notifier.Notifier;
import comms.connection.IConnection;

@:access(comms.Comms)
class NotifierSubscriber<T> implements ISubscriber {
	var notifier:Notifier<T>;
	var id:String;

	public function new(notifier:Notifier<T>, id:String) {
		this.notifier = notifier;
		this.id = id;

		for (connection in Comms.connections) {
			addConnection(connection);
		}
	}

	public function addConnection(connection:IConnection) {
		connection.on(id, onMessage);
	}

	function onMessage(payload:T) {
		notifier.value = payload;
	}
}
