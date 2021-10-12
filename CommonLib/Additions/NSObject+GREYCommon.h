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
 * EarlGrey specific common additions to NSObject.
 */
@interface NSObject (GREYCommon)

/**
 * Traverses up the accessibility tree and returns the immediate ancestor UIView or @c nil if none
 * exists.
 * @remark In the case of web accessibility elements the container web view is returned instead.
 *
 * @return The containing UIView object or @c nil if none was found.
 */
- (UIView *)grey_viewContainingSelf;

/**
 * @return The direct container of the element or @c nil if the element has no container.
 */
- (id)grey_container;

/**
 * Traverses up the element hierarchy returning all containers of type @c klass. When called on a
 * non-UIView accessibility element, the accessibility container tree is traversed until the first
 * UIView is encountered, at which point it switches to traversing the view hierarchy.
 *
 * @param klass The class the container being searched for.
 *
 * @return An array of all container objects.
 */
- (NSArray *)grey_containersAssignableFromClass:(Class)klass;

/**
 * @return A detailed description of the element, including accessibility attributes.
 */
- (NSString *)grey_description;

/**
 * @return A short description of the element, including its class, accessibility ID and label.
 */
- (NSString *)grey_shortDescription;

/**
 * @return A description with the class and memory address of the object.
 */
- (NSString *)grey_objectDescription;

/**
 * Takes a value string, which if non-empty, is returned with a prefix attached, else an empty
 * string is returned.
 *
 * @param value  The string representing a value.
 * @param prefix The prefix to be attached to the value
 *
 * @return @c prefix appended to the @c value or empty string if @c value is @c nil.
 */
- (NSString *)grey_formattedDescriptionOrEmptyStringForValue:(NSString *)value
                                                  withPrefix:(NSString *)prefix;
@end

/** Protocol allowing for extending the set of attributes in the output of @c grey_description. */
@protocol GREYExtendedDescriptionAttributes <NSObject>

@optional

/**
 * Objects may implement this method to provide extra attributes to be included in the detailed
 * description of the object printed for EarlGrey errors. This is particularly useful for projects
 * that implement custom matchers; by adding the attributes used by custom matchers to the
 * description and thus to the error output, it can be much easier to diagnose the operation of
 * custom matchers.
 *
 * @return Dictionary mapping attribute names to values. The values can be any object which can be
 * formatted with @c %@ in an @c NSString.
 *
 * @note This property will typically only be accessed at most once per object, and only when an
 * EarlGrey error is constructed, so it's not typically necessary for implementations of this
 * property to be highly efficient.
 *
 * For instance, suppose a given project has a widely implemented property that is used in custom
 * matchers like:
 * @code{objc}
 * @property(nonatomic, nonnull) NSString *targetElementID;
 * @endcode
 * Then an implementation of @c grey_extendedDescriptionAttributes for objects which implement this
 * property might be:
 * @code{objc}
 * - (NSDictionary<NSString *, id> *)grey_extendedDescriptionAttributes {
 *   return @{ @"targetElementID", self.targetElementID };
 * }
 * @endcode
 */
- (nullable NSDictionary<NSString *, id> *)grey_extendedDescriptionAttributes;

@end

NS_ASSUME_NONNULL_END
