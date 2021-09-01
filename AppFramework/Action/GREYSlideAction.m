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

#import "GREYSlideAction.h"

#include <tgmath.h>

#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYSyntheticEvents.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYDiagnosable.h"
#import "GREYLogger.h"
#import "GREYMatcher.h"
#import "GREYElementHierarchy.h"

@implementation GREYSlideAction {
  /**
   * The final value that the slider should be moved to.
   */
  float _finalValue;
}

- (instancetype)initWithSliderValue:(float)value classConstraint:(id<GREYMatcher>)classConstraint {
  id<GREYMatcher> systemAlertShownMatcher = [GREYMatchers matcherForSystemAlertViewShown];
  NSArray<id<GREYMatcher>> *constraintMatchers = @[
    [GREYMatchers matcherForInteractable],
    [GREYMatchers matcherForNegation:systemAlertShownMatcher], classConstraint
  ];
  NSString *name = [NSString stringWithFormat:@"Slide to value: %g", value];
  self = [super initWithName:name
                 constraints:[[GREYAllOf alloc] initWithMatchers:constraintMatchers]];
  if (self) {
    _finalValue = value;
  }
  return self;
}

#pragma mark - GREYAction

#if TARGET_OS_IOS
- (BOOL)perform:(id)slider error:(__strong NSError **)error {
  __block BOOL retVal = NO;
  grey_dispatch_sync_on_main_thread(^{
    // We aggressively access UI elements when performing the action, rather than having pieces
    // running on the main thread separately, the whole action will be performed on the main thread.
    retVal = [self grey_perform:slider error:error];
  });
  return retVal;
}
#endif  // TARGET_OS_IOS

#pragma mark - Private

#if TARGET_OS_IOS
- (BOOL)grey_perform:(id)slider error:(__strong NSError **)error {
  if (![self satisfiesConstraintsForElement:slider error:error]) {
    return NO;
  }

  if (!islessgreater([self valueForSlider:slider], _finalValue)) {
    return YES;
  }

  if (![self checkEdgeCasesForFinalValueOfSlider:slider error:error]) {
    return NO;
  };

  CGFloat currentSliderValue = [self valueForSlider:slider];

  // Get the center of the thumb in coordinates respective of the slider it is in.
  CGPoint touchPoint = [self centerOfSliderThumbInSliderCoordinates:slider];

  // Begin sliding by injecting touch events.
  GREYSyntheticEvents *eventGenerator = [[GREYSyntheticEvents alloc] init];
  CFTimeInterval interactionTimeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
  [eventGenerator beginTouchAtPoint:[slider convertPoint:touchPoint toView:nil]
                   relativeToWindow:[slider window]
                  immediateDelivery:YES
                            timeout:interactionTimeout];

  // |slider.value| could have changed, because touch down sometimes moves the thumb.
  CGFloat previousSliderValue = currentSliderValue;
  currentSliderValue = [self valueForSlider:slider];

  // Stepsize is hypothesized amount you have to step to get from one value to another. It's
  // hypothesized because the distance between any two given values is not always consistent.
  double stepSize = [self stepSizeForCurrentValue:currentSliderValue inSlider:slider];
  double amountToSlide = stepSize * ((double)_finalValue - (double)currentSliderValue);

  // A value could be unattainable, in which case, this algorithm would run forever. From testing,
  // we've seen that it takes anywhere from 2-4 interactions to find a final value that is
  // acceptable (see constants defined above to understand what accepable is). So, we let the
  // algorithm run for at most ten iterations and then halt.
  static const unsigned short kAllowedAttemptsBeforeStopping = 10;
  unsigned short numberOfAttemptsAtGettingFinalValue = 0;

  // Begin moving thumb to the |_finalValue|
  while (islessgreater([self valueForSlider:slider], _finalValue)) {
    @autoreleasepool {
      if (!(numberOfAttemptsAtGettingFinalValue < kAllowedAttemptsBeforeStopping)) {
        NSLog(@"The value you have chosen to move to is probably unattainable. Most likely, it is "
              @"between two pixels.");
        break;
      }

      touchPoint = CGPointMake(touchPoint.x + (CGFloat)amountToSlide, touchPoint.y);
      [eventGenerator continueTouchAtPoint:[slider convertPoint:touchPoint toView:nil]
                         immediateDelivery:YES
                                   timeout:interactionTimeout];

      // For debugging purposes, leave this in.
      GREYLogVerbose(@"Slider value after moving: %f", [self valueForSlider:slider]);

      // Update |previousSliderValue| and |currentSliderValue| only if slider value actually
      // changed.
      if (islessgreater([self valueForSlider:slider], currentSliderValue)) {
        previousSliderValue = currentSliderValue;
        currentSliderValue = [self valueForSlider:slider];
      }

      // changeInSliderValueAfterMoving is how many values we actually moved with the previously
      // calculated |amountToSlide|.
      double changeInSliderValueAfterMoving = currentSliderValue - previousSliderValue;
      if (islessgreater(currentSliderValue, previousSliderValue)) {
        // Adjust the stepSize based upon how many values were actually traversed.
        stepSize = fabs(amountToSlide / changeInSliderValueAfterMoving);
        amountToSlide = stepSize * ((double)_finalValue - (double)currentSliderValue);
      } else {
        // If we didn't move at all and we are still not at the final value, move by twice as much
        // as we did last time to try to get a different value.
        amountToSlide = 2.0 * amountToSlide;
      }
      numberOfAttemptsAtGettingFinalValue++;
    }
  }

  [eventGenerator endTouchWithTimeout:interactionTimeout];
  return YES;
}

