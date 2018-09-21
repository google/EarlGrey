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

#ifndef GREY_APP_STATE_H
#define GREY_APP_STATE_H

#import <Foundation/Foundation.h>

/**
 *  Non-idle states that the App can be at any given point in time.
 *  These states are not mutually exclusive and can be combined together using Bitwise-OR to
 *  represent multiple states.
 */
typedef NS_OPTIONS(NSUInteger, GREYAppState) {
  /**
   *  Idle state implies App is not undergoing any state changes and it is OK to interact with it.
   */
  kGREYIdle = 0,
  /**
   *  View is pending draw or layout pass.
   */
  kGREYPendingDrawLayoutPass = (1UL << 0),
  /**
   *  Waiting for viewDidAppear: method invocation.
   */
  kGREYPendingViewsToAppear = (1UL << 1),
  /**
   *  Waiting for viewDidDisappear: method invocation.
   */
  kGREYPendingViewsToDisappear = (1UL << 2),
  /**
   *  Pending keyboard transition.
   */
  kGREYPendingKeyboardTransition = (1UL << 3),
  /**
   *  Waiting for CA animation to complete.
   */
  kGREYPendingCAAnimation = (1UL << 4),
  /**
   *  Waiting for a UIAnimation to be marked as stopped.
   */
  kGREYPendingUIAnimation = (1UL << 5),
  /**
   *  Pending root view controller to be set.
   */
  kGREYPendingRootViewControllerToAppear = (1UL << 6),
  /**
   *  Pending a UIWebView async load request
   */
  kGREYPendingUIWebViewAsyncRequest = (1UL << 7),
  /**
   *  Pending a network request completion.
   */
  kGREYPendingNetworkRequest = (1UL << 8),
  /**
   *  Pending gesture recognition.
   */
  kGREYPendingGestureRecognition = (1UL << 9),
  /**
   *  Waiting for UIScrollView to finish scrolling.
   */
  kGREYPendingUIScrollViewScrolling = (1UL << 10),
  /**
   *  [UIApplication beginIgnoringInteractionEvents] was called and all interaction events are
   *  being ignored.
   */
  kGREYIgnoringSystemWideUserInteraction = (1UL << 11),
};

#endif /* GREY_APP_STATE_H */
