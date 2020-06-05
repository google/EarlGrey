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

@class GREYError;

NS_ASSUME_NONNULL_BEGIN

@interface GREYErrorFormatter: NSObject

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
 * For a given @c hierarchy, create a human-readable hierarchy
 * including the legend.
 *
 * @param hierarchy The string representation of the App UI Hierarchy
 *
 * @return The formatted hierarchy and legend to be printed on the console
 */
//+ (NSString *)formattedHierarchy:(nonnull NSString *)hierarchy;
NSString *GREYFormattedHierarchy(NSString *hierarchy);

/**
 * Determine whether this error's code and domain are supported
 * by the new GREYErrorFormatter formattedDescription.
 * If NO, then default to using the existing dictionary object formatting.
 *
 * @return YES if the new formatting should be used for this error
 */
//+ (BOOL)shouldUseErrorFormatterForError:(GREYError *)error;
BOOL GREYShouldUseErrorFormatterForError(GREYError *error);

@end

NS_ASSUME_NONNULL_END