/**
 * @return Center of the slider thumb in slider coordinate.
 *
 * @param slider An id that must have the methods required for a slider.
 **/
- (CGPoint)centerOfSliderThumbInSliderCoordinates:(id)slider {
  UISlider *uiSlider = (UISlider *)slider;
  CGRect sliderBounds = uiSlider.bounds;
  CGRect trackBounds = [uiSlider trackRectForBounds:sliderBounds];
  CGRect thumbBounds = [uiSlider thumbRectForBounds:sliderBounds
                                          trackRect:trackBounds
                                              value:uiSlider.value];
  return CGPointMake(CGRectGetMidX(thumbBounds), CGRectGetMidY(thumbBounds));
}

/**
 * @return The step side of the slider.
 *
 * @param currentSliderValue A double signifying the current value the slider has.
 * @param slider             An id that must have the methods required for a slider.
 **/
- (double)stepSizeForCurrentValue:(double)currentSliderValue inSlider:(id)slider {
  UISlider *uiSlider = (UISlider *)slider;
  // Get the rectangle width in order to estimate horizonal distance between values.
  CGRect trackBounds = [uiSlider trackRectForBounds:uiSlider.bounds];
  double trackWidth = trackBounds.size.width;

  // Stepsize is hypothesized amount you have to step to get from one value to another. It's
  // hypothesized because the distance between any two given values is not always consistent.
  return fabs(trackWidth / ((double)uiSlider.maximumValue - (double)uiSlider.minimumValue));
}

/**
 * @return A BOOL signifying that the value to be updated is beyond the slider's min/max values.
 *
 * @param      slider An id that must have the methods required for a slider.
 * @param[out] error  An NSError populated with the error for the slide action.
 **/
- (BOOL)checkEdgeCasesForFinalValueOfSlider:(id)slider error:(__strong NSError **)error {
  NSString *reason;
  if (isgreater(_finalValue, [self maxValueForSlider:slider])) {
    reason = @"Value to move to is larger than slider's maximum value";
  } else if (isless(_finalValue, [self minValueForSlider:slider])) {
    reason = @"Value to move to is smaller than slider's minimum value";
  } else if (!islessgreater([self minValueForSlider:slider], [self maxValueForSlider:slider]) &&
             islessgreater(_finalValue, [self minValueForSlider:slider])) {
    reason = @"Slider has the same maximum and minimum, cannot move thumb to desired value";
  } else {
    return YES;
  }

  NSString *description = [NSString stringWithFormat:@"%@: Slider's Minimum is %g, Maximum is %g, "
                                                     @"desired value is %g",
                                                     reason, [self minValueForSlider:slider],
                                                     [self maxValueForSlider:slider], _finalValue];

  I_GREYPopulateError(error, kGREYInteractionErrorDomain, kGREYInteractionActionFailedErrorCode,
                      description);

  return NO;
}

#endif  // TARGET_OS_IOS

/**
 * @return The CGFloat value of the slider. Any slider subclass must have a @c value property.
 *
 * @param slider The slider being acted upon.
 */
- (CGFloat)valueForSlider:(id)slider {
#if TARGET_OS_IOS
  return ((UISlider *)slider).value;
#else
  return NSNotFound;
#endif
}

/**
 * @return The CGFloat minimum value of the slider. Any slider subclass must have a @c minimumValue
 *         property.
 *
 * @param slider The slider being acted upon.
 */
- (CGFloat)minValueForSlider:(id)slider {
#if TARGET_OS_IOS
  return ((UISlider *)slider).minimumValue;
#else
  return NSNotFound;
#endif
}

/**
 * @return The CGFloat maximum value of the slider. Any slider subclass must have a @c maximumValue
 *         property.
 *
 * @param slider The slider being acted upon.
 */
- (CGFloat)maxValueForSlider:(id)slider {
#if TARGET_OS_IOS
  return ((UISlider *)slider).maximumValue;
#else
  return NSNotFound;
#endif
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return GREYCorePrefixedDiagnosticsID(@"slide");
}

@end
