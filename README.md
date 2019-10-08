## P2P

WARNING: Not production ready

The aim of this library is to offer a simple way to setup a p2p communication layer.

This library is currently in the early stages of development, therefore I wouldn't recommend using this for anything in production.

### Goal

The goal of this library is to create a standardize Peer to Peer API that can be layered on top of multiple types of communication protocols.

### Installing a communication layer
```
P2P.install(ICommunication);
```


### [Notifier](https://github.com/peteshand/notifier) Binding API

As the name suggest notifier binding allows you to bind a notifier to a string Id and then have it synchronise over the p2p network when it's value is changed.

Listen for changes with Id 'test' and assign value to `notifier`

```
P2P.bind(notifier, 'test', P2P.IN);
```

Listen for value changes on `notifier` and when it updates broascast it's value over the network with Id 'test'.

```
P2P.bind(notifier, 'test', P2P.OUT);
```

Both listen and broadcast

```
P2P.bind(notifier, 'test', P2P.IO);
```

.....

```
notifier1.add((value:Int) -> {
	trace("value = " + value);
}
var notifier1:Notifier<Int> = new Notifier<Int>(0);
P2P.addSubscriber(notifier1, 'test');
```

```
var notifier1:Notifier<Int> = new Notifier<Int>(0);
P2P.addBroadcast(notifier1, 'test');

notifier1.value = 2;
```

### Basic listener and sender API
```
P2P.listen("messageId", (payload:{foo:String}) -> {
	trace("payload.foo = " + payload.foo);
});
```

```
var payload = {
	foo:"bar"
};
P2P.send("messageId", payload);
```

