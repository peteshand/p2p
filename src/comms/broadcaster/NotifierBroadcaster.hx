package comms.broadcaster;

import notifier.Notifier;

@:access(comms.Comms)
class NotifierBroadcaster<T> implements IBroadcaster {
	var notifier:Notifier<T>;
	var id:String;

	public function new(notifier:Notifier<T>, id:String) {
		this.id = id;
		this.notifier = notifier;

		notifier.add(setCurrentValue);
	}

	public function setCurrentValue():Void {
		Comms.send(id, notifier.value);
		// for (connection in Comms.connections) {
		//	connection.send(id, notifier.value);
		// }
	}
}
