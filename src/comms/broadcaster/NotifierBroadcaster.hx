package comms.broadcaster;

import notifier.Notifier;

@:access(comms.Comms)
class NotifierBroadcaster<T> implements IBroadcaster {
	var notifier:Notifier<T>;
	var comms:Comms;

	public var id:String;
	public var value(get, null):Dynamic;

	var guards:Array<(id:String, value:T) -> Bool> = [];

	public function new(comms:Comms, notifier:Notifier<T>, id:String) {
		this.comms = comms;
		this.id = id;
		this.notifier = notifier;

		notifier.add(setCurrentValue);
	}

	public function setCurrentValue():Void {
		for (guard in guards) {
			if (!guard(id, notifier.value))
				return;
		}
		// if (!comms.PAUSE_BROADCAST) {
		comms.send(id, notifier.value);
		// }
	}

	public function addGuard(guard:(id:Dynamic, value:Dynamic) -> Bool) {
		guards.push(guard);
	}

	function get_value():Dynamic {
		return notifier.value;
	}
}
