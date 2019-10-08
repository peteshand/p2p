package comms;

typedef CommsMessage = {
	// senderId:Float,
	id:String,
	payload:String,
	// ?remoteHost:String,
	// ?remotePort:Int
}

typedef CommsBatch = {
	senderId:Float,
	messages:Array<CommsMessage>
}
