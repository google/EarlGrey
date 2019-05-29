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

/**
 *  @file GREYExposed.h
 *  @brief Exposes all IOHID event and private APIs required to create synthetic touches.
 *  Source for IOHID event types:
 *  https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-1035.41.2/IOHIDFamily/IOHIDEventTypes.h.auto.html
 *
 *  @remark Most of the code here is undocumented. Refer to the open sourced headers above for
 *  complete documentation.
 */

#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

typedef struct __IOHIDEvent *IOHIDEventRef;

#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

enum {
  kIOHIDDigitizerEventRange = 1 << 0,
  kIOHIDDigitizerEventTouch = 1 << 1,
  kIOHIDDigitizerEventPosition = 1 << 2,
  kIOHIDDigitizerEventStop = 1 << 3,
  kIOHIDDigitizerEventPeak = 1 << 4,
  kIOHIDDigitizerEventIdentity = 1 << 5,
  kIOHIDDigitizerEventAttribute = 1 << 6,
  kIOHIDDigitizerEventCancel = 1 << 7,
  kIOHIDDigitizerEventStart = 1 << 8,
  kIOHIDDigitizerEventResting = 1 << 9,
  kIOHIDDigitizerEventFromEdgeFlat = 1 << 10,
  kIOHIDDigitizerEventFromEdgeTip = 1 << 11,
  kIOHIDDigitizerEventFromCorner = 1 << 12,
  kIOHIDDigitizerEventSwipePending = 1 << 13,
  kIOHIDDigitizerEventFromEdgeForcePending = 1 << 14,
  kIOHIDDigitizerEventFromEdgeForceActive = 1 << 15,
  kIOHIDDigitizerEventForcePopped = 1 << 16,
  kIOHIDDigitizerEventSwipeUp = 1 << 24,
  kIOHIDDigitizerEventSwipeDown = 1 << 25,
  kIOHIDDigitizerEventSwipeLeft = 1 << 26,
  kIOHIDDigitizerEventSwipeRight = 1 << 27,
  kIOHIDDigitizerEventEstimatedAltitude = 1 << 28,
  kIOHIDDigitizerEventEstimatedAzimuth = 1 << 29,
  kIOHIDDigitizerEventEstimatedPressure = 1 << 30,
  kIOHIDDigitizerEventSwipeMask = 0xF << 24,
};
typedef uint32_t IOHIDDigitizerEventMask;

enum {
  kIOHIDEventOptionNone = 0,
};
typedef uint32_t IOHIDEventOptionBits;
typedef uint32_t IOHIDEventField;

enum {
  kIOHIDDigitizerTransducerTypeStylus = 0,
  kIOHIDDigitizerTransducerTypePuck,
  kIOHIDDigitizerTransducerTypeFinger,
  kIOHIDDigitizerTransducerTypeHand
};
typedef uint32_t IOHIDDigitizerTransducerType;

enum {
  kIOHIDEventTypeNULL,  // 0
  kIOHIDEventTypeVendorDefined,
  kIOHIDEventTypeButton,
  kIOHIDEventTypeKeyboard,
  kIOHIDEventTypeTranslation,
  kIOHIDEventTypeRotation,  // 5
  kIOHIDEventTypeScroll,
  kIOHIDEventTypeScale,
  kIOHIDEventTypeZoom,
  kIOHIDEventTypeVelocity,
  kIOHIDEventTypeOrientation,  // 10
  kIOHIDEventTypeDigitizer,
  kIOHIDEventTypeAmbientLightSensor,
  kIOHIDEventTypeAccelerometer,
  kIOHIDEventTypeProximity,
  kIOHIDEventTypeTemperature,  // 15
  kIOHIDEventTypeNavigationSwipe,
  kIOHIDEventTypePointer,
  kIOHIDEventTypeProgress,
  kIOHIDEventTypeMultiAxisPointer,
  kIOHIDEventTypeGyro,  // 20
  kIOHIDEventTypeCompass,
  kIOHIDEventTypeZoomToggle,
  kIOHIDEventTypeDockSwipe,
  kIOHIDEventTypeSymbolicHotKey,
  kIOHIDEventTypePower,  // 25
  kIOHIDEventTypeLED,
  kIOHIDEventTypeFluidTouchGesture,
  kIOHIDEventTypeBoundaryScroll,
  kIOHIDEventTypeBiometric,
  kIOHIDEventTypeUnicode,  // 30
  kIOHIDEventTypeAtmosphericPressure,
  kIOHIDEventTypeForce,
  kIOHIDEventTypeMotionActivity,
  kIOHIDEventTypeMotionGesture,
  kIOHIDEventTypeGameController,  // 35
  kIOHIDEventTypeHumidity,
  kIOHIDEventTypeCollection,
  kIOHIDEventTypeBrightness,
  kIOHIDEventTypeCount,

  // DEPRECATED:
  kIOHIDEventTypeSwipe = kIOHIDEventTypeNavigationSwipe,
  kIOHIDEventTypeMouse = kIOHIDEventTypePointer
};
typedef uint32_t IOHIDEventType;

