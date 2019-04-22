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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/**
 *  EarlGrey specific common additions to NSObject.
 */
@interface NSObject (GREYCommon)

/**
 *  Traverses up the accessibility tree and returns the immediate ancestor UIView or @c nil if none
 *  exists.
 *  @remark In the case of web accessibility elements the container web view is returned instead.
 *
 *  @return The containing UIView object or @c nil if none was found.
 */
- (UIView *)grey_viewContainingSelf;

/**
 *  @return The direct container of the element or @c nil if the element has no container.
 */
- (id)grey_container;

/**
 *  Traverses up the element hierarchy returning all containers of type @c klass. When called on a
 *  non-UIView accessibility element, the accessibility container tree is traversed until the first
 *  UIView is encountered, at which point it switches to traversing the view hierarchy.
 *
 *  @param klass The class the container being searched for.
 *
 *  @return An array of all container objects.
 */
- (NSArray *)grey_containersAssignableFromClass:(Class)klass;

/**
 *  @return @c YES if @c self is an accessibility element within a UIWebView, @c NO otherwise.
 */
- (BOOL)grey_isWebAccessibilityElement;

/**
 *  @return A detailed description of the element, including accessibility attributes.
 */
- (NSString *)grey_description;

/**
 *  @return A short description of the element, including its class, accessibility ID and label.
 */
- (NSString *)grey_shortDescription;

/**
 *  @return A description with the class and memory address of the object.
 */
- (NSString *)grey_objectDescription;

/**
 *  Takes a value string, which if non-empty, is returned with a prefix attached, else an empty
 *  string is returned.
 *
 *  @param value  The string representing a value.
 *  @param prefix The prefix to be attached to the value
 *
 *  @return @c prefix appended to the @c value or empty string if @c value is @c nil.
 */
- (NSString *)grey_formattedDescriptionOrEmptyStringForValue:(NSString *)value
                                                  withPrefix:(NSString *)prefix;
@end
NS_ASSUME_NONNULL_END
