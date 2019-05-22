//
// Copyright 2017 Google Inc.
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

#import "AppFramework/Action/GREYAction.h"
#import "AppFramework/Action/GREYActions.h"
#import "AppFramework/Core/GREYInteraction.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/Error/GREYError.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"
#import "CommonLib/GREYConstants.h"
#import "CommonLib/Matcher/GREYElementMatcherBlock.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

@interface GREYActionsTest : GREYAppBaseTest
@end

@implementation GREYActionsTest

- (void)testTapActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  GREYError *error;
  [tap perform:view error:&error];
  XCTAssertEqual(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode);
}

- (void)testTapActionConstraintsFailedWithNSError {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  GREYError *error;
  [tap perform:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain, @"Wrong error domain.");
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode, @"Wrong error code.");
  XCTAssertEqualObjects(error.errorInfo[kErrorDetailActionNameKey], @"Tap", @"Wrong error action.");
  XCTAssertEqualObjects(error.errorInfo[@"Element Description"], [view grey_description],
                        @"Wrong error element description.");
}

- (void)testMultiTapActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> doubleTap = [GREYActions actionForMultipleTapsWithCount:2];
  GREYError *error;
  [doubleTap perform:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

- (void)testMultiTapActionWithZeroTapCount {
  XCTAssertThrowsSpecificNamed([GREYActions actionForMultipleTapsWithCount:0], NSException,
                               NSInternalInconsistencyException,
                               @"Should throw an exception for initializing a tap action with "
                               @"zero tap count.");
}

- (void)testTurnSwitchActionConstraintsFailed {
  UISwitch *uiswitch = [[UISwitch alloc] init];
  uiswitch.hidden = YES;
  id<GREYAction> turnSwitch = [GREYActions actionForTurnSwitchOn:YES];
  GREYError *error;
  [turnSwitch perform:uiswitch error:&error];
  XCTAssertEqual(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode);
}

- (void)testSwipeLeftActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> swipeLeft = [GREYActions actionForSwipeFastInDirection:kGREYDirectionLeft];
  GREYError *error;
  [swipeLeft perform:view error:&error];
  NSLog(@"%@", error.domain);
  XCTAssertEqual(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode);
}

- (void)testSwipeOnViewWithoutWindow {
  // First, disable other constraint checks so the action won't fail because of them
  [[GREYConfiguration sharedConfiguration] setValue:@NO
                                       forConfigKey:kGREYConfigKeyActionConstraintsEnabled];

  UIView *view = [[UIView alloc] init];
  [[[self.mockSharedApplication stub] andReturnValue:@(UIDeviceOrientationPortrait)]
      statusBarOrientation];
  id<GREYAction> swipeLeft = [GREYActions actionForSwipeFastInDirection:kGREYDirectionLeft];

  GREYError *error;
  [swipeLeft perform:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYSyntheticEventInjectionErrorDomain);
}

- (void)testTapDisabledControl {
  UIControl *view = [[UIControl alloc] init];

  // Mock out [GREYMatchers matcherForSufficientlyVisible] for a matcher that matches anything.
  id mockMatcher = [OCMockObject mockForProtocol:@protocol(GREYMatcher)];
  OCMStub([mockMatcher matches:OCMOCK_ANY]).andReturn(@YES);
  id mockGREYMatchers = OCMClassMock([GREYMatchers class]);
  OCMStub([mockGREYMatchers matcherForSufficientlyVisible]).andReturn(mockMatcher);

  view.enabled = NO;
  id<GREYAction> tap = [GREYActions actionForTap];
  GREYError *error;
  [tap perform:view error:&error];
  XCTAssertEqual(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode);
}

- (void)testInvalidTapActionSucceedsAfterDisablingConstraints {
  [[GREYConfiguration sharedConfiguration] setValue:@NO
                                       forConfigKey:kGREYConfigKeyActionConstraintsEnabled];

  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  GREYError *error;
  [tap perform:view error:&error];
  XCTAssertNotNil(error);
}

- (void)testReplaceTextSucceedsOnUITextField {
  NSString *textToReplace = @"A String";
  NSError *error;

  UITextField *textfield = [[UITextField alloc] init];

  id<GREYAction> replace = [GREYActions actionForReplaceText:textToReplace];
  [replace perform:textfield error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(textToReplace, textfield.text);
}

- (void)testReplaceTextFailsOnUIView {
  NSString *textToReplace = @"A String";
  GREYError *error;

  UIView *view = [[UIView alloc] init];

  id<GREYAction> replace = [GREYActions actionForReplaceText:textToReplace];
  [replace perform:view error:&error];

  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain, @"Wrong error domain.");
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode, @"Wrong error code");
  NSString *actionName = [NSString stringWithFormat:@"Replace with text: \"%@\"", textToReplace];
  XCTAssertEqualObjects(error.errorInfo[kErrorDetailActionNameKey], actionName,
                        @"Wrong error action.");
  XCTAssertEqualObjects(error.errorInfo[@"Element Description"], [view grey_description],
                        @"Wrong error element description.");
}

@end
