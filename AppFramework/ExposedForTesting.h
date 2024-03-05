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
 * An umbrella header that contains all of the headers that are public to both
 * the app-under-test binary and testing binary.
 */

// EarlGrey interaction APIs
#import "GREYElementInteraction.h"
#import "GREYInteraction.h"

// EarlGrey matcher APIs
#import "GREYAllOf.h"
#import "GREYAnyOf.h"
#import "GREYMatchers.h"
#import "GREYMatchersShorthand.h"
#import "GREYBaseMatcher.h"
#import "GREYDescription.h"
#import "GREYElementMatcherBlock+Private.h"
#import "GREYElementMatcherBlock.h"
#import "GREYLayoutConstraint.h"
#import "GREYMatcher.h"

// EarlGrey action and assertion APIs
#import "GREYAction.h"
#import "GREYActionBlock.h"
#import "GREYActions.h"
#import "GREYActionsShorthand.h"
#import "GREYBaseAction.h"
#import "GREYAssertion.h"
#import "GREYAssertionBlock.h"
#import "GREYAssertionDefinesPrivate.h"
#import "GREYDescribeVariable.h"

// EarlGrey RMI (Remote Method Invocation) APIs and eDO
#import "GREYHostApplicationDistantObject+GREYTestHelper.h"
#import "GREYDistantObjectUtils.h"
#import "GREYHostApplicationDistantObject.h"
#import "GREYHostBackgroundDistantObject.h"
#import "GREYTestApplicationDistantObject.h"
#import "EDOHostPort.h"
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDORemoteVariable.h"
#import "EDOServicePort.h"
#import "NSObject+EDOBlockedType.h"
#import "NSObject+EDOValueObject.h"
#import "NSObject+EDOWeakObject.h"

// EarlGrey Synchronization APIs
#import "GREYIdlingResource.h"

// Miscellaneous APIs
#import "GREYKeyboard.h"
#import "NSFileManager+GREYCommon.h"
#import "NSObject+GREYCommon.h"
#import "GREYAppState.h"
#import "GREYConfigKey.h"
#import "GREYConfiguration.h"
#import "GREYError.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYConstants.h"
#import "GREYDefines.h"
#import "GREYDiagnosable.h"
#import "GREYLogger.h"
#import "GREYSwizzler.h"
#import "GREYElementHierarchy.h"
#import "GREYScreenshotter.h"
#import "GREYUILibUtils.h"
