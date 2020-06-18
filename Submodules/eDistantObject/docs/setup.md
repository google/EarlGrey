# eDO Setup Guide

## How to build your project with eDO

If you are using [Bazel](https://bazel.build/), normally, you will have at
least two BUILD files

<!--zippy-->

BUILD for the `Host` and `YourClass`

```build

# The Host binary that starts the EDOHostService.
objc_library(
    name = "Host",
    srcs = [
      "Host.m",
    ],
    deps = [
      ":YourClass",  # Your actual class implementation
      "//third_party/objective_c/eDistantObject",
    ]
)

# YourClass library
objc_library(
    name = "YourClass",
    srcs = ["YourClass.m"],
    deps = [":Headers"],
)

# Expose YourClass headers as a separate target so the client can use it
# without linking the binary.
objc_library(
    name = "Headers",
    hdrs = ["YourClass.h"],
    # If there is any deps, make sure it will not introduce any binary unit that
    # is going to link with the client.
)

```

<!--endzippy-->

<!--zippy-->

BUILD for the `Client` to use `YourClass`

```build
# The client that uses YourClass from a different process.
objc_library(
    name = "Client",
    srcs = ["Client.m"],
    deps = [
        ":Headers",
        "//third_party/objective_c/eDistantObject",
    ]
)

```

<!--endzippy-->

This is an example using [Bazel](https://bazel.build/). For other build tools,
the rule is to import headers and implementations in one process, while import
only headers in the other process who makes remote invocations using methods
defined in the headers.

## Where to write code

When you need to write code that will jump between two processes, it can be
confusing to say in which process the actual implementation and its stub/proxy
call should be.

For example, you already have an API in the host process to get the element from
an internal array, and you need another API to do some complicated logic to
process the number in client process.
In this case, since only the host process has access to the internal data, we
should keep the old API in host process and let the client process hold a distant
object of it.

```objectivec
// In the host process

@implementation HostDistantObject {
  NSArray<NSNumber *>* _myArray;
}

- (NSNumber *)getNumber:(NSInteger *)index {
  return [_myArray objectAtIndex:index];
}

@end
```

```objectivec
// In the client process
- (void)processFirstNumber {
    NSNumber *firstNumber = [HostDistantObject.sharedInstance getNumber:0];
    // Do some complicated logic with the remote object firstNumber...
}
```

In the example above, the client process holds a remote instance of
`HostDistantObject`. And the API `getNumber:` actually runs in host process.
Then the client process receives another remote instance of `NSNumber` and
can do whatever logic on it.
