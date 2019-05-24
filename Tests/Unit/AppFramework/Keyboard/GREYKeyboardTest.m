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

#import "AppFramework/Keyboard/GREYKeyboard.h"
#import "AppFramework/Synchronization/GREYAppStateTracker.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"

#import <XCTest/XCTest.h>

@interface GREYKeyboard (GREYKeyboardTest)
typedef BOOL (^ConditionBlock)(void);
+ (BOOL)grey_waitUntilCondition:(ConditionBlock)condition
         isSatisfiedWithTimeout:(NSTimeInterval)timeInterval;
@end

@interface GREYKeyboardTest : GREYAppBaseTest
@end

@implementation GREYKeyboardTest

- (void)testKeyboardChangesPendingUIEventState {
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillShowNotification
                                                      object:nil];
  XCTAssertTrue(
      kGREYPendingKeyboardTransition & [[GREYAppStateTracker sharedInstance] currentState],
      @"Pending Keyboard appearance should be tracked");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidShowNotification
                                                      object:nil];
  XCTAssertFalse(
      kGREYPendingKeyboardTransition & [[GREYAppStateTracker sharedInstance] currentState],
      @"After keyboard appears its state should be cleared");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification
                                                      object:nil];
  XCTAssertTrue(
      kGREYPendingKeyboardTransition & [[GREYAppStateTracker sharedInstance] currentState],
      @"Pending Keyboard disappearance should be tracked");

  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidHideNotification
                                                      object:nil];
  XCTAssertFalse(
      kGREYPendingKeyboardTransition & [[GREYAppStateTracker sharedInstance] currentState],
      @"After keyboard disappears its state should be cleared");
}

- (void)greyTestWaitCondition {
  ConditionBlock nilCondition = nil;
  ConditionBlock immediatelySatisfiedCondition = ^BOOL(void) {
    return NO;
  };
  ConditionBlock timedoutCondition = ^BOOL(void) {
    return YES;
  };
  __block BOOL returnValue = YES;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   returnValue = NO;
                 });
  ConditionBlock timedCondition = ^BOOL(void) {
    return returnValue;
  };
  XCTAssertThrows([GREYKeyboard grey_waitUntilCondition:nilCondition isSatisfiedWithTimeout:0.1]);
  XCTAssertThrows([GREYKeyboard grey_waitUntilCondition:immediatelySatisfiedCondition
                                 isSatisfiedWithTimeout:0]);
  XCTAssertThrows([GREYKeyboard grey_waitUntilCondition:immediatelySatisfiedCondition
                                 isSatisfiedWithTimeout:-0.1]);
  XCTAssertTrue([GREYKeyboard grey_waitUntilCondition:immediatelySatisfiedCondition
                               isSatisfiedWithTimeout:0.1]);
  XCTAssertFalse(
      [GREYKeyboard grey_waitUntilCondition:timedoutCondition isSatisfiedWithTimeout:0.1]);
  XCTAssertFalse([GREYKeyboard grey_waitUntilCondition:timedCondition isSatisfiedWithTimeout:0.2]);
  XCTAssertTrue([GREYKeyboard grey_waitUntilCondition:timedCondition isSatisfiedWithTimeout:0.5]);
}

@end
