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

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the visibility test. */
@interface GREYHostApplicationDistantObject (VisibilityTest)

/**
 * @return An object conforming to GREYAssertion that checks if the content offset has changed.
 */
- (id<GREYAssertion>)coverContentOffsetChangedAssertion;

/**
 * @return An object conforming to GREYAssertion that checks if a translucent overlapping
 *         area is present.
 */
- (id<GREYAssertion>)translucentOverlappingViewVisibleAreaAssertion;

/**
 * @return An object conforming to GREYAssertion that checks if a matched element is visible
 *         and adds it to a provided set.
 */
- (GREYAssertionBlock *)ftr_assertOnIDSet:(NSMutableSet *)idSet;

/**
 * @return An object conforming to GREYAssertion that checks if a rectangle is visible.
 */
- (id<GREYAssertion>)visibleRectangleAssertion;

/**
 * @return An object conforming to GREYAssertion that checks if a rectangle is 100% visible.
 */
- (id<GREYAssertion>)entireRectangleVisibleAssertion;

/**
 * Set up an outer view and add it to the current main window for checking rasterization.
 */
- (void)setupOuterView;

/**
 * Remove the outer view added for checking rasterization.
 */
- (void)removeOuterView;

/**
 * @return An object conforming to GREYAssertion that checks the size of a rectangle.
 */
- (id<GREYAssertion>)visibleRectangleSizeAssertion;

/**
 * @return A BOOL checking if the images created by the visibility checker are present.
 */
- (BOOL)visibilityImagesArePresent;

/**
 * @return A BOOL checking if the images created by the visibility checker are absent.
 */
- (BOOL)visibilityImagesAreAbsent;

@end
