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
 * EarlGrey additions for UITextSelectionView, the view created for text fields, view etc. which
 * contains information for the caret (cursor) in a text related view.
 */
@interface UITextSelectionView_GREYApp : NSObject
@end

/**
 * EarlGrey additions for UITextInteractionAssistant, an internal iOS 17+ class that contains
 * information for the caret (cursor) in a text related view.
 */
@interface UITextInteractionAssistant_GREYApp : NSObject
@end

NS_ASSUME_NONNULL_END
