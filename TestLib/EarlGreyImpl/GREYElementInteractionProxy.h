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

#import "GREYElementInteraction.h"
#import "GREYMatcher.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Test-side class for directing calls to GREYElementInteraction in the app process. Must be
 *  called after establishing a valid connection with app process.
 */
@interface GREYElementInteractionProxy : NSObject <GREYInteraction>

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes the element interaction with the provided matcher.
 *
 *  @param elementMatcher The matcher to used by the interaction for finding the element.
 *
 *  @return An NSObject that conforms to GREYInteraction.
 */
- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher;

/**
 *  Include status bar's window in the interaction.
 */
- (id<GREYInteraction>)includeStatusBar;

@end

NS_ASSUME_NONNULL_END
