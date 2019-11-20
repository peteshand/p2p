package comms.subscriber;

import notifier.Notifier;
import comms.connection.IConnection;

@:access(comms.Comms)
class NotifierSubscriber<T> implements ISubscriber {
	var notifier:Notifier<T>;
	var id:String;
	var comms:Comms;

	public function new(comms:Comms, notifier:Notifier<T>, id:String) {
		this.comms = comms;
		this.notifier = notifier;
		this.id = id;

		for (connection in comms.connections) {
			addConnection(connection);
		}
	}

	public function addConnection(connection:IConnection) {
		connection.on(id, onMessage);
	}

	function onMessage(payload:T, connectionIndex:Int) {
		// comms.PAUSE_BROADCAST = true;
		#if (debugComms && html5)
		comms.received_messages.set(id, payload);
		#end
		notifier.value = payload;
		// comms.PAUSE_BROADCAST = false;
	}
}
