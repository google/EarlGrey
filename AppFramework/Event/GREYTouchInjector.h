//
// Copyright 2018 Google Inc.
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

#import "GREYTouchInfo.h"
#import "GREYDefines.h"

/**
 *  A touch injector that delivers a complete touch sequence to mimic physical user interaction
 *  with the app under test. Buffers all touch events until @c start is called.
 */
@interface GREYTouchInjector : NSObject

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Initializes with the @c window to which touches will be delivered.
 *
 *  @param window The window that receives the touches.
 *
 *  @return An instance of GREYTouchInjector.
 */
- (instancetype)initWithWindow:(UIWindow *)window NS_DESIGNATED_INITIALIZER;

/**
 *  Enqueues @c touchInfo that will be materialized into a UITouch and delivered to application.
 *
 *  @param touchInfo The info that is used to create the UITouch. If it represents a last touch
 *                   in a sequence, the specified @c point value is ignored and injector
 *                   automatically picks the previous point where touch occurred to deliver
 *                   the last touch.
 */
- (void)enqueueTouchInfoForDelivery:(GREYTouchInfo *)touchInfo;

/**
 *  Waits for all enqueued touches to be injected into the system.
 *
 *  This is a synchronous call and can be made on any thread but the actual
 *  touch will be delivered on the main thread, as expected.
 */
- (void)waitUntilAllTouchesAreDelivered;

@end
