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

#import "GREYError.h"

NS_ASSUME_NONNULL_BEGIN

@interface GREYErrorFormatter: NSObject

/**
 * For a given @c hierarchy, create a human-readable hierarchy
 * including the legend.
 *
 * @param hierarchy The string representation of the App UI Hierarchy
 *
 * @return The formatted hierarchy and legend to be printed on the console
*/
+ (NSString *)formattedHierarchy:(nonnull NSString *)hierarchy;

/**
 * For a given @c error, create a GREYErrorFormatter to provide a formattedDescription.
 *
 * @param error The GREYError used to format the description
 *
 * @return An instance of GREYErrorFormatter
*/
- (instancetype)initWithError:(GREYError *)error;

/**
 * Create a human-readable formatted string for the GREYError,
 * depending on its code and domain.
 *
 * @return The full description of the error including its nested errors
 *          suitable for output to the user.
*/
- (NSString *)formattedDescription;

/**
 * For a given @c error, creates an array of error dictionaries with its nested error.
 *
 * @return An array of error dictionaries for the given @c error.
 *         If the given error does not contain nested error, an empty array will be returned.
 */
+ (NSArray *)grey_nestedErrorDictionariesForError:(NSError *)error;

/**
 * For a given @c error, creates a JSON-formatted description of the error and its nested error.
 *
 * @return The description of the error including its nested errors,
 *         if error object was created and set. Otherwise, return @c NULL.
 */
+ (NSString *)grey_nestedDescriptionForError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
