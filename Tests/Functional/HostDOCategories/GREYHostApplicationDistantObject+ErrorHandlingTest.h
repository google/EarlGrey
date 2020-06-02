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

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the error handling test. */
@interface GREYHostApplicationDistantObject (ErrorHandlingTest)

/**
 * @c returns An error populated by GREYError with the UI Hierarchy.
 */
- (NSError *)errorPopulatedInTheApp;

/**
 * @c returns A simple error created with the UI Hierarchy.
 */
- (NSError *)errorCreatedInTheApp;

/**
 * @return A simple error nested with a GREYError containing the UI Hierarchy.
 */
- (NSError *)nestedErrorWithHierarchyCreatedInTheApp;

/**
 * @return A simple error nested error with no UI hierarchy.
 */
- (NSError *)simpleNestedError;

/**
 * Dispatches a sleep on the main thread of the application for 10 seconds. Used for errors with
 * non-GREYInteraction based APIs.
 */
- (void)induceNonTactileActionTimeoutInTheApp;

/**
 * @return An assertion that always fails and sets a generic error.
 */
- (id<GREYAssertion>)failingAssertion;

/**
 * @return An action that always fails and sets a generic error.
 */
- (id<GREYAction>)failingAction;
@end
