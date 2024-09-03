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

#import "GREYConstants.h"
#import "GREYDiagnosable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A protocol for actions that are performed on accessibility elements.
 */
@protocol GREYAction <GREYDiagnosable>

/**
 * Perform the action specified by the GREYAction object on an @c element if and only if the
 * @c element matches the constraints of the action.
 *
 * @param      element    The element the action is to be performed on. This must not be @c nil.
 * @param[out] errorOrNil Error that will be populated on failure. The implementing class should
 *                        handle the behavior when it is @c nil by, for example, logging the error
 *                        or throwing an exception.
 *
 * @return @c YES if the action succeeded, else @c NO. If an action returns @c NO, it does not
 *         mean that the action was not performed at all but somewhere during the action execution
 *         the error occurred and so the UI may be in an unrecoverable state.
 */
- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil;

/**
 * A method to get the name of this action.
 *
 * @return The name of the action. If the action fails, then the name is printed along with all
 *         other relevant information.
 */
- (NSString *)name;

/**
 * Whether or not the corresponding action should be run on the background thread or on the main
 * thread after the element is matched. If action is run on the background thread after element is
 * found, EarlGrey loses control of the main thread. This leaves room for the application to change
 * the UI state of the application before action is performed without EarlGrey's knowledge. As this
 * synchronization gap may cause stability issues, most of the actions should be run on the main
 * thread right after matching is completed. Some actions (like GREYSwipeAction) should be left
 * running on the background thread as it is more similar to how the system behaves when they are
 * performed or if it's a long running action.
 */
- (BOOL)shouldRunOnMainThread;

/**
 * A method to get the type of this action.
 *
 * @return The type of the action.
 */
- (GREYActionType)type;

@end

NS_ASSUME_NONNULL_END
