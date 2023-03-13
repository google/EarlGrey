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

/** An object to encapsulate essential information about a touch. */
@interface GREYTouchInfo : NSObject

/** Array of @c NSValue wrapping @c CGPoint (one for each finger) where touch will be delivered. */
@property(nonatomic, readonly) NSArray *points;

/** The phases (began, moved etc) of the UITouch object. */
@property(nonatomic, assign, readonly) UITouchPhase phase;

/** The number of taps that occurred for this touch within a predefined period of time. */
@property(nonatomic, assign, readonly) NSUInteger tapCount;

/** Delays touch delivery by this amount since the last touch delivery. */
@property(nonatomic, readonly) NSTimeInterval deliveryTimeDeltaSinceLastTouch;

/** The convenient initializer for the designated initializer with `tapCount` set to 1. */
- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                              phase:(UITouchPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds;

/**
 * Initializes this object to represent a touch at the given @c points.
 *
 * @param points                         The CGPoints where the touches are to be delivered.
 * @param tapCount                       The number of taps that occurred for this touch within a
 *                                       predefined period of time.
 * @param phase                          Specifies the touch's phase.
 * @param timeDeltaSinceLastTouchSeconds The relative injection time from the time last
 *                                       touch point was injected. It is also used as the
 *                                       expected delivery time.
 *
 * @return An instance of GREYTouchInfo, initialized with all required data.
 */
- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                       withTapCount:(NSUInteger)tapCount
                              phase:(UITouchPhase)phase
    deliveryTimeDeltaSinceLastTouch:(NSTimeInterval)timeDeltaSinceLastTouchSeconds
    NS_DESIGNATED_INITIALIZER;

/**
 * @remark init is not available. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end
