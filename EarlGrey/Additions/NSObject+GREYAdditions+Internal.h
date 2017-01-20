//
// Copyright 2016 Google Inc.
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

/**
 *  @file NSObject+GREYAdditions+Internal.h
 *  @brief Exposes NSObject+GREYAdditions' interfaces and methods that are otherwise private for
 *  testing purposes.
 */

@interface NSObject (Internal)

/**
 *  Swizzle a selector with a particular object after a specified delay time interval in a
 *  specific run loop mode.
 *
 *  @param aSelector  The selector to be swizzled.
 *  @param anArgument The object to swizzle the selector with.
 *  @param delay      The NSTimeInterval after which the swizzling is to be done.
 *  @param modes      The run loop mode to perform the swizzling in.
 *
 *  @remark This is available only for internal testing purposes.
 */
- (void)greyswizzled_performSelector:(SEL)aSelector
                          withObject:(id)anArgument
                          afterDelay:(NSTimeInterval)delay
                             inModes:(NSArray *)modes;

@end
