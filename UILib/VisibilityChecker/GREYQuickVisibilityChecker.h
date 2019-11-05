//
// Copyright 2019 Google Inc.
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

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Performs frame comparison between views in the hierarchy to figure out the visibility of an
 *  element. Because this check compares frames, it can potentially yield inaccurate result if the
 *  views obscuring the target view are transformed in some way. In such cases, it should fallback
 *  to using the GREYThoroughVisibilityChecker as it gives more accurate result in these cases.
 */
@interface GREYQuickVisibilityChecker : NSObject

/**
 *  Calculates the amount (in percent) @c element is visible on the screen.
 *
 *  @param element         The UI element whose visibility is to be checked.
 *  @param performFallback An out parameter indicating whether or not a fallback should occur
 *                         because the quick visibility checker has low confidence in the accuracy
 *                         of the calculation. Use GREYThoroughVisibilityChecker instead to
 *                         calculate the visible percentage area. You MUST check for @c
 *                         performFallback before using the return value.
 *
 *  @return The percentage ([0,1] inclusive) of the area visible on the screen compared to @c
 *          element's accessibility frame. Returned value is invalid if @c performFallback is
 *          set to @c YES. Returns NaN if @c performFallback is set to @c YES.
 */
+ (CGFloat)percentVisibleAreaOfElement:(id)element performFallback:(BOOL *)performFallback;

@end

NS_ASSUME_NONNULL_END
