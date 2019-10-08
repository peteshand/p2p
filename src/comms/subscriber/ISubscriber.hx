package comms.subscriber;

import comms.connection.IConnection;

interface ISubscriber {
	function addConnection(connection:IConnection):Void;
}
