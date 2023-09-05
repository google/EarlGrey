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

#import "GREYConstants.h"

#include <math.h>

/** Timeouts */
const CFTimeInterval kGREYInfiniteTimeout = DBL_MAX;

/** Visibility related constants */
const CGFloat kGREYMinimumVisibleAlpha = 0.01f;

/** Action related constants */
const CFTimeInterval kGREYSwipeFastDuration = 0.1;
const CFTimeInterval kGREYSwipeSlowDuration = 1.0;

const CFTimeInterval kGREYPinchFastDuration = 0.1;
const CFTimeInterval kGREYPinchSlowDuration = 1.0;
const double kGREYPinchAngleDefault = (30.0 * M_PI / 180.0);

const CFTimeInterval kGREYTwistFastDuration = 0.1;
const CFTimeInterval kGREYTwistSlowDuration = 1.0;
const double kGREYTwistAngleDefault = (30.0 * M_PI / 180.0);

const CFTimeInterval kGREYLongPressDefaultDuration = 0.7;

const CGFloat kGREYAcceptableFloatDifference = 0.00001f;

const NSInteger kUIPickerViewMaxAccessibilityViews = 500;

/** String constants for names. */

NSString *const kTextFieldAXElementClassName = @"UIAccessibilityTextFieldElement";

NSString *const kNSTimerIgnoreTrackingKey = @"kNSTimerIgnoreTrackingKey";

NSString *const kHostPingRequestMessage = @"ping";

NSString *const kHostPingSuccessMessage = @"success";

NSString *const kSwiftUIConstant = @"SwiftUI";

NSString *const kFastTapEnvironmentVariableName = @"fast_tap_events";

#if TARGET_IPHONE_SIMULATOR
const double kGREYAppLaunchTimeout = 300;  // 5 minutes for Simulators.
#else
const double kGREYAppLaunchTimeout = 600;  // 10 minutes for Devices.
#endif

#if TARGET_OS_IOS
NSString *NSStringFromUIDeviceOrientation(UIDeviceOrientation deviceOrientation) {
  switch (deviceOrientation) {
    case UIDeviceOrientationUnknown:
      return @"UIDeviceOrientationUnknown";
    case UIDeviceOrientationPortrait:
      return @"UIDeviceOrientationPortrait";
    case UIDeviceOrientationPortraitUpsideDown:
      return @"UIDeviceOrientationPortraitUpsideDown";
    case UIDeviceOrientationLandscapeLeft:
      return @"UIDeviceOrientationLandscapeLeft";
    case UIDeviceOrientationLandscapeRight:
      return @"UIDeviceOrientationLandscapeRight";
    case UIDeviceOrientationFaceUp:
      return @"UIDeviceOrientationFaceUp";
    case UIDeviceOrientationFaceDown:
      return @"UIDeviceOrientationFaceDown";
  }
}
#endif  // TARGET_OS_IOS

NSString *NSStringFromGREYDirection(GREYDirection direction) {
  switch (direction) {
    case kGREYDirectionLeft:
      return @"Left";
      break;
    case kGREYDirectionRight:
      return @"Right";
      break;
    case kGREYDirectionUp:
      return @"Up";
      break;
    case kGREYDirectionDown:
      return @"Down";
      break;
  }
}

NSString *NSStringFromPinchDirection(GREYPinchDirection pinchDirection) {
  switch (pinchDirection) {
    case kGREYPinchDirectionOutward:
      return @"Outward";
    case kGREYPinchDirectionInward:
      return @"Inward";
  }
}

NSString *NSStringFromGREYContentEdge(GREYContentEdge edge) {
  switch (edge) {
    case kGREYContentEdgeLeft:
      return @"Left";
    case kGREYContentEdgeRight:
      return @"Right";
    case kGREYContentEdgeTop:
      return @"Top";
    case kGREYContentEdgeBottom:
      return @"Bottom";
  }
}

NSString *NSStringFromGREYLayoutAttribute(GREYLayoutAttribute attribute) {
  switch (attribute) {
    case kGREYLayoutAttributeTop:
      return @"Top";
    case kGREYLayoutAttributeBottom:
      return @"Bottom";
    case kGREYLayoutAttributeLeft:
      return @"Left";
    case kGREYLayoutAttributeRight:
      return @"Right";
  }
}

NSString *NSStringFromGREYLayoutRelation(GREYLayoutRelation relation) {
  switch (relation) {
    case kGREYLayoutRelationEqual:
      return @"==";
    case kGREYLayoutRelationGreaterThanOrEqual:
      return @">=";
    case kGREYLayoutRelationLessThanOrEqual:
      return @"<=";
  }
}

