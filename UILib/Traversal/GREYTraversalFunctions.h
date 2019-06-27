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

NS_ASSUME_NONNULL_BEGIN

/**
 *  Explores the immediate children of @c element, including accessibility elements.
 *
 *  @param element The UI element whose children are to be explored.
 *
 *  @return Creates a new NSArray* that contains the immediate children of @c element. The children
 *  are ordered from front to back, meaning subviews that were added first are present later in the
 *  array. If no children exist, then an empty array is returned.
 */
NSArray<id> *GREYTraversalExploreImmediateChildren(id element);

NS_ASSUME_NONNULL_END
