//
// Copyright 2016 Google Inc.
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

#import "Synchronization/GREYAppStateTracker.h"

#import <objc/runtime.h>
#import <pthread.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYDefines.h"

/**
 *  Lock protecting element state map.
 */
static pthread_mutex_t gStateLock = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

@implementation GREYAppStateTracker {
  /**
   *  Mapping of each UI element to the state(s) it is in.
   *  Access should be guarded by @c stateLock lock.
   */
  NSMapTable *_elementToState;
  NSMapTable *_elementToCallStack;
}

+ (instancetype)sharedInstance {
  static GREYAppStateTracker *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[GREYAppStateTracker alloc] initOnce];
  });
  return instance;
}

/**
 *  Initializes the state tracker. Not thread-safe. Must be invoked under a race-free synchronized
 *  environment by the caller.
 *
 *  @return The initialized instance.
 */
- (instancetype)initOnce {
  self = [super init];
  if (self) {
    _elementToState = [NSMapTable weakToStrongObjectsMapTable];
    _elementToCallStack = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (NSString *)trackState:(GREYAppState)state forElement:(id)element {
  return [self grey_changeState:state forElement:element orExternalElementID:nil toBusy:YES];
}

- (void)untrackState:(GREYAppState)state forElementWithID:(NSString *)elementID {
  [self grey_changeState:state forElement:nil orExternalElementID:elementID toBusy:NO];
}

- (GREYAppState)currentState {
  return [[self grey_performBlockInCriticalSection:^id {
    // Recalc current UI state.
    GREYAppState curState = kGREYIdle;
    // Use keyEnumeration because it purges weak keys.
    for (NSNumber *state in [_elementToState objectEnumerator]) {
      curState |= [state unsignedIntegerValue];
    }
    return @(curState);
  }] unsignedIntegerValue];
}

/**
 *  @return A string description of current pending UI event state.
 */
- (NSString *)description {
  NSMutableString *description = [[NSMutableString alloc] init];

  [self grey_performBlockInCriticalSection:^id {
    GREYAppState state = [self currentState];
    [description appendString:[self stringFromState:state]];

    if (state != kGREYIdle) {
      [description appendString:@"\n\n"];
      [description appendString:@"Full state transition call stack for all elements:\n"];
      for (NSString *internalElementID in [_elementToCallStack keyEnumerator]) {
        NSNumber *stateNumber = (NSNumber *)[_elementToState objectForKey:internalElementID];
        [description appendFormat:@"<%@> => %@\n",
            internalElementID,
            [self stringFromState:[stateNumber unsignedIntegerValue]]];
        [description appendFormat:@"%@\n", [_elementToCallStack objectForKey:internalElementID]];
      }
    }
    return nil;
  }];
  return description;
}

- (NSString *)stringFromState:(GREYAppState)state {
  NSMutableArray *eventStateString = [[NSMutableArray alloc] init];
  if (state == kGREYIdle) {
    return @"Idle";
  }

  if (state & kGREYPendingDrawCycle) {
    [eventStateString addObject:@"Waiting for a draw/layout pass to complete"];
  }
  if (state & kGREYPendingViewsToAppear) {
    [eventStateString addObject:@"Waiting for UIViews to appear"];
  }
  if (state & kGREYPendingViewsToDisappear) {
    [eventStateString addObject:@"Waiting for UIViews to disappear"];
  }
  if (state & kGREYPendingKeyboardTransition) {
    [eventStateString addObject:@"Waiting for keyboard transition"];
  }
  if (state & kGREYPendingCAAnimation) {
    [eventStateString addObject:@"Waiting for CAAnimations to finish"];
  }
  if (state & kGREYPendingActionSheetToDisappear) {
    [eventStateString addObject:@"Waiting for UIActionSheet to disappear"];
  }
  if (state & kGREYPendingUIViewAnimation) {
    [eventStateString addObject:@"Waiting for UIView Animations to finish"];
  }
  if (state & kGREYPendingMoveToParent) {
    [eventStateString addObject:@"Waiting for UIViewController to move to parent"];
  }
  if (state & kGREYPendingRootViewControllerToAppear) {
    [eventStateString addObject:@"Waiting for root UIViewController to appear"];
  }
  if (state & kGREYPendingUIWebViewAsyncRequest) {
    [eventStateString addObject:@"Waiting for UIWebView to finish loading async request"];
  }
  if (state & kGREYPendingNetworkRequest) {
    [eventStateString addObject:@"Waiting for network requests to finish"];
  }
  if (state & kGREYPendingGestureRecognition) {
    [eventStateString addObject:@"Waiting for gesture recognizer to detect or fail"];
  }
  if (state & kGREYPendingUIScrollViewScrolling) {
    [eventStateString addObject:@"Waiting for UIScrollView to finish scrolling"];
  }
  if (state & kGREYPendingUIAnimation) {
    [eventStateString addObject:@"Waiting for UIAnimation to be marked as stopped"];
  }
  if (state & kGREYIgnoringSystemWideUserInteraction) {
    [eventStateString addObject:@"System Wide Events are being ignored"];
  }

  NSAssert([eventStateString count] > 0, @"Did we forget some states?");
  return [eventStateString componentsJoinedByString:@"\n"];
}

#pragma mark - Private

- (id)grey_performBlockInCriticalSection:(id (^)())block {
  int lock = pthread_mutex_lock(&gStateLock);
  NSAssert(lock == 0, @"Failed to lock.");
  id retVal = block();
  int unlock = pthread_mutex_unlock(&gStateLock);
  NSAssert(unlock == 0, @"Failed to unlock.");

  return retVal;
}

- (NSString *)grey_elementIDForElement:(id)element {
  return [NSString stringWithFormat:@"%@:%p", NSStringFromClass([element class]), element];
}

- (NSString *)grey_changeState:(GREYAppState)state
                  forElement:(id)element
         orExternalElementID:(NSString *)externalElementID
                      toBusy:(BOOL)busy {
  // It is possible for both element and externalElementID to be nil in cases where
  // the tracking logic tries to be overly safe and untrack elements which were never registered
  // before.
  if (!element && !externalElementID) {
    return nil;
  }

  NSAssert((element && !externalElementID || !element && externalElementID),
           @"Provide either a valid element or a valid externalElementID, not both.");
  return [self grey_performBlockInCriticalSection:^id {
    static void const *const stateAssociationKey = &stateAssociationKey;
    NSString *elementIDToReturn;

    // This autorelease pool makes sure we release any autoreleased objects added to the tracker
    // map. If we rely on external autorelease pools to be drained, we might delay removal of
    // released keys. In some cases, it could lead to a livelock (calling drainUntilIdle inside
    // drainUntilIdle where the first drainUntilIdle sets up an autorelease pool and the second
    // drainUntilIdle never returns because it is expecting the first drainUntilIdle's autorelease
    // pool to release the object so state tracker can return to idle state)
    @autoreleasepool {
      // Instead of tracking element as keys in NSMapTable, we track element ID, which is just a
      // string representation of the underlying element.
      // This element ID is then added to the element as an object association.
      // We leverage the fact that dealloc clears this object association, thereby releasing the
      // element ID and clearing NSMapTable's weak reference to it.
      // But there is a GOTCHA - We cannot return the same element ID we store in NSMapTable.
      // The returned element ID is an exact replica of the element ID added as object association.
      // Why? Because there are eactly two entities - us and the element's object association
      // that manages the lifetime of this internal element ID and don't expose it to
      // the outside world which can potentially alter the reference count by adding an extra
      // retain/autorelease and cause NSMapTable's reference to never clear out.
      NSString *potentialInternalElementID = externalElementID;
      if (!potentialInternalElementID) {
        potentialInternalElementID = [self grey_elementIDForElement:element];
      }

      NSString *internalElementID;
      // Get the internal element ID we store.
      for (NSString *key in [_elementToState keyEnumerator]) {
        if ([key isEqualToString:potentialInternalElementID]) {
          internalElementID = key;
          break;
        }
      }

      if (!internalElementID) {
        if (element) {
          // Explicit ownership.
          internalElementID = [[NSString alloc] initWithString:potentialInternalElementID];
          // When element deallocates, so will internalElementID causing our weak references to it
          // to be removed.
          objc_setAssociatedObject(element,
                                   stateAssociationKey,
                                   internalElementID,
                                   OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else {
          // External element id was specified and we couldn't find an internal element id
          // associated to the external element id. This could happen if element was deallocated and
          // we removed weak references to internal element id.
          return nil;
        }
      }

      // Always return a copy of internalElementID.
      elementIDToReturn = [NSString stringWithFormat:@"%@", internalElementID];
      NSNumber *originalStateNumber = [_elementToState objectForKey:internalElementID];
      GREYAppState originalState =
          originalStateNumber ? [originalStateNumber unsignedIntegerValue] : kGREYIdle;
      GREYAppState newState = busy ? (originalState | state) : (originalState & ~state);

      if (newState == kGREYIdle) {
        [_elementToState removeObjectForKey:internalElementID];
        [_elementToCallStack removeObjectForKey:internalElementID];
        if (element) {
          objc_setAssociatedObject(element, stateAssociationKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
      } else {
        // Add internalElementID to underlying element. When the underlying element deallocates,
        // we expect internalElementID to deallocate as well, causing it to be removed from
        // _elementToState and _elementToCallStack because it is a weakly held key.
        [_elementToState setObject:@(newState) forKey:internalElementID];
        // TODO: Consider tracking callStackSymbols for all states, not just the last one.
        [_elementToCallStack setObject:[NSThread callStackSymbols] forKey:internalElementID];
      }
    }
    return elementIDToReturn;
  }];
}

- (void)grey_clearState {
  [self grey_performBlockInCriticalSection:^id {
    while ([_elementToState count] > 0) {
      [_elementToState removeAllObjects];
      // _elementToCallStack can also hold references that when removed can enqueue more items to
      // _elementToState, so we remove both.
      [_elementToCallStack removeAllObjects];
    }
    return nil;
  }];
}

#pragma mark - Methods Only For Testing

- (GREYAppState)grey_lastKnownStateForElement:(id)element {
  return [[self grey_performBlockInCriticalSection:^id {
    NSString *internalElementID = [self grey_elementIDForElement:element];
    NSNumber *stateNumber = [_elementToState objectForKey:internalElementID];
    GREYAppState state = stateNumber ? [stateNumber unsignedIntegerValue] : kGREYIdle;

    return @(state);
  }] unsignedIntegerValue];
}

@end
