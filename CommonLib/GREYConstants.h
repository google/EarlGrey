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

#import <UIKit/UIKit.h>

#import "GREYDefines.h"

/**
 * Any alpha less than this value is considered hidden by Apple.
 * @see
 * https://developer.apple.com/reference/uikit/uiview/1622469-hittest?language=objc
 */
GREY_EXTERN const CGFloat kGREYMinimumVisibleAlpha;

/**
 * Amount of time a "fast" swipe should last for, in seconds.
 */
GREY_EXTERN const CFTimeInterval kGREYSwipeFastDuration;

/**
 * Amount of time a "slow" swipe should last for, in seconds.
 */
GREY_EXTERN const CFTimeInterval kGREYSwipeSlowDuration;

/**
 * Amount of time a "fast" pinch should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYPinchFastDuration;

/**
 * Amount of time a "slow" pinch should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYPinchSlowDuration;

/**
 * Amount of time a "fast" twist should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYTwistFastDuration;

/**
 * Amount of time a "slow" twist should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYTwistSlowDuration;

/**
 * Infinite timeout.
 */
GREY_EXTERN const CFTimeInterval kGREYInfiniteTimeout;

/**
 * Limit on the number of UIPickerViews that can be pulled for getting the hierarchy.
 */
GREY_EXTERN const NSInteger kUIPickerViewMaxAccessibilityViews;

/**
 * Amount of time a normal long press should last for, in seconds. Extracted from:
 * @see
 * https://developer.apple.com/reference/uikit/uilongpressgesturerecognizer/1616423-minimumpressduration
 */
GREY_EXTERN const CFTimeInterval kGREYLongPressDefaultDuration;

/**
 * Minimum acceptable difference between two floating-point values when comparing them.
 */
GREY_EXTERN const CGFloat kGREYAcceptableFloatDifference;

/**
 * Class name for the accessibility element inside a UITextField.
 */
GREY_EXTERN NSString* _Nonnull const kTextFieldAXElementClassName;

/**
 * A key which if set on an NSTimer will prevent it from being tracked.
 */
GREY_EXTERN NSString* _Nonnull const kNSTimerIgnoreTrackingKey;

/**
 * The ping message to be sent to the app-under-test's ping service.
 */
GREY_EXTERN NSString* _Nonnull const kHostPingRequestMessage;

/**
 * The expected ping response to be sent back from the app-under-test's ping service.
 */
GREY_EXTERN NSString* _Nonnull const kHostPingSuccessMessage;

/**
 * The expected prefix for the 'class' name when finding elements in SwiftUI.
 */
GREY_EXTERN NSString* _Nonnull const kSwiftUIConstant;

/**
 * The environment variable name to remove extra delays between touch events.
 */
GREY_EXTERN NSString* _Nonnull const kFastTapEnvironmentVariableName;

/**
 * The default pinch angle for the pinch action, specified by an approximate angle for a right
 * handed two finger pinch.
 */
GREY_EXTERN const double kGREYPinchAngleDefault;

/**
 * The default pinch angle for the twist action, specified by an approximate angle for a right
 * handed two finger twist.
 */
GREY_EXTERN const double kGREYTwistAngleDefault;

/**
 * The default timeout for an XCUIApplication::launch call in an EarlGrey test.
 */
GREY_EXTERN const double kGREYAppLaunchTimeout;

/**
 * Directions for scrolling and swiping.
 *
 * The direction describes the motion of the view port as a result of the swipe, which is opposite
 * to the direction the user's finger moves. For example, a scroll down the page should be
 * expressed with @c kGREYDirectionDown as it simulates a touch that starts somewhere in the middle
 * of the screen and moves up to simulate an absolute scroll down behavior.
 */
typedef NS_ENUM(NSInteger, GREYDirection) {
  /**
   * The finger is moving to the right, view port is moving left.
   */
  kGREYDirectionLeft = 1,
  /**
   * The finger is moving to the left, view port is moving right.
   */
  kGREYDirectionRight,
  /**
   * The finger is moving downwards, view port is moving up.
   */
  kGREYDirectionUp,
  /**
   * The finger is moving upwards, view port is moving down.
   */
  kGREYDirectionDown,
};

/**
 * Directions for pinch gesture.
 *
 * The direction describes the motion of the view port as a result of pinch. There are two
 * possible directions for pinch action inward and outward.
 */
typedef NS_ENUM(NSInteger, GREYPinchDirection) {
  /**
   * Two fingers pinching outward.
   */
  kGREYPinchDirectionOutward = 1,
  /**
   * Two fingers pinching inward.
   */
  kGREYPinchDirectionInward,
};

/**
 * Content edges for scrolling.
 */
typedef NS_ENUM(NSInteger, GREYContentEdge) {
  /**
   * The left content edge of the screen in the current orientation.
   */
  kGREYContentEdgeLeft,
  /**
   * The right content edge of the screen in the current orientation.
   */
  kGREYContentEdgeRight,
  /**
   * The top content edge of the screen in the current orientation.
   */
  kGREYContentEdgeTop,
  /**
   * The bottom content edge of the screen in the current orientation.
   */
  kGREYContentEdgeBottom,
};

