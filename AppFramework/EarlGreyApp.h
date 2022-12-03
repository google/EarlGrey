//
// Copyright 2022 Google Inc.
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
 * An umbrella header that contains all of the headers required for creating
 * custom actions, matchers and assertions along with any synchronization
 * utilities.
 *
 * This file is to only be imported in a Helper Lib for creating custom
 * interactions that are to be run in the app-under-test process.
 */

// Headers shared for both the app-under-test binary and testing binary.
#import "ExposedForTesting.h"

// Synchronization APIs
#import "GREYDispatchQueueIdlingResource.h"
#import "GREYManagedObjectContextIdlingResource.h"
#import "GREYOperationQueueIdlingResource.h"
#import "GREYSyncAPI.h"
#import "GREYUIThreadExecutor+GREYApp.h"
#import "GREYUIThreadExecutor+Private.h"
#import "GREYUIThreadExecutor.h"

// Miscellaneous APIs
#import "GREYElementFinder.h"
#import "GREYAppError.h"
#import "GREYFailureScreenshotter.h"
#import "GREYSyntheticEvents.h"
