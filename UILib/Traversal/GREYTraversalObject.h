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

#import "GREYTraversalProperties.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A private wrapper used to store information that is essential for printing the UI hierarchy
 * appropriately and in correct order.
 */
@interface GREYTraversalObject : NSObject

/**
 * The UI element that the GREYTraversalObject is wrapped around.
 */
@property(nonatomic, strong, readonly) id element;

/**
 * An NSUInteger representing the number of parent-child relationships from the root element
 * to the current element.
 */
@property(nonatomic, readonly) NSUInteger level;

/**
 * Dictionary class to store information about the @c element's visibility.
 */
@property(nonatomic, strong, readonly, nullable) GREYTraversalProperties *properties;

/**
 * @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Convenience initializer if @c properties is not used.
 */
- (instancetype)initWithElement:(id)element level:(NSUInteger)level;

/**
 * Designated initializer for the class.
 */
- (instancetype)initWithElement:(id)element
                          level:(NSUInteger)level
                     properties:(nullable GREYTraversalProperties *)properties
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
