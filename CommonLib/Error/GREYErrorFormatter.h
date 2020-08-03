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
 * Formats the description to be printed for a GREYError.
 */
@interface GREYErrorFormatter : NSObject

/**
 * @note This is the formatted description of the GREYError itself, so it does not include the
 *       hierarchy, screenshots, or stack trace - those are populated on the test side, typically in
 *       the failure handler.
 *
 * @param error The GREYError being formatted.
 *
 * @return The full description of the error including its nested errors suitable for output to the
 *         user, depending on the error's code and domain.
 */
+ (NSString *)formattedDescriptionForError:(GREYError *)error;

@end

NS_ASSUME_NONNULL_END
