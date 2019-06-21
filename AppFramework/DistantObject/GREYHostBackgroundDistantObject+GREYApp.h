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

#import "GREYHostBackgroundDistantObject.h"

#import "GREYElementInteraction.h"
#import "GREYMatcher.h"

/**
 *  GREYHostBackgroundDistantObject extension in the EarlGrey AppFramework. This file should
 *  contain categories on classes that are to be called in the tests. Similar to
 *  GREYHostApplicationDistantObject categories, these create distant objects between the
 *  application and the test on a background queue, rather than on the main queue as is done in the
 *  GREYHostApplicationDistantObject categories.
 */
@interface GREYHostBackgroundDistantObject (GREYApp)

/**
 *  Create a remote element interaction for a passed in GREYMatcher.
 *
 *  @param  elementMatcher The GREYMatcher to be passed to the element interaction.
 *  @return A remote object that is connected to an object of class GREYElementInteraction.
 */
- (GREYElementInteraction *)interactionWithMatcher:(id<GREYMatcher>)elementMatcher;

@end
