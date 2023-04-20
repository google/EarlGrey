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
#import "GREYDefines.h"
#import "GREYVisibilityCheckerCacheEntry.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The minimum number of points that must be visible on an UI element for EarlGrey to consider it
 * as interactable to the user.
 */
GREY_EXTERN const NSUInteger kMinimumPointsVisibleForInteraction;

/**
 * Checker for assessing the visibility of elements on screen as they appear to the user.
 */
@interface GREYVisibilityChecker : NSObject

/**
 * Calculates the percentage visible of the element in the screen.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return The percentage ([0,1] inclusive) of the area visible on the screen compared to @c
 *         element's accessibility frame.
 */
+ (CGFloat)percentVisibleAreaOfElement:(nullable id)element;

/**
 * Calculates the smallest rectangle enclosing the entire visible area of the element.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return The smallest rectangle enclosing the entire visible area of @c element in screen
 *         coordinates. If no part of the element is visible, @c CGRectZero will be returned. The
 *         returned rect is always in points.
 */
+ (CGRect)rectEnclosingVisibleAreaOfElement:(id)element;

@end

/**
 * Check if the @c element is completely obscured.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return @c YES if no part of the @c element is visible to the user. @c NO otherwise.
 */
BOOL GREYIsNotVisible(__nullable id element);

/**
 * Calculates the visible point where a user can tap to interact with.
 *
 * @param element The UI element whose visibility is to be checked.
 *
 * @return A visible point where a user can tap to interact with specified @c element, or
 *         @c GREYCGPointNull if there's no such point.
 * @remark The returned point is relative to @c element's bound.
 */
CGPoint GREYVisibleInteractionPointForElement(__nullable id element);

#pragma mark - Private

/**
 * @return The cached key for an @c element.
 */
NSString *GREYKeyForElement(id element);

/**
 * Saves a cache @c entry for an @c element and adds it for invalidation on the next runloop drain.
 *
 * @param entry   The cache entry to be saved.
 * @param element The element to which the entry is associated.
 */
void GREYAddCache(GREYVisibilityCheckerCacheEntry *entry, id element);

/**
 * Returns cached value for an @c element. Modifying the returned cache also modifies it in the
 * backing store so any changes are visible next time cache is fetched for the same @c element,
 * provided the cache is still valid.
 *
 * @param element The element whose cache is being queried.
 *
 * @return The cached stored under the given @c element.
 */
GREYVisibilityCheckerCacheEntry *GREYCacheForElementCreateIfNonExistent(id element);

/**
 * Invalidates the global cache of visibility checks.
 */
void GREYInvalidateCache(void);  // NO_LINT

#pragma mark - Package Internal

void GREYResetVisibilityImages(void);  // NO_LINT

UIImage *GREYLastActualBeforeImage(void);  // NO_LINT

UIImage *GREYLastActualAfterImage(void);  // NO_LINT

UIImage *GREYLastExpectedAfterImage(void);  // NO_LINT

NS_ASSUME_NONNULL_END
