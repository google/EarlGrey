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

#import "NSURLSession+GREYApp.h"

#include <objc/runtime.h>

#import "__NSCFLocalDataTask_GREYApp.h"
#import "GREYFatalAsserts.h"
#import "GREYDefines.h"
#import "GREYObjcRuntime.h"
#import "GREYSwizzler.h"

/**
 * Type of the handlers used as NSURLSessionTask's completion blocks.
 */
typedef void (^GREYTaskCompletionBlock)(NSData *data, NSURLResponse *response, NSError *error);

@implementation NSURLSession (GREYAdditions)

+ (void)load {
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
  SEL swizzledSelector = @selector(greyswizzled_dataTaskWithRequest:completionHandler:);
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:originalSelector
                                    withMethod:swizzledSelector];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[NSURLSession %@]",
                             NSStringFromSelector(originalSelector));
  if (iOS13_OR_ABOVE()) {
    originalSelector = @selector(dataTaskWithRequest:);
    swizzledSelector = @selector(greyswizzled_dataTaskWithRequest:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[NSURLSession %@]",
                               NSStringFromSelector(originalSelector));

    originalSelector = @selector(dataTaskWithURL:completionHandler:);
    swizzledSelector = @selector(greyswizzled_dataTaskWithURL:completionHandler:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[NSURLSession %@]",
                               NSStringFromSelector(originalSelector));

    originalSelector = @selector(dataTaskWithURL:);
    swizzledSelector = @selector(greyswizzled_dataTaskWithURL:);
    swizzleSuccess = [swizzler swizzleClass:self
                      replaceInstanceMethod:originalSelector
                                 withMethod:swizzledSelector];
    GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[NSURLSession %@]",
                               NSStringFromSelector(originalSelector));
  }
}

#pragma mark - Swizzled Implementation

- (NSURLSessionDataTask *)greyswizzled_dataTaskWithURL:(NSURL *)url {
  SwizzleDelegateForSession(self);
  NSURLSessionDataTask *task =
      INVOKE_ORIGINAL_IMP1(NSURLSessionDataTask *, @selector(greyswizzled_dataTaskWithURL:), url);
  if (!self.delegate) {
    [(id)task grey_neverTrack];
  }
  return task;
}

- (NSURLSessionDataTask *)greyswizzled_dataTaskWithURL:(NSURL *)url
                                     completionHandler:(GREYTaskCompletionBlock)completionHandler {
  SwizzleDelegateForSession(self);
  __weak __block id weakTask;
  GREYTaskCompletionBlock wrappedHandler = nil;
  if (completionHandler) {
    wrappedHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
      completionHandler(data, response, error);
      [weakTask grey_untrack];
    };
  }

  NSURLSessionDataTask *task = INVOKE_ORIGINAL_IMP2(
      NSURLSessionDataTask *, @selector(greyswizzled_dataTaskWithURL:completionHandler:), url,
      wrappedHandler);

  if (!self.delegate && !completionHandler) {
    [(id)task grey_neverTrack];
  } else {
    weakTask = task;
  }
  return task;
}

- (NSURLSessionDataTask *)greyswizzled_dataTaskWithRequest:(NSURLRequest *)request {
  SwizzleDelegateForSession(self);
  NSURLSessionDataTask *task = INVOKE_ORIGINAL_IMP1(
      NSURLSessionDataTask *, @selector(greyswizzled_dataTaskWithRequest:), request);
  if (!self.delegate) {
    [(id)task grey_neverTrack];
  }
  return task;
}

- (NSURLSessionDataTask *)greyswizzled_dataTaskWithRequest:(NSURLRequest *)request
                                         completionHandler:(GREYTaskCompletionBlock)handler {
  SwizzleDelegateForSession(self);
  __weak __block id weakTask;
  GREYTaskCompletionBlock wrappedHandler = nil;
  if (handler) {
    wrappedHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {
      handler(data, response, error);
      [weakTask grey_untrack];
    };
  }

  NSURLSessionDataTask *task = INVOKE_ORIGINAL_IMP2(
      NSURLSessionDataTask *, @selector(greyswizzled_dataTaskWithRequest:completionHandler:),
      request, wrappedHandler);

  if (!self.delegate && !handler) {
    [(id)task grey_neverTrack];
  } else {
    weakTask = task;
  }
  return task;
}

- (void)greyswizzled_URLSession:(NSURLSession *)session
                           task:(NSURLSessionTask *)task
           didCompleteWithError:(NSError *)error {
  INVOKE_ORIGINAL_IMP3(void, @selector(greyswizzled_URLSession:task:didCompleteWithError:), session,
                       task, error);
  // Now untrack *after* the delegate method has been invoked.
  id greyTask = task;
  if ([greyTask respondsToSelector:@selector(grey_untrack)]) {
    [greyTask grey_untrack];
  }
}

/**
 * Swizzles the URLSession:task:didCompleteWithError: method of the delegate in order to track the
 * delegate callbacks.
 *
 * @param session The NSURLSession that is to be tracked.
 */
static void SwizzleDelegateForSession(NSURLSession *session) {
  // Swizzle the session delegate class if not yet done.
  id delegate = session.delegate;
  if (!delegate) {
    return;
  }
  SEL swizzledSel = @selector(greyswizzled_URLSession:task:didCompleteWithError:);
  SEL originalSel = @selector(URLSession:task:didCompleteWithError:);
  // Add a check for a proxy delegate in the case it might respond @c YES to `respondsToSelector:`
  // but `class_getInstanceMethod` returns nil. Forward the target until the right delegate object
  // is found, if any.
  id nextForwardingDelegate;
  while ((nextForwardingDelegate = [delegate forwardingTargetForSelector:originalSel])) {
    delegate = nextForwardingDelegate;
  }
  Class delegateClass = [delegate class];

  if (![delegateClass instancesRespondToSelector:swizzledSel]) {
    // If delegate does not exist or if it does not implement the delegate method, then this request
    // need not be tracked as its completion/failure does not trigger any delegate callbacks.
    if ([delegate respondsToSelector:originalSel]) {
      Class selfClass = [session class];
      // Double-checked locking to prevent multiple swizzling attempts of the same class.
      @synchronized(selfClass) {
        if (![delegateClass instancesRespondToSelector:swizzledSel]) {
          [GREYObjcRuntime addInstanceMethodToClass:delegateClass
                                       withSelector:swizzledSel
                                          fromClass:selfClass];
          GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
          BOOL swizzleSuccess = [swizzler swizzleClass:delegateClass
                                 replaceInstanceMethod:originalSel
                                            withMethod:swizzledSel];
          GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle -[%@ %@] in %@",
                                     delegateClass, NSStringFromSelector(originalSel), delegate);
        }
      }
    }
  }
}

@end
