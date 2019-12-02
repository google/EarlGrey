//
// Copyright 2019 Google Inc.
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

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Class that holds visibility information about the UI element in the hierarchy traversal.
 */
@interface GREYTraversalProperties : NSObject

/**
 *  A @c CGRect representing the boundary in which the current element clips to. @c CGRectNull
 *  if there is no boundary. It is represented relative to its parent element.
 */
@property(nonatomic, readonly) CGRect boundingRect;

/**
 *  A @c BOOL specifying whether the traversing element is hidden or not (either by itself or its
 *  ancestors' property). This is different from the UIView's @c hidden property as UIView's
 *  property does not propagate down through the hierarchy. This property is inherited to the
 *  children by performing an OR operation with its children's property.
 */
@property(nonatomic, readonly) BOOL hidden;

/**
 *  A @c CGFloat indicating the lowest alpha value in the hierarchy above the traversing element.
 *  This is different from the UIView's @c alpha property as UIView's property does not propagate
 *  through the hierarchy. This property is inherited to the children by performing an MIN operation
 *  with its children's alpha.
 */
@property(nonatomic, readonly) CGFloat lowestAlpha;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializer for the class.
 */
- (instancetype)initWithBoundingRect:(CGRect)boundingRect
                              hidden:(BOOL)hidden
                         lowestAlpha:(CGFloat)lowestAlpha NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
