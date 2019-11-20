package comms.broadcaster;

import notifier.Notifier;

@:access(comms.Comms)
class NotifierBroadcaster<T> implements IBroadcaster {
	var notifier:Notifier<T>;
	var comms:Comms;

	public var id:String;
	public var value(get, null):Dynamic;

	public function new(comms:Comms, notifier:Notifier<T>, id:String) {
		this.comms = comms;
		this.id = id;
		this.notifier = notifier;

		notifier.add(setCurrentValue);
	}

	public function setCurrentValue():Void {
		// if (!comms.PAUSE_BROADCAST) {
		comms.send(id, notifier.value);
		// }
	}

	function get_value():Dynamic {
		return notifier.value;
	}
}
