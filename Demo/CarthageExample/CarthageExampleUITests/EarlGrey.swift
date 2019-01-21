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
    _ reason: @autoclosure () -> String = "Assert on expression Failed"
    ) {
    GREYAssert(expression(), reason, "Expected expression to be true")
}

public func GREYAssertTrue(
    _ expression: @autoclosure () -> Bool,
    _ reason: @autoclosure () -> String = "Expression is not true"
    ) {
    GREYAssert(expression(), reason, "Expected the boolean expression to be true")
}

public func GREYAssertFalse(
    _ expression: @autoclosure () -> Bool,
    _ reason: @autoclosure () -> String = "Expression is not false"
    ) {
    GREYAssert(!expression(), reason, "Expected the boolean expression to be false")
}

public func GREYAssertNotNil(
    _ expression: @autoclosure ()-> Any?,
    _ reason: @autoclosure () -> String = "Expression is nil"
    ) {
    GREYAssert(expression() != nil, reason, "Expected expression to be not nil")
}

public func GREYAssertNil(
    _ expression: @autoclosure () -> Any?,
    _ reason: @autoclosure () -> String = "Expression is not nil"
    ) {
    GREYAssert(expression() == nil, reason, "Expected expression to be nil")
}

public func GREYAssertEqual<T: Equatable>(
    _ left: @autoclosure () -> T?,
    _ right: @autoclosure () -> T?,
    _ reason: @autoclosure () -> String = "Expression's compared values are not equal"
    ) {
    GREYAssert(left() == right(), reason, "Expected left term to be equal to right term")
}

public func GREYAssertNotEqual<T: Equatable>(
    _ left: @autoclosure () -> T?,
    _ right: @autoclosure () -> T?,
    _ reason: @autoclosure () -> String  = "Expression's compared values are equal"
    ) {
    GREYAssert(
        left() != right(),
        reason,
        "Expected left term to not equal the right term")
}

public func GREYFail(
    _ reason: @autoclosure () -> String = "Generic EarlGrey exception thrown.",
    _ details: @autoclosure () -> String = ""
    ) {
    EarlGrey.handle(
        GREYFrameworkException(
            name: kGREYAssertionFailedException,
            reason: reason()),
        details: details())
}

private func GREYAssert(
    _ expression: @autoclosure () -> Bool,
    _ reason: @autoclosure () -> String = "Generic EarlGrey Assertion Failed.",
    _ details: @autoclosure () -> String
    ) {
    GREYWaitUntilIdle()
    if !expression() {
        EarlGrey.handle(
            GREYFrameworkException(
                name: kGREYAssertionFailedException,
                reason: reason()),
            details: details())
    }
}

private func GREYWaitUntilIdle() {
    GREYUIThreadExecutor.sharedInstance().drainUntilIdle()
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
    
    public static func handle(
        _ exception: GREYFrameworkException,
        details: String,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
            .handle(exception, details: details)
    }
    
    public static func setFailureHandler(
        _ handler: GREYFailureHandler?,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
            .setFailureHandler(handler)
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
