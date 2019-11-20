package comms;

typedef CommsBatch = {
	senderIds:Array<Float>,
	messages:Array<CommsMessage>
}

typedef CommsMessage = {
	id:String,
	payload:Dynamic
}
