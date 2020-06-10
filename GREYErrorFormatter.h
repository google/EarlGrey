//
// Copyright 2020 Google Inc.
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

@class GREYError;

NS_ASSUME_NONNULL_BEGIN

/**
 * Responsible for determining the human-readable formatted description of a GREYError.
 */
@interface GREYErrorFormatter: NSObject

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * For a given @c error, Creates a GREYErrorFormatter for formatting the description of a GREYError.
 *
 * @param error The GREYError used to format the description
 *
 * @return An instance of GREYErrorFormatter
 */
- (instancetype)initWithError:(GREYError *)error NS_DESIGNATED_INITIALIZER;

/**
 * @return The full description of the error including its nested errors
 *         suitable for output to the user, depending on the error's code and domain
 */
- (NSString *)formattedDescription;

/**
 * For a given @c hierarchy, creates a human-readable hierarchy
 * including the legend.
 *
 * @param hierarchy The string representation of the App UI Hierarchy
 *
 * @return The formatted hierarchy and legend to be printed on the console
 */
NSString *GREYFormattedHierarchy(NSString *hierarchy);

/**
 * Determines whether this error's code and domain are supported
 * by the new GREYErrorFormatter::formattedDescription.
 * If @c NO, then default to using the existing dictionary object formatting.
 *
 * This is temporary until all errors are using GREYErrorFormatter.
 *
 * @return @c YES if the new formatting based on the code and domain should be used for this error
 */
BOOL GREYShouldUseErrorFormatterForError(GREYError *error);

@end

NS_ASSUME_NONNULL_END
