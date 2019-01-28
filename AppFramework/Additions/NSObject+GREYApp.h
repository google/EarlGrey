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

/**
 *  Additions to NSObject for obtaining details for UI and Accessibility Elements.
 */
@interface NSObject (GREYApp)

/**
 *  @return The element's accessibilityActivationPoint converted to window coordinates.
 */
- (CGPoint)grey_accessibilityActivationPointInWindowCoordinates;

/**
 *  @return The element's accessibility point relative to its accessibility frame's origin.
 */
- (CGPoint)grey_accessibilityActivationPointRelativeToFrame;

/**
 *  @return The recursive description of the UI hierarchy for the current element. This should be
 *          used only with objects that are UIViews or UIAccessibilityElements.
 */
- (NSString *)grey_recursiveDescription;

/**
 *  @return An NSString in the format required by the app state tracker. The information printed
 *          here is printed when the application is not idle and the app's state is checked. This
 *          can be utilized for debugging since it shows which object is currently being tracked
 *          and preventing the app from idling.
 */
- (NSString *)grey_stateTrackerDescription;

/**
 *  Swizzle a selector with a particular object after a specified delay time interval in a
 *  specific run loop mode.
 *
 *  @param aSelector  The selector to be swizzled.
 *  @param anArgument The object to swizzle the selector with.
 *  @param delay      The NSTimeInterval after which the swizzling is to be done.
 *  @param modes      The run loop mode to perform the swizzling in.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)greyswizzled_performSelector:(SEL)aSelector
                          withObject:(id)anArgument
                          afterDelay:(NSTimeInterval)delay
                             inModes:(NSArray *)modes;

@end
