package comms.connection;

import haxe.Json;
import comms.CommsMessage.CommsBatch;
import electron.Process;
import electron.main.App;
import electron.main.BrowserWindow;
import electron.renderer.IpcRenderer;
import electron.main.IpcMain;
import comms.Comms;
import comms.connection.*;
import signals.Signal1;

@:access(comms.Comms)
class IPCConnection implements IConnection {
	public var connectionIndex:Int;
	public var comms:Comms;

	static var browserWindows:Array<BrowserWindow> = [];
	static var webviews:Array<Webview> = [];
	static var isRenderer:Null<Bool> = null;

	public var onBatch = new Signal1<CommsBatch>();

	static function init() {
		isRenderer = (App == null);
	}

	public static function addWindow(window:BrowserWindow) {
		IPCConnection.init();
		if (window == null || isRenderer == true)
			return;
		for (browserWindow in browserWindows) {
			if (browserWindow == window)
				return;
		}
		browserWindows.push(window);
	}

	public static function removeWindow(window:BrowserWindow) {
		IPCConnection.init();
		if (window == null || isRenderer == true)
			return;
		var i:Int = browserWindows.length - 1;
		while (i >= 0) {
			if (browserWindows[i] == window) {
				browserWindows.splice(i, 1);
			}
			i--;
		}
	}

	public static function addWebview(webview:Webview) {
		IPCConnection.init();
		if (webview == null || isRenderer == false)
			return;
		for (w in webviews) {
			if (w == webview)
				return;
		}
		webviews.push(webview);
	}

	public static function removeWebview(webview:Webview) {
		IPCConnection.init();
		if (webview == null || isRenderer == false)
			return;
		var i:Int = webviews.length - 1;
		while (i >= 0) {
			if (webviews[i] == webview) {
				webviews.splice(i, 1);
			}
			i--;
		}
	}

	var listeners:Array<CallbackWrapper> = [];

	public function new() {
		// connectionIndex = Comms.CONNECTION_COUNT++;
		IPCConnection.init();
		if (isRenderer) {
			IpcRenderer.on("ipc", checkCallbacks);
		} else {
			IpcMain.on("ipc", checkCallbacks);
		}
		onBatch.add(onBatchReceived);
	}

	function checkCallbacks(event:Dynamic, batchStr:String) {
		var batch:CommsBatch = null;
		try {
			batch = Json.parse(batchStr);
		} catch (e:Dynamic) {
			trace(e);
			return;
		}
		if (batch == null)
			return;
		if (batch.messages == null)
			return;
		if (batch.messages.length == 0)
			return;

		if (batch.senderIds != null && batch.senderIds.indexOf(comms.instanceId) != -1) {
			// from self
			return;
		}
		onBatch.dispatch(batch);
	}

	function onBatchReceived(batch:CommsBatch) {
		for (message in batch.messages) {
			if (message.id == "")
				continue;
			var payload:CommsPayload = null;
			try {
				payload = Json.parse(message.payload);
			} catch (e:Dynamic) {
				trace("Payload Parsing Error: " + e);
				continue;
			}
			for (listener in listeners) {
				if (listener.id == message.id) {
					// listener.callback(message.payload, connectionIndex);
					listener.callback(payload.value, connectionIndex);
				}
			}
		}
	}

	public function send(batch:String):Void {
		if (isRenderer) {
			IpcRenderer.send("ipc", batch);
			for (webview in webviews) {
				try {
					webview.send("ipc", batch);
				} catch (e:Dynamic) {}
			}
		} else {
			for (browserWindow in browserWindows) {
				browserWindow.webContents.send("ipc", batch);
			}
		}
	}

	public function on(id:String, callback:(payload:Dynamic, connectionIndex:Int) -> Void):Void {
		listeners.push({id: id, callback: callback});
	}

	public function close():Void {
		if (isRenderer) {
			IpcRenderer.removeAllListeners("ipc");
		} else {
			IpcMain.removeAllListeners("ipc");
		}
	}
}

typedef Webview = {
	var document:{readyState:String};
	function send(id:String, payload:Dynamic):Void;
}

typedef CallbackWrapper = {
	id:String,
	callback:(payload:Dynamic, connectionIndex:Int) -> Void
}
