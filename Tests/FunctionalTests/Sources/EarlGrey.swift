//
// Copyright 2016 Google Inc.
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

func grey_replaceText(text: String) -> GREYAction {
  return GREYActionBlock.actionWithName("Replace text \"\(text)\"", constraints: grey_not(grey_systemAlertViewShown()),
                                        performBlock: { element, errorOrNil in
                                          guard let textfield = element as? UITextField else {
                                            let reasonAndDetails: String = "grey_replaceText failed. Element is not a UITextField"
                                            let userInfo: [NSObject : AnyObject] = [NSLocalizedDescriptionKey: reasonAndDetails]

                                            errorOrNil.memory = NSError(domain: kGREYInteractionErrorDomain,
                                              code: GREYInteractionErrorCode.ActionFailedErrorCode.rawValue,
                                              userInfo: userInfo)
                                            return false
                                          }
                                          
                                          textfield.text = text
                                          return true
  })
}

func grey_allOfMatchers(args: AnyObject...) -> GREYMatcher! {
  return GREYAllOf.init(matchers: args)
}

func grey_anyOfMatchers(args: AnyObject...) -> GREYMatcher! {
  return GREYAnyOf.init(matchers: args)
}

public func EarlGrey() -> EarlGreyImpl! {
  return EarlGreyImpl.invokedFromFile(#file, lineNumber: #line)
}

public func GREYAssert(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(expression, reason, details: "Expected expression to be true")
}

public func GREYAssertTrue(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(expression().boolValue,
    reason,
    details: "Expected the boolean expression to be true")
}

public func GREYAssertFalse(@autoclosure expression: () -> BooleanType, reason: String) {
  GREYAssert(!expression().boolValue,
    reason,
    details: "Expected the boolean expression to be true")
}

public func GREYAssertNotNil(@autoclosure expression: () -> Any?, reason: String) {
  GREYAssert(expression() != nil, reason, details: "Expected expression to be not nil")
}

public func GREYAssertNil(@autoclosure expression: () -> Any?, reason: String) {
  GREYAssert(expression() == nil, reason, details: "Expected expression to be nil")
}

public func GREYAssertEqual<T : Equatable>(@autoclosure left: () -> T?,
    @autoclosure _ right: () -> T?, reason: String) {
  GREYAssert(left() == right(), reason, details: "Expeted left term to be equal to right term")
}

public func GREYFail(reason: String) {
  greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
    reason: reason),
    details: "")
}

public func GREYFail(reason: String, details: String) {
  greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
    reason: reason),
    details: details)
}

private func GREYAssert(@autoclosure expression: () -> BooleanType,
                        _ reason: String, details: String) {
  GREYSetCurrentAsFailable()
  if !expression().boolValue {
    greyFailureHandler.handleException(GREYFrameworkException(name: kGREYAssertionFailedException,
      reason: reason),
      details: details)
  }
}

private func GREYSetCurrentAsFailable() {
  let greyFailureHandlerSelector =
      #selector(GREYFailureHandler.setInvocationFile(_:andInvocationLine:))
  if greyFailureHandler.respondsToSelector(greyFailureHandlerSelector) {
    greyFailureHandler.setInvocationFile!(#file, andInvocationLine: #line)
  }
}
