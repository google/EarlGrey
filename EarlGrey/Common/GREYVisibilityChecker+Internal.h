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
 *  @file GREYVisibilityChecker+Internal.h
 *  @brief Exposes GREYVisibilityChecker' interfaces and methods that are otherwise private
 *  for testing purposes.
 */

@interface GREYVisibilityChecker (Internal)

/**
 *   @return The last known original image used by the visibility checker.
 *
 *   @remark This is available only for internal testing purposes.
 */
+ (UIImage *)grey_lastActualBeforeImage;
/**
 *   @return The last known actual color shifted image used by visibility checker.
 *
 *   @remark This is available only for internal testing purposes.
 */
+ (UIImage *)grey_lastActualAfterImage;
/**
 *   @return The last known actual color shifted image used by visibility checker.
 *
 *   @remark This is available only for internal testing purposes.
 */
+ (UIImage *)grey_lastExpectedAfterImage;

@end