NSString *NSStringFromUIAccessibilityTraits(UIAccessibilityTraits traits) {
  NSMutableArray *traitsPresent = [[NSMutableArray alloc] init];

  if (traits & UIAccessibilityTraitButton) {
    [traitsPresent addObject:@"UIAccessibilityTraitButton"];
  }

  if (traits & UIAccessibilityTraitLink) {
    [traitsPresent addObject:@"UIAccessibilityTraitLink"];
  }

  if (traits & UIAccessibilityTraitHeader) {
    [traitsPresent addObject:@"UIAccessibilityTraitHeader"];
  }

  if (traits & UIAccessibilityTraitSearchField) {
    [traitsPresent addObject:@"UIAccessibilityTraitSearchField"];
  }

  if (traits & UIAccessibilityTraitImage) {
    [traitsPresent addObject:@"UIAccessibilityTraitImage"];
  }

  if (traits & UIAccessibilityTraitSelected) {
    [traitsPresent addObject:@"UIAccessibilityTraitSelected"];
  }

  if (traits & UIAccessibilityTraitPlaysSound) {
    [traitsPresent addObject:@"UIAccessibilityTraitPlaysSound"];
  }

  if (traits & UIAccessibilityTraitKeyboardKey) {
    [traitsPresent addObject:@"UIAccessibilityTraitKeyboardKey"];
  }

  if (traits & UIAccessibilityTraitStaticText) {
    [traitsPresent addObject:@"UIAccessibilityTraitStaticText"];
  }

  if (traits & UIAccessibilityTraitSummaryElement) {
    [traitsPresent addObject:@"UIAccessibilityTraitSummaryElement"];
  }

  if (traits & UIAccessibilityTraitNotEnabled) {
    [traitsPresent addObject:@"UIAccessibilityTraitNotEnabled"];
  }

  if (traits & UIAccessibilityTraitUpdatesFrequently) {
    [traitsPresent addObject:@"UIAccessibilityTraitUpdatesFrequently"];
  }

  if (traits & UIAccessibilityTraitStartsMediaSession) {
    [traitsPresent addObject:@"UIAccessibilityTraitStartsMediaSession"];
  }

  if (traits & UIAccessibilityTraitAdjustable) {
    [traitsPresent addObject:@"UIAccessibilityTraitAdjustable"];
  }

  if (traits & UIAccessibilityTraitAllowsDirectInteraction) {
    [traitsPresent addObject:@"UIAccessibilityTraitAllowsDirectInteraction"];
  }

  if (traits & UIAccessibilityTraitCausesPageTurn) {
    [traitsPresent addObject:@"UIAccessibilityTraitCausesPageTurn"];
  }

  if ([traitsPresent count] == 0) {
    [traitsPresent addObject:@"UIAccessibilityTraitNone"];
  }

  return [traitsPresent componentsJoinedByString:@","];
}

NSString *GREYBugDestination(void) {
  static NSString *bugDestination;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    bugDestination = @"https://github.com/google/EarlGrey/issues";
  });
  return bugDestination;
}

@implementation GREYConstants

+ (GREYDirection)directionFromCenterForEdge:(GREYContentEdge)edge {
  switch (edge) {
    case kGREYContentEdgeLeft:
      return kGREYDirectionLeft;
    case kGREYContentEdgeRight:
      return kGREYDirectionRight;
    case kGREYContentEdgeTop:
      return kGREYDirectionUp;
    case kGREYContentEdgeBottom:
      return kGREYDirectionDown;
  }
}

+ (GREYContentEdge)edgeInDirectionFromCenter:(GREYDirection)direction {
  switch (direction) {
    case kGREYDirectionLeft:
      return kGREYContentEdgeLeft;
    case kGREYDirectionRight:
      return kGREYContentEdgeRight;
    case kGREYDirectionUp:
      return kGREYContentEdgeTop;
    case kGREYDirectionDown:
      return kGREYContentEdgeBottom;
  }
}

+ (GREYDirection)reverseOfDirection:(GREYDirection)direction {
  switch (direction) {
    case kGREYDirectionLeft:
      return kGREYDirectionRight;
    case kGREYDirectionRight:
      return kGREYDirectionLeft;
    case kGREYDirectionUp:
      return kGREYDirectionDown;
    case kGREYDirectionDown:
      return kGREYDirectionUp;
  }
}

+ (CGVector)normalizedVectorFromDirection:(GREYDirection)direction {
  switch (direction) {
    case kGREYDirectionLeft:
      return CGVectorMake(-1, 0);
    case kGREYDirectionRight:
      return CGVectorMake(1, 0);
    case kGREYDirectionUp:
      return CGVectorMake(0, -1);
    case kGREYDirectionDown:
      return CGVectorMake(0, 1);
  }
}

#if TARGET_OS_IOS

// When dealing with DeviceOrientation and InterfaceOrientation in landscape mode, it should be
// noted that they are mapped differently. DeviceOrientation is from the perspective of the
// screen, InterfaceOrientation is from the perspective of the user
// https://developer.apple.com/documentation/uikit/uiinterfaceorientation/uiinterfaceorientationlandscaperight
// UIDeviceOrientationLandscapeLeft = UIInterfaceOrientationLandscapeRight
// https://developer.apple.com/documentation/uikit/uiinterfaceorientation/uiinterfaceorientationlandscapeleft
// UIDeviceOrientationLandscapeRight = UIInterfaceOrientationLandscapeLeft
+ (UIInterfaceOrientation)interfaceOrientationForDeviceOrientation:
    (UIDeviceOrientation)deviceOrientation {
  switch (deviceOrientation) {
    case UIDeviceOrientationPortrait:
      return UIInterfaceOrientationPortrait;
    case UIDeviceOrientationPortraitUpsideDown:
      return UIInterfaceOrientationPortraitUpsideDown;
    case UIDeviceOrientationLandscapeLeft:
      return UIInterfaceOrientationLandscapeRight;
    case UIDeviceOrientationLandscapeRight:
      return UIInterfaceOrientationLandscapeLeft;
    default:
      return UIInterfaceOrientationUnknown;
  }
}

+ (UIDeviceOrientation)deviceOrientationForInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation {
  switch (interfaceOrientation) {
    case UIInterfaceOrientationPortrait:
      return UIDeviceOrientationPortrait;
    case UIInterfaceOrientationPortraitUpsideDown:
      return UIDeviceOrientationPortraitUpsideDown;
    case UIInterfaceOrientationLandscapeRight:
      return UIDeviceOrientationLandscapeLeft;
    case UIInterfaceOrientationLandscapeLeft:
      return UIDeviceOrientationLandscapeRight;
    default:
      return UIDeviceOrientationUnknown;
  }
}

#endif  // TARGET_OS_IOS

BOOL GREYIsLocalTest(void) {
  return YES;
}

@end
