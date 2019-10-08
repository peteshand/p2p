package comms;

abstract MulticastAddr(String) to String {
	public static var DEFAULT_ADDRESS:String = "233.255.255.255";

	// VALID RANGE
	// 224.0.0.0 to 239.255.255.255
	// 3758096384 - 4026531839

	public function new(value:String) {
		this = validate(value);
	}

	@:from
	static public function fromString(s:String) {
		return new MulticastAddr(s);
	}

	static inline function validate(s:String) {
		if (s == null)
			return DEFAULT_ADDRESS;
		var regex = ~/2(?:2[4-9]|3\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]\d?|0)){3}$/i;
		if (regex.match(s)) {
			return s;
		} else {
			trace(s + " is NOT valid, using " + DEFAULT_ADDRESS + " instead");
			return DEFAULT_ADDRESS;
		}
	}
}
