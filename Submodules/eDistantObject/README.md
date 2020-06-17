# eDistantObject

[![Apache License](https://img.shields.io/badge/license-Apache%202-lightgrey.svg?style=flat)](https://github.com/google/eDistantObject/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/google/eDistantObject.svg?branch=master)](https://travis-ci.org/google/eDistantObject)

eDistantObject (easyDistantObject or eDO) provides users an easy way to make remote invocations
between processes in Objective-C and Swift without explicitly
constructing RPC structures.

Similar to [NSDistantObject](https://developer.apple.com/reference/foundation/nsdistantobject?language=objc),
eDistantObject takes advantage of Objective-C runtime features: it behaves as a
proxy, or a puppet, in one process, and when it receives the message, it
forwards the message via the communication layer (POSIX socket) to the object in
a different process.

You can find the guideline to setup eDO and try it with your code
in [Setup Guide](docs/setup.md), and more about how eDO actually
works in [Details Doc](docs/detail.md).

## How to use

Consider a typical use case, where a Client needs to communicate with a Host.
The usage steps for eDO are broken into three main steps:

### 1.  [Host](docs/terminology.md#hostremote-process)

On the host side, an `EDOHostService` must be created so that the eDistantObject is set up.
Say this is done in a file `Host.m`. Adding the following code will setup a simple distant object.

The execution queue will hold a strong reference to the EDOHostService,
so it needs to be retained to keep the service alive. To stop
serving the root object, we can either call the invalidate API or release the queue,
which implicitly invalidates the service hosting the root object.

`FooClass` is just a placeholder. Any class can be used in this way.

```objectivec
- (void)startUp {
  // Arbitrary port number for starting the service. Ensure that this doesn't
  // conflict with any existing ports being used.
  UInt16 portNumber = 12345;

  // The root object exposed is associated with a dispatch queue, any invocation made
  // on this object will have its invocations forwarded to the host. The invocations
  // will be dispatched to the associated queue.
  FooClass *rootObject = [[FooClass alloc] init];
  // If the execution queue is released, the EDOHostService running in this
  // queue will be released as well. Users can choose their own way to
  // retain the queue.
  self.executionQueue = dispatch_queue_create("MyQueue", DISPATCH_QUEUE_SERIAL);
  [EDOHostService serviceWithPort:portNumber
                       rootObject:rootObject
                            queue:self.executionQueue];
}
```

### 2.  [Shared Header](docs/terminology.md#shared-header)

So that both the client and the host are aware of the methods available in the `FooClass`
class, the header `FooClass.h` needs to be exposed in both the host as well as the client
targets. However, any calls from the client side will be forwarded to the host, hence
`FooClass.m` will only need to be compiled and linked with the Host process.

```objectivec
# FooClass.h

@interface FooClass
- (void)method1;
@end

# FooClass.m omitted [Present only in the Host Process, containing the implementation of method1]
```

### 3.  [Client](docs/terminology.md#client-process)

In the client side, say a file `Client.m` makes a call to the distant object, `FooClass`.
For this purpose, the client will have to fetch the root distant object using `EDOClientService`.
Once this is set up, the distant object can be used as if it were a local object, with calls proxied
to the host.

```objectivec

- (void)someMethod {
  // The object, fetched remotely from the host is seen by the client to be the same as a local
  // object.
  FooClass *rootObject = [EDOClientService rootObjectWithPort:portNumber];
  [rootObject method1];
}
```

For more information please look at [Where to write code](docs/setup.md#where-to-write-code).

## Swift Support

eDO can also work on Swift although it uses features of Objective-C as long as
the object defined and used are marked to invoke in the Objective-C manner.

For Swift support you will need some extra setup. Please refer to the
[Swift Guide](docs/swift.md).

## For Contributors

Please make sure you’ve followed the guidelines in
[CONTRIBUTING.md](https://github.com/google/eDistantObject/blob/master/CONTRIBUTING.md)
before making any contributions.

### Setup eDistantObject project
  1. Clone eDistantObject repository from GitHub:

    git clone https://github.com/google/eDistantObject.git

  2. After you have cloned the eDistantObject repository, install dependencies:

    pod install

  3. Open `eDistantObject.xcworkspace` and ensure that all the targets build.
  4. You can now use `eDistantObject.xcworkspace` to make changes to the project.
