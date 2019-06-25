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

#import "GREYElementInteractionProxy.h"

#include <stdatomic.h>

#import "GREYHostBackgroundDistantObject+GREYApp.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYError.h"
#import "GREYElementInteractionErrorHandler.h"
#import <EDOHostService.h>

@implementation GREYElementInteractionProxy {
  /** App-side interaction instance. */
  GREYElementInteraction *_remoteElementInteraction;
  /**
   *  A separate queue to tunnel all canonical EarlGrey interactions i.e. perform, assert etc.
   */
  dispatch_queue_t _interactionProxyQueue;
}

@dynamic dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  GREYThrowOnNilParameter(elementMatcher);

  self = [super init];
  if (self) {
    _remoteElementInteraction =
        [GREYHostBackgroundDistantObject.sharedInstance interactionWithMatcher:elementMatcher];
    _interactionProxyQueue =
        dispatch_queue_create("com.google.earlgrey.interactionProxy", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (id<GREYInteraction>)performAction:(id)action {
  return [self performAction:action error:nil];
}

- (id<GREYInteraction>)performAction:(id)action error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(action, @"Action can't be nil.");
  __block __strong GREYError *interactionError = nil;
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction performAction:action error:&interactionError];
  }];
  [GREYElementInteractionErrorHandler handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion
                        error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(assertion, @"Assertion can't be nil.");
  __block __strong GREYError *interactionError = nil;
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction assert:assertion error:&interactionError];
  }];
  [GREYElementInteractionErrorHandler handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher
                                   error:(__autoreleasing NSError **)errorOrNil {
  GREYThrowOnNilParameterWithMessage(matcher, @"Matcher can't be nil.");
  __block __strong GREYError *interactionError = nil;
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction assertWithMatcher:matcher error:&interactionError];
  }];
  [GREYElementInteractionErrorHandler handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)inRoot:(id<GREYMatcher>)rootMatcher {
  GREYThrowOnNilParameterWithMessage(rootMatcher, @"Root Matcher can't be nil.");
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction inRoot:rootMatcher];
  }];
  return self;
}

- (id<GREYInteraction>)usingSearchAction:(id<GREYAction>)action
                    onElementWithMatcher:(id<GREYMatcher>)matcher {
  GREYThrowOnNilParameterWithMessage(action, @"Action can't be nil.");
  GREYThrowOnNilParameterWithMessage(matcher, @"Matcher can't be nil.");
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction usingSearchAction:action onElementWithMatcher:matcher];
  }];
  return self;
}

- (id<GREYInteraction>)atIndex:(NSUInteger)index {
  [self grey_dispatchBlockInBackgroundQueue:^{
    [self->_remoteElementInteraction atIndex:index];
  }];
  return self;
}

- (id<GREYInteraction>)includeStatusBar {
  __block id<GREYInteraction> includeStatusBar;
  [self grey_dispatchBlockInBackgroundQueue:^{
    includeStatusBar = [self->_remoteElementInteraction includeStatusBar];
  }];
  return includeStatusBar;
}

- (id<GREYInteractionDataSource>)dataSource {
  return _remoteElementInteraction.dataSource;
}

- (void)setDataSource:(id<GREYInteractionDataSource>)dataSource {
  _remoteElementInteraction.dataSource = dataSource;
}

#pragma mark - Private

/**
 *  Runs the given block in the background distant object's queue. It also takes
 *  the current (caller) queue's runloop and spins it, in order to enable the
 *  main queue to process messages from other queues. On completion of
 *  the block in the background distant object's queue, it stops spinning the caller
 *  queue and returns control to the caller queue.
 */
- (void)grey_dispatchBlockInBackgroundQueue:(void (^)(void))block {
  // This dispatches the EarlGrey call onto another queue so that the test's main queue
  // is freed up for handling any more events. Without this, deadlocks will be seen.
  // The timeout for the interaction is set to be forever since EarlGrey's interaction
  // should handle the interaction timeout.
  __block BOOL blockProcessed = NO;
  dispatch_block_t blockToStopMainRunloopSpinning =
      dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        blockProcessed = YES;
        CFRunLoopStop(CFRunLoopGetCurrent());
      });
  dispatch_async(_interactionProxyQueue, ^{
    block();
    dispatch_async(dispatch_get_main_queue(), blockToStopMainRunloopSpinning);
  });

  while (!blockProcessed) {
    CFRunLoopRun();
  }
  // Cancel any future executions of the CFRunLoppStop block.
  dispatch_block_cancel(blockToStopMainRunloopSpinning);
}

@end
