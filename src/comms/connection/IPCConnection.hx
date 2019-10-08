package comms.connection;

import comms.CommsMessage.CommsBatch;
import electron.Process;
import electron.main.App;
import electron.main.BrowserWindow;
import electron.renderer.IpcRenderer;
import electron.main.IpcMain;
import comms.Comms;
import comms.connection.*;

@:access(comms.Comms)
class IPCConnection implements IConnection {
	static var browserWindows:Array<BrowserWindow> = [];
	static var webviews:Array<Webview> = [];
	static var isRenderer:Null<Bool> = null;

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
		IPCConnection.init();
		if (isRenderer) {
			IpcRenderer.on("ipc", checkCallbacks);
		} else {
			IpcMain.on("ipc", checkCallbacks);
		}
	}

	function checkCallbacks(event:Dynamic, batch:CommsBatch) {
		if (batch.senderId == Comms.instanceId) {
			// from self
			return;
		}
		for (message in batch.messages) {
			for (listener in listeners) {
				if (listener.id == message.id) {
					listener.callback(message.payload);
				}
			}
		}
	}

	public function send(batch:CommsBatch):Void {
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

	public function on(id:String, callback:(payload:Dynamic) -> Void):Void {
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
	callback:(payload:Dynamic) -> Void
}
