package comms.connection;

import comms.CommsMessage.CommsBatch;
import js.Browser;
import haxe.Json;
import js.html.Window;
import comms.*;

class WindowPostConnection implements IConnection {
	static var otherWindows:Array<Window> = [];

	public static function addWindow(window:Window) {
		if (window == null)
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
		addWindow(Browser.window.parent);
		addWindow(Browser.window.opener);
	}

	public function send(batch:CommsBatch):Void {
		if (otherWindows.length == 0) {
			trace("No other windows open");
			return;
		}
		for (otherWindow in otherWindows) {
			otherWindow.postMessage(batch, "*");
		}
	}

	public function on(id:String, callback:(payload:Dynamic) -> Void):Void {
		Browser.window.addEventListener('message', (event) -> {
			var batch:CommsBatch = event.data;
			for (message in batch.messages) {
				if (message.id == id || id == "*") {
					// if (returnParsedPayload)
					callback(Json.parse(message.payload));
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
