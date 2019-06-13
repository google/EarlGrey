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

#import "AppFramework/Action/GREYActions.h"
#import "AppFramework/Error/GREYFailureScreenshotter.h"
#import "AppFramework/Event/GREYSyntheticEvents.h"
#import "AppFramework/Keyboard/GREYKeyboard.h"
#import "AppFramework/Matcher/GREYAllOf.h"
#import "AppFramework/Matcher/GREYAnyOf.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "AppFramework/Matcher/GREYNot.h"
#import "AppFramework/Synchronization/GREYUIThreadExecutor.h"
#import "CommonLib/Config/GREYConfiguration.h"
#import "CommonLib/DistantObject/GREYHostApplicationDistantObject.h"
#import "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h"
#import "CommonLib/DistantObject/GREYTestApplicationDistantObject.h"
#import "Service/Sources/EDOClientService.h"

// Stub classes defined in the host (app under test)

#pragma mark - HostApplication Stub

GREY_STUB_CLASS_IN_APP_MAIN_QUEUE(GREYHostApplicationDistantObject)

#pragma mark - Actions Stubs

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYActions)

#pragma mark - Matchers Stubs

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYAllOf)
GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYAnyOf)
GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYMatchers)
GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYNot)

#pragma mark - Host Background Stubs

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYHostBackgroundDistantObject)

#pragma mark - Synthetic Events Stub

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYSyntheticEvents)

#pragma mark - Synchronization Stubs

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYUIThreadExecutor)

#pragma mark - Keyboard Stub

GREY_STUB_CLASS_IN_APP_BACKGROUND_QUEUE(GREYKeyboard)

#pragma mark - Failure Screenshots Stub

GREY_STUB_CLASS_IN_APP_MAIN_QUEUE(GREYFailureScreenshotter)
