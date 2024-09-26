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

#import "GREYElementInteractionProxy.h"

#include <XCTest/XCTest.h>
#include <stdatomic.h>

#import "GREYAction.h"
#import "GREYElementInteraction.h"
#import "GREYHostBackgroundDistantObject+GREYApp.h"
#import "GREYThrowDefines.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYDefines.h"
#import "GREYElementInteractionErrorHandler.h"
#import "GREYRemoteExecutor.h"
#import "GREYXCTestAction.h"
#import "GREYXCTestActions.h"

@implementation GREYElementInteractionProxy {
  /** App-side interaction instance. */
  GREYElementInteraction *_remoteElementInteraction;
}

@dynamic dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  GREYThrowOnNilParameter(elementMatcher);

  self = [super init];
  if (self) {
    _remoteElementInteraction =
        [GREYHostBackgroundDistantObject.sharedInstance interactionWithMatcher:elementMatcher];
  }
  return self;
}

- (id<GREYInteraction>)performAction:(id<GREYAction>)action {
  return [self performAction:action error:nil];
}

/**
 * Check if any error from perform action needs to be overwritten to success. Example: when a tap
 * action fails on iOS 18 due to incompatibility, try to tap at the offset in XCUIElement.
 *
 * @param action Grey action to be performed.
 * @param interactionError Error thrown from EarlGrey when attempting the action, this contains the
 * details to be used to perform the XCUITest action.
 */
- (void)performXCUIActionWithGreyAction:(id<GREYAction>)action error:(GREYError *)interactionError {
  if (iOS18_OR_ABOVE()) {
    id<GREYXCTestAction> xctestAction = [GREYXCTestActions XCTestActionForGREYAction:action];
    NSAssert(xctestAction != nil, @"Unsupported XCUIAction: %@", NSStringFromClass([action class]));
    id element = interactionError.userInfo[kErrorUserInfoElementReferenceKey];
    NSAssert(element != nil, @"Can't perform XCUIAction on nil element: %@", interactionError);
    [xctestAction performOnElement:element];
  }
}

- (id<GREYInteraction>)performAction:(id<GREYAction>)action
                               error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(action, @"Action can't be nil.");
  __block __strong GREYError *interactionError = nil;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    [self->_remoteElementInteraction performAction:action error:&interactionError];
  });
  // Perform action might be interrupted by unsupported action error. For that situation we need to
  // use XCUIElement to perform the action. We need to exit the perform queue early by throwing an
  // error to avoid timing issues such as having nil reference to XCUIElement.

  if (interactionError) {
    if (interactionError.code == kGREYInteractionResponderNotSupportedErrorCode) {
      [self performXCUIActionWithGreyAction:action error:interactionError];
    } else {
      GREYHandleInteractionError(interactionError, errorOrNil);
    }
  }

  return self;
}

- (void)performAction:(id<GREYAction>)action
    completionHandler:(void (^)(id<GREYInteraction>, NSError *))completionHandler {
  __block __strong GREYError *interactionError = nil;
  GREYExecuteAsyncBlockInBackgroundQueue(
      ^{
        [self->_remoteElementInteraction performAction:action error:&interactionError];
      },
      ^{
        if (interactionError.code == kGREYInteractionResponderNotSupportedErrorCode) {
          [self performXCUIActionWithGreyAction:action error:interactionError];
        }
        completionHandler(self, interactionError);
      });
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion
                        error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(assertion, @"Assertion can't be nil.");
  __block __strong GREYError *interactionError = nil;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    [self->_remoteElementInteraction assert:assertion error:&interactionError];
  });
  GREYHandleInteractionError(interactionError, errorOrNil);
  return self;
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher
                                   error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(matcher, @"Matcher can't be nil.");
  __block __strong GREYError *interactionError = nil;
  GREYExecuteSyncBlockInBackgroundQueue(^{
    [self->_remoteElementInteraction assertWithMatcher:matcher error:&interactionError];
  });
  GREYHandleInteractionError(interactionError, errorOrNil);
  return self;
}

- (void)assertWithMatcher:(id<GREYMatcher>)matcher
        completionHandler:(void (^)(id<GREYInteraction>, NSError *))completionHandler {
  __block __strong GREYError *interactionError = nil;
  GREYExecuteAsyncBlockInBackgroundQueue(
      ^{
        [self->_remoteElementInteraction assertWithMatcher:matcher error:&interactionError];
      },
      ^{
        completionHandler(self, interactionError);
      });
}

- (id<GREYInteraction>)inRoot:(id<GREYMatcher>)rootMatcher {
  GREYThrowOnNilParameterWithMessage(rootMatcher, @"Root Matcher can't be nil.");
  // The remote interaction completes the whole execution within the target thread. If this is
  // changed at remote, the method call below should be wrapped with
  // `GREYExecuteSyncBlockInBackgroundQueue`, and a completion handler version of this API should be
  // provided for Swift async test.
  [self->_remoteElementInteraction inRoot:rootMatcher];
  return self;
}

- (id<GREYInteraction>)usingSearchAction:(id<GREYAction>)action
                    onElementWithMatcher:(id<GREYMatcher>)matcher {
  GREYThrowOnNilParameterWithMessage(action, @"Action can't be nil.");
  GREYThrowOnNilParameterWithMessage(matcher, @"Matcher can't be nil.");
  // The remote interaction completes the whole execution within the target thread. If this is
  // changed at remote, the method call below should be wrapped with
  // `GREYExecuteSyncBlockInBackgroundQueue`, and a completion handler version of this API should be
  // provided for Swift async test.
  [self->_remoteElementInteraction usingSearchAction:action onElementWithMatcher:matcher];
  return self;
}

- (id<GREYInteraction>)atIndex:(NSUInteger)index {
  // The remote interaction completes the whole execution within the target thread. If this is
  // changed at remote, the method call below should be wrapped with
  // `GREYExecuteSyncBlockInBackgroundQueue`, and a completion handler version of this API should be
  // provided for Swift async test.
  [self->_remoteElementInteraction atIndex:index];
  return self;
}

- (id<GREYInteraction>)includeStatusBar {
  // The remote interaction completes the whole execution within the target thread. If this is
  // changed at remote, the method call below should be wrapped with
  // `GREYExecuteSyncBlockInBackgroundQueue`, and a completion handler version of this API should be
  // provided for Swift async test.
  [self->_remoteElementInteraction includeStatusBar];
  return self;
}

- (id<GREYInteractionDataSource>)dataSource {
  return _remoteElementInteraction.dataSource;
}

- (void)setDataSource:(id<GREYInteractionDataSource>)dataSource {
  _remoteElementInteraction.dataSource = dataSource;
}

@end
