package comms;

import haxe.Json;
import comms.CommsMessage.CommsBatch;
import comms.connection.IConnection;

@:access(comms.Comms)
class Relayer {
	var comms:Comms;
	var relays = new Map<String, String>();

	static var relayed_messages = new Map<String, String>();

	public function new(comms:Comms) {
		this.comms = comms;
		#if (debugComms && html5)
		Reflect.setProperty(js.Browser.window, 'relayed_messages', relayed_messages);
		#end
	}

	public function add(id:String) {
		relays.set(id, id);
	}

	public function addConnection(connection:IConnection) {
		connection.onBatch.add((incomingBatch:CommsBatch) -> {
			var relayBatch = {
				senderIds: incomingBatch.senderIds,
				messages: []
			}
			if (relayBatch.senderIds == null) {
				relayBatch.senderIds = [comms.instanceId];
			} else {
				relayBatch.senderIds.push(comms.instanceId);
			}
			for (message in incomingBatch.messages) {
				if (relays.exists(message.id)) {
					#if (debugComms && html5)
					relayed_messages.set(message.id, message.payload);
					#end
					relayBatch.messages.push(message);
				}
			}
			if (relayBatch.messages.length == 0) {
				return;
			}
			var strBatch:String = Json.stringify(relayBatch);
			for (i in 0...comms.connections.length) {
				if (connection != comms.connections[i]) {
					comms.connections[i].send(strBatch);
				}
			}
		});
	}
}
