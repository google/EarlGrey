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

#import <UIKit/UIKit.h>

#import "GREYTraversalViewProperties.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A private wrapper used to store information that is essential for printing the UI hierarchy
 *  appropriately and in correct order.
 */
@interface GREYTraversalObject : NSObject

/**
 *  The UI element that the GREYHierarchyObject is wrapped around.
 */
@property(nonatomic, strong) id element;

/**
 *  An NSUInteger representing the number of parent-child relationships from the root element
 *  to the current element.
 */
@property(nonatomic) NSUInteger level;

/**
 *  Class that carries useful information about the traversing view. @c nil if
 *  the @c element is a non-UIView.
 */
@property(nonatomic, strong, nullable) GREYTraversalViewProperties *properties;

@end

NS_ASSUME_NONNULL_END
