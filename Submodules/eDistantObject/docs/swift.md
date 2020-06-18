# Swift Support

eDistantObject supports Swift as Swift is fundamentally interoperable with
Objective-C. More details in [Apple doc around
MixAndMatch](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).
However, pure Swift calls are statically linked, therefore, invocations are not
through the Objective-C runtime. There are three different scenarios when
working with Swift.

## 1. Swift calling methods in Objective-C

This works naturally when importing Objective-C headers as Swift will invoke
those methods already in an Objective-C manner and trigger the runtime to
forward invocations. As is usual with Swift, these method definitions must be exposed in a bridging header.

## 2. Objective-C calling methods in Swift

The methods need to be annotated with `@objc` so that it can be exported to
Objective-C and is visible. Once the invocation is fired in Objective-C, it will
properly be forwarded to the remote site.

The above two scenarios should work as long as the methods are tagged with
@objc.

## 3. Swift calling methods in Swift

In the Objective-C case, the compiler needs to see the header in order to know how
to run your code. However, there is no header in Swift. The workaround is to
define a protocol, to serve as a header, and then expose the object to work
with as a protocol.

For example:

*   The common dependency that defines the protocols

```swift
//  In Swift
@objc
public protocol RemoteInterface {
  func remoteFoo() -> Bar
}

@objc
public protocol RootObjectExtension {
  func remoteInterface() -> RemoteInterface
}
```

*   The service side implementation

```swift
class ActualImplementation: RemoteInterface {
  func remoteFoo() -> Bar {
    // Your actual implementation.
  }
}

@objc
extension RootObject: RootObjectExtension {
  // The client calling this method to require the remote object.
  func remoteInterface() -> RemoteInterface {
    return ActualImplementation()
  }
}
```

*   The client side retrieving the remote objects

```swift
let rootObject = EDOClientService<RootObjectExtension>.rootObject(withPort: portNumber)
let remote = rootObject.remoteInterface()
remote.remoteFoo()
```

In the code above, `RootObject` is defined and implemented on the server side.
This will then be used as an entry point to return the protocol
`RootObjectExtension`.

Working example is shown
[here](../Service/Tests/FunctionalTests/EDOSwiftUITest.swift).

Alternatively, you can extend the root object directly. It is up to the user how
they want to organize their code structure.

### The block closure

The block is also supported but it may confuse the compiler and the runtime as the calling convention can be different. Adding @escaping to let both the runtime and the compiler to know how to handle the block scope. [For example](../Service/Tests/TestsBundle/EDOTestSwiftProtocol.swift).