#define IOHIDEventFieldBase(type) (type << 16)

enum {
  kIOHIDEventFieldDigitizerX = IOHIDEventFieldBase(kIOHIDEventTypeDigitizer),
  kIOHIDEventFieldDigitizerY,
  kIOHIDEventFieldDigitizerZ,
  kIOHIDEventFieldDigitizerButtonMask,
  kIOHIDEventFieldDigitizerType,
  kIOHIDEventFieldDigitizerIndex,
  kIOHIDEventFieldDigitizerIdentity,
  kIOHIDEventFieldDigitizerEventMask,
  kIOHIDEventFieldDigitizerRange,
  kIOHIDEventFieldDigitizerTouch,
  kIOHIDEventFieldDigitizerPressure,
  kIOHIDEventFieldDigitizerAuxiliaryPressure,
  kIOHIDEventFieldDigitizerTwist,
  kIOHIDEventFieldDigitizerTiltX,
  kIOHIDEventFieldDigitizerTiltY,
  kIOHIDEventFieldDigitizerAltitude,
  kIOHIDEventFieldDigitizerAzimuth,
  kIOHIDEventFieldDigitizerQuality,
  kIOHIDEventFieldDigitizerDensity,
  kIOHIDEventFieldDigitizerIrregularity,
  kIOHIDEventFieldDigitizerMajorRadius,
  kIOHIDEventFieldDigitizerMinorRadius,
  kIOHIDEventFieldDigitizerCollection,
  kIOHIDEventFieldDigitizerCollectionChord,
  kIOHIDEventFieldDigitizerChildEventMask,
  kIOHIDEventFieldDigitizerIsDisplayIntegrated,
  kIOHIDEventFieldDigitizerQualityRadiiAccuracy,
  kIOHIDEventFieldDigitizerGenerationCount,
  kIOHIDEventFieldDigitizerWillUpdateMask,
  kIOHIDEventFieldDigitizerDidUpdateMask,
  kIOHIDEventFieldDigitizerEstimatedMask
};

IOHIDEventRef IOHIDEventCreateDigitizerEvent(
    CFAllocatorRef allocator, uint64_t timestamp, IOHIDDigitizerTransducerType tranducerType,
    uint32_t index, uint32_t identifier, IOHIDDigitizerEventMask eventMask, uint32_t buttonEvent,
    IOHIDFloat x, IOHIDFloat y, IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat twist,
    boolean_t range, boolean_t touch, IOHIDEventOptionBits options);

IOHIDEventRef IOHIDEventCreateDigitizerFingerEvent(CFAllocatorRef allocator, uint64_t timeStamp,
                                                   uint32_t index, uint32_t identifier,
                                                   IOHIDDigitizerEventMask eventMask, IOHIDFloat x,
                                                   IOHIDFloat y, IOHIDFloat z,
                                                   IOHIDFloat tipPressure, IOHIDFloat twist,
                                                   boolean_t range, boolean_t touch,
                                                   IOHIDEventOptionBits options);

void IOHIDEventAppendEvent(IOHIDEventRef hidEvtRef, IOHIDEventRef childEvtRef,
                           IOHIDEventOptionBits opt);

void IOHIDEventSetIntegerValue(IOHIDEventRef hidEventRef, IOHIDEventField field, CFIndex value);

#pragma mark - Other Touch Injection APIs

/**
 *  A private class that represents touch related events. This is sent to UIApplication whenever a
 *  touch occurs.
 */
@interface UITouchesEvent : UIEvent

- (void)_setHIDEvent:(IOHIDEventRef)event;

- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)delayedDelivery;

// Only call this before sending new events. Don't call this after an event is sent.
- (void)_clearTouches;
@end

/**
 *  Exposes methods for fetching touch object container that can be sent to
 *  -[UIApplication sendEvent:]
 */
@interface UIApplication (GREYIOHIDEventTypes)
/**
 *  @return The shared UITouchesEvent object of the application, which is used to keep track of
 *          UITouch objects, and the relevant touch interaction state.
 */
- (UITouchesEvent *)_touchesEvent;
@end

/**
 *  Exposes methods for setting properties on UITouch for faking user interaction.
 */
@interface UITouch (GREYIOHIDEventTypes)

// Sets the @c location at which touch will be delivered. For new touches, set @c reset to @c YES.
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)reset;

- (void)setPhase:(UITouchPhase)phase;

// Must be set to YES for new touches.
- (void)setIsTap:(BOOL)isTap;

- (void)setIsDelayed:(BOOL)delayed;

- (void)setTapCount:(NSUInteger)tapCount;

// Must be set to YES for new touches.
- (void)_setIsFirstTouchForView:(BOOL)first;

- (void)setTimestamp:(NSTimeInterval)timestamp;
- (void)setView:(UIView *)view;
- (void)setWindow:(UIWindow *)window;

// Underlying HID finger event representing this touch.
- (void)_setHidEvent:(IOHIDEventRef)event;

- (void)_setPathIndex:(uint8_t)index;
- (void)_setPathIdentity:(uint8_t)index;
- (void)_setSenderID:(uint64_t)senderID;

@end
