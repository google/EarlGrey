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

NS_ASSUME_NONNULL_BEGIN

/**
 * Filter found elements from an element finder based on patterns seen in iOS improvements.
 */
@interface GREYElementFilter : NSObject

/**
 * De-dupes the list of elements by removing any accessibility element that has its parent
 * UITextField present. If no such combination exists, or if elements array does not contain
 * exactly two elements, it is returned as is.
 *
 * @param elements An NSArray of elements found from an element matcher.
 *
 * @return A UITextField if the matched elements were a UITextfield and its accessibility element,
 *         else the matched element(s).
 */
+ (NSArray<id> *)dedupedTextFieldFromElements:(NSArray<id> *)elements;

@end

NS_ASSUME_NONNULL_END
