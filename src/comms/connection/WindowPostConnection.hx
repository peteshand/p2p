package comms.connection;

#if html5
import js.Browser;
import js.html.Window;
import comms.CommsMessage.CommsBatch;
import comms.*;
import haxe.Json;
import signals.Signal1;

@:access(comms.Comms)
class WindowPostConnection implements IConnection {
	public var connectionIndex:Int;
	public var comms:Comms;
	public var onBatch = new Signal1<CommsBatch>();

	static var otherWindows:Array<Window> = [];

	public static function addWindow(window:Window) {
		if (window == null)
			return;
		if (window == js.Browser.window)
			return;
		for (otherWindow in otherWindows) {
			if (otherWindow == window)
				return;
		}
		otherWindows.push(window);
	}

	public static function removeWindow(window:Window) {
		if (window == null)
			return;
		var i:Int = otherWindows.length - 1;
		while (i >= 0) {
			if (otherWindows[i] == window) {
				otherWindows.splice(i, 1);
			}
			i--;
		}
	}

	public function new() {
		// connectionIndex = Comms.CONNECTION_COUNT++;
		addWindow(Browser.window.parent);
		addWindow(Browser.window.opener);
	}

	public function send(batch:String):Bool {
		trace("SEND: " + batch);
		if (otherWindows.length == 0) {
			trace("No other windows open");
			return true;
		}
		for (otherWindow in otherWindows) {
			// otherWindow.postMessage(batch, "*");
		}
		return true;
	}

	public function on(id:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void):Void {
		Browser.window.addEventListener('message', (event) -> {
			trace("RECEIVE: " + event.data);
			var batch:CommsBatch = Json.parse(event.data);
			onBatch.dispatch(batch);
			for (message in batch.messages) {
				var payload:CommsPayload = Json.parse(message.payload);
				if (message.id == id || id == "*") {
					// if (returnParsedPayload)
					callback(payload.value, connectionIndex);
					// else
					// callback(message);
				}
			}
		}, false);
	}

	public function close():Void {
		// need to implement
	}
}
#end
