//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
public func GREYAssert(
  _ expression: @autoclosure () -> Bool,
  _ reason: @autoclosure () -> String = "Assert on expression Failed",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(expression(), reason(), "Expected expression to be true", file: file, line: line)
}

public func GREYAssertTrue(
  _ expression: @autoclosure () -> Bool,
  _ reason: @autoclosure () -> String = "Expression is not true",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(
    expression(), reason(), "Expected the boolean expression to be true", file: file, line: line)
}

public func GREYAssertFalse(
  _ expression: @autoclosure () -> Bool,
  _ reason: @autoclosure () -> String = "Expression is not false",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(
    !expression(), reason(), "Expected the boolean expression to be false", file: file, line: line)
}

public func GREYAssertNotNil(
  _ expression: @autoclosure () -> Any?,
  _ reason: @autoclosure () -> String = "Expression is nil",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(
    expression() != nil, reason(), "Expected expression to be not nil", file: file, line: line)
}

public func GREYAssertNil(
  _ expression: @autoclosure () -> Any?,
  _ reason: @autoclosure () -> String = "Expression is not nil",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(expression() == nil, reason(), "Expected expression to be nil", file: file, line: line)
}

public func GREYAssertEqual<T: Equatable>(
  _ left: @autoclosure () -> T?,
  _ right: @autoclosure () -> T?,
  _ reason: @autoclosure () -> String = "Expression's compared values are not equal",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(
    left() == right(), reason(), "Expected left term to be equal to right term", file: file,
    line: line)
}

public func GREYAssertNotEqual<T: Equatable>(
  _ left: @autoclosure () -> T?,
  _ right: @autoclosure () -> T?,
  _ reason: @autoclosure () -> String = "Expression's compared values are equal",
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYAssert(
    left() != right(),
    reason(),
    "Expected left term to not equal the right term", file: file, line: line)
}

public func GREYFail(
  _ reason: @autoclosure () -> String = "Generic EarlGrey exception thrown.",
  _ details: @autoclosure () -> String = "",
  file: StaticString = #file,
  line: UInt = #line
) {
  EarlGrey.handle(
    GREYFrameworkException(
      name: kGREYAssertionFailedException,
      reason: reason()),
    details: details(), file: file, line: line)
}

/// Waits for the application to idle on a background queue of the test to enable thread safe calls
/// on the main thread.
///
/// - Parameters:
///   - timeoutDescription: The description to be printed if the application doesn't idle.
public func GREYWaitForAppToIdle(
  _ timeoutDescription: @autoclosure () -> String =
    "EarlGrey timed out while waiting for the app to idle.",
  file: StaticString = #file,
  line: UInt = #line
) {
  var error: NSError?
  GREYWaitForAppToIdleWithError(&error)
  if error == nil {
    return
  }
  EarlGrey.handle(
    GREYFrameworkException(
      name: kGREYTimeoutException,
      reason: timeoutDescription()),
    details: error.debugDescription, file: file, line: line)
}

/// Waits for the application to idle within a timeout on a background queue of the test to enable
/// thread safe calls on the main thread.
///
/// - Parameters:
///   - timeout: The timeout within which the application must idle.
///   - timeoutDescription: The description to be printed if the application doesn't idle.
public func GREYWaitForAppToIdle(
  _ timeout: CFTimeInterval,
  _ timeoutDescription: @autoclosure () -> String =
    "EarlGrey timed out while waiting for the app to idle within timeout: \timeout.",
  file: StaticString = #file,
  line: UInt = #line
) {
  var error: NSError?
  GREYWaitForAppToIdleWithTimeoutAndError(timeout, &error)
  if error == nil {
    return
  }
  EarlGrey.handle(
    GREYFrameworkException(
      name: kGREYTimeoutException,
      reason: timeoutDescription()),
    details: error.debugDescription, file: file, line: line)
}

private func GREYAssert(
  _ expression: @autoclosure () -> Bool,
  _ reason: @autoclosure () -> String = "Generic EarlGrey Assertion Failed.",
  _ details: @autoclosure () -> String,
  file: StaticString = #file,
  line: UInt = #line
) {
  GREYWaitForAppToIdle()
  if !expression() {
    EarlGrey.handle(
      GREYFrameworkException(
        name: kGREYAssertionFailedException,
        reason: reason()),
      details: details(),
      file: file,
      line: line)
  }
}

public func GREYRemoteClassInApp<T>(classVal: T.Type) -> T.Type {
  // T may not conform to AnyClass, e.g. it can be SomeClass.Type.Type. So we need do cast T.self to
  // AnyClass here.
  return unsafeBitCast(EarlGrey.remoteClassInApp(T.self as! AnyClass), to: T.Type.self)
}

// Allows calling `EarlGreyImpl` methods that would typically rely on the `EarlGrey` macro in
// Objective-C.
public struct EarlGrey {
  private init() {}

  public static func selectElement(
    with matcher: GREYMatcher,
    file: StaticString = #file,
    line: UInt = #line
  ) -> GREYInteraction {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .selectElement(with: matcher)
  }

  public static func rotateDevice(
    to orientation: UIDeviceOrientation,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    return try EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .rotateDevice(to: orientation)
  }

  public static func shakeDevice(
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    return try EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line).shakeDevice()
  }

  public static func handle(
    _ exception: GREYFrameworkException,
    details: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .handle(exception, details: details)
  }

  public static func dismissKeyboard(
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    try EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line).dismissKeyboard()
  }

  @available(iOS 11.0, *)
  public static func openDeepLinkURL(
    _ url: String,
    with application: XCUIApplication,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    try EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .openDeepLinkURL(url, with: application)
  }

  public static func remoteClassInApp(
    _ classVal: AnyClass,
    file: StaticString = #file,
    line: UInt = #line
  ) -> AnyClass {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .remoteClass(inApp: classVal)
  }

  public static func setHostApplicationCrashHandler(
    _ handler: GREYHostApplicationCrashHandler?,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
      .setHostApplicationCrashHandler(handler)
  }
}

extension GREYInteraction {
  @discardableResult public func assert(_ matcher: @autoclosure () -> GREYMatcher) -> Self {
    return self.__assert(with: matcher())
  }

  @discardableResult public func assert(
    _ matcher: @autoclosure () -> GREYMatcher,
    error: NSErrorPointer
  ) -> Self {
    return self.__assert(with: matcher(), error: error)
  }

  @discardableResult public func perform(_ action: GREYAction) -> Self {
    return self.__perform(action)
  }

  @discardableResult public func perform(
    _ action: GREYAction,
    error: NSErrorPointer
  ) -> Self {
    return self.__perform(action, error: error)
  }

  @discardableResult public func usingSearch(
    action: GREYAction,
    onElementWith matcher: GREYMatcher
  ) -> Self {
    return self.__usingSearch(action, onElementWith: matcher)
  }
}