/**
 * Directions for layout specification.
 */
typedef NS_ENUM(NSInteger, GREYLayoutDirection) {
  /**
   * To the left of the current element.
   */
  kGREYLayoutDirectionLeft = 1,
  /**
   * To the right of the current element.
   */
  kGREYLayoutDirectionRight,
  /**
   * Above the current element.
   */
  kGREYLayoutDirectionUp,
  /**
   * Below the current element.
   */
  kGREYLayoutDirectionDown,
};

/**
 * Layout attributes for matching on layouts (modelled after @c NSLayoutAttribute).
 */
typedef NS_ENUM(NSInteger, GREYLayoutAttribute) {
  /**
   * The left edge of element.
   */
  kGREYLayoutAttributeLeft = 1,
  /**
   * The right edge of element.
   */
  kGREYLayoutAttributeRight,
  /**
   * The top edge of element.
   */
  kGREYLayoutAttributeTop,
  /**
   * The bottom edge of element.
   */
  kGREYLayoutAttributeBottom,
};

/**
 * Layout relations for comparison of layout attributes (modelled after @c NSLayoutRelation).
 */
typedef NS_ENUM(NSInteger, GREYLayoutRelation) {
  /**
   * Value is less than or equal to the other operand.
   */
  kGREYLayoutRelationLessThanOrEqual = -1,
  /**
   * Value is equal to the other operand.
   */
  kGREYLayoutRelationEqual = 0,
  /**
   * Value is greater than or equal to the other operand.
   */
  kGREYLayoutRelationGreaterThanOrEqual = 1,
};

/**
 * Types of tap actions
 */
typedef NS_ENUM(NSInteger, GREYTapType) {
  /**
   * Tap action for basic tap.
   */
  kGREYTapTypeShort,
  /**
   * Tap action for long press tap.
   */
  kGREYTapTypeLong,
  /**
   * Tap action for multiple taps (for example double tap).
   */
  kGREYTapTypeMultiple,
  /**
   * Tap action for keyboard keys.
   */
  kGREYTapTypeKBKey,
};

/**
 * @return A string representation of the given @c deviceOrientation.
 */
#if TARGET_OS_IOS
NSString* _Nonnull NSStringFromUIDeviceOrientation(UIDeviceOrientation deviceOrientation);
#endif  // TARGET_OS_IOS

/**
 * @return A string representation of the given @c direction.
 */
NSString* _Nonnull NSStringFromGREYDirection(GREYDirection direction);

/**
 * Returns a string representation of the given @c pinchDirection.
 */
NSString* _Nonnull NSStringFromPinchDirection(GREYPinchDirection pinchDirection);

/**
 * @return A string representation of the given @c edge.
 */
NSString* _Nonnull NSStringFromGREYContentEdge(GREYContentEdge edge);

/**
 * @return A string representation of the given layout @c attribute.
 */
NSString* _Nonnull NSStringFromGREYLayoutAttribute(GREYLayoutAttribute attribute);

/**
 * @return A string representation of the given layout @c relation.
 */
NSString* _Nonnull NSStringFromGREYLayoutRelation(GREYLayoutRelation relation);

/**
 * @return A string representation of the given accessibility trait.
 */
NSString* _Nonnull NSStringFromUIAccessibilityTraits(UIAccessibilityTraits traits);

/**
 * @return The destination that EarlGrey users should file bugs/issues at.
 */
NSString* _Null_unspecified GREYBugDestination(void);  // NOLINT

/**
 * @return A BOOL specifying if the test is being run locally or on internal CI.
 */
BOOL GREYIsLocalTest(void);  // NOLINT

NS_ASSUME_NONNULL_BEGIN
/**
 * EarlGrey specific common additions to NSObject.
 */
/**
 * A class containing helper methods for conversion to-and-from constants.
 */
@interface GREYConstants : NSObject

/**
 * @return The direction from center to the given @c edge.
 */
+ (GREYDirection)directionFromCenterForEdge:(GREYContentEdge)edge;

/**
 * @return The edge that is in the given @c direction from the center.
 */
+ (GREYContentEdge)edgeInDirectionFromCenter:(GREYDirection)direction;

/**
 * @return The reverse direction of the given @c direction.
 */
+ (GREYDirection)reverseOfDirection:(GREYDirection)direction;

/**
 * @return A normalized vector in the given @c direction.
 */
+ (CGVector)normalizedVectorFromDirection:(GREYDirection)direction;

#if TARGET_OS_IOS

/**
 * Maps UIDeviceOrientation to UIInterfaceOrientation for use in rotation API's.
 */
+ (UIInterfaceOrientation)interfaceOrientationForDeviceOrientation:
    (UIDeviceOrientation)deviceOrientation;

/**
 * Maps UIDeviceOrientation to UIInterfaceOrientation for use in rotation API's.
 */
+ (UIDeviceOrientation)deviceOrientationForInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation;

#endif  // TARGET_OS_IOS

@end
NS_ASSUME_NONNULL_END
