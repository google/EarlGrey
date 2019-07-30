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

#import "GREYElementInteraction.h"

#import "GREYAction.h"
#import "NSObject+GREYApp.h"
#import "GREYAssertions.h"
#import "GREYElementFinder.h"
#import "GREYInteractionDataSource.h"

#import "GREYAppError.h"
#import "GREYAllOf.h"
#import "GREYMatchers.h"
#import "GREYSyncAPI.h"
#import "GREYUIThreadExecutor.h"
#import "NSObject+GREYCommon.h"
#import "GREYAssertion.h"
#import "GREYFatalAsserts.h"
#import "GREYThrowDefines.h"
#import "GREYConfiguration.h"
#import "GREYError+Private.h"
#import "GREYErrorConstants.h"
#import "GREYObjectFormatter.h"
#import "GREYDefines.h"
#import "GREYLogger.h"
#import "GREYStopwatch.h"
#import "GREYMatcher.h"
#import "GREYElementProvider.h"
#import "GREYUIWindowProvider.h"
#import "GREYVisibilityChecker+Private.h"

@interface GREYElementInteraction () <GREYInteractionDataSource>
@end

@implementation GREYElementInteraction {
  id<GREYMatcher> _rootMatcher;
  id<GREYMatcher> _searchActionElementMatcher;
  id<GREYMatcher> _elementMatcher;
  id<GREYAction> _searchAction;
  // If _index is set to NSUIntegerMax, then it is unassigned.
  NSUInteger _index;
  // Include status bar in the interaction.
  BOOL _includeStatusBar;
}

@synthesize dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  GREYThrowOnNilParameter(elementMatcher);

  self = [super init];
  if (self) {
    _elementMatcher = elementMatcher;
    _index = NSUIntegerMax;
    [self setDataSource:self];
  }
  return self;
}

- (instancetype)inRoot:(id<GREYMatcher>)rootMatcher {
  _rootMatcher = rootMatcher;
  return self;
}

- (instancetype)atIndex:(NSUInteger)index {
  _index = index;
  return self;
}

#pragma mark - Package Internal

- (void)matchElementsWithTimeout:(CFTimeInterval)timeout
                 syncBeforeMatch:(BOOL)syncBeforeMatch
                 completionBlock:(void (^)(NSArray<id> *, GREYError *))completionBlock {
  GREYFatalAssert(completionBlock);

  GREYLogVerbose(@"Scanning for element matching: %@", _elementMatcher);
  id<GREYInteractionDataSource> strongDataSource = [self dataSource];
  GREYFatalAssertWithMessage(strongDataSource,
                             @"strongDataSource must be set before fetching UI elements");

  GREYElementProvider *entireRootHierarchyProvider =
      [GREYElementProvider providerWithRootProvider:[strongDataSource rootElementProvider]];
  id<GREYMatcher> elementMatcher = _elementMatcher;
  if (_rootMatcher) {
    elementMatcher = [[GREYAllOf alloc]
        initWithMatchers:@[ elementMatcher, [GREYMatchers matcherForAncestor:_rootMatcher] ]];
  }
  GREYElementFinder *elementFinder = [[GREYElementFinder alloc] initWithMatcher:elementMatcher];
  GREYStopwatch *elementFinderStopwatch = [[GREYStopwatch alloc] init];

  // Find the element in the current UI hierarchy.
  __block BOOL elementsFound = NO;
  void (^matchingBlock)(void) = ^{
    
    GREYFatalAssertMainThread();

    [elementFinderStopwatch start];
    
    NSArray *elements = [elementFinder elementsMatchedInProvider:entireRootHierarchyProvider];
    
    [elementFinderStopwatch stop];

    GREYLogVerbose(@"Finished scanning hierarchy for match %@ in %f seconds.",
                   self->_elementMatcher, [elementFinderStopwatch elapsedTime]);

    elementsFound = (elements.count > 0);
    if (elementsFound) {
      completionBlock(elements, nil);
    }
  };

  GREYError *error;
  GREYError *searchActionError;
  GREYError *executorError;

  // We want the search action to be performed at least once.
  static const UInt8 kMinimumSearchAttempts = 1;
  BOOL isSearchTimedOut = NO;
  UInt8 numSearchIterations = 0;

  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeout;
  for (; !elementsFound && !isSearchTimedOut; ++numSearchIterations) {
    @autoreleasepool {
      if (syncBeforeMatch || numSearchIterations > 0) {
        // Clamp the timeout to zero so the synchronization will not throw an exception.
        CFTimeInterval remainingTimeout = MAX(timeoutTime - CACurrentMediaTime(), 0);

        // If the @c syncBeforeMatch is YES, or the @c searchAction is being performed,
        // wait until the app becomes idle and then execute the @c matchingBlock right after the
        // synchronization so it looks at the stable UI on the main thread.
        // In case of a timeout, the block will not be executed and the error will be returned.
        [GREYUIThreadExecutor.sharedInstance executeSyncWithTimeout:remainingTimeout
                                                              block:matchingBlock
                                                              error:&executorError];
      } else {
        grey_dispatch_sync_on_main_thread(matchingBlock);
      }

      // Exits the loop early in case of successful matches or errors
      if (elementsFound || executorError) {
        break;
      } else if (!_searchAction) {
        NSString *desc = @"Interaction cannot continue because the desired element was not found.";
        error = GREYErrorMakeWithHierarchy(kGREYInteractionErrorDomain,
                                           kGREYInteractionElementNotFoundErrorCode, desc);
        break;
      } else if (searchActionError) {
        break;
      } else if (numSearchIterations >= kMinimumSearchAttempts &&
                 timeoutTime < CACurrentMediaTime()) {
        // When a @c searchAction is provided, it should be performed at least
        // @c kMinimumIterationAttempts of times, before it is considered to be a timeout.
        isSearchTimedOut = YES;
        break;
      }

      // Don't fail if this interaction error's out. It might still have revealed the element
      // we're looking for.
      [self grey_performSearchActionWithError:&searchActionError];
    }
  }

  if (elementsFound) {
    return;
  } else if (executorError && numSearchIterations <= 0) {
    // Errors during the synchronization before the match happens.
    // TODO: Add test coverage for this error. // NOLINT
    NSString *actionTimeoutDesc =
        [NSString stringWithFormat:@"App not idle within %g seconds.", timeout];
    error = GREYErrorNestedMake(kGREYInteractionErrorDomain, kGREYInteractionTimeoutErrorCode,
                                actionTimeoutDesc, executorError);
  } else if (searchActionError) {
    error =
        GREYErrorNestedMake(kGREYInteractionErrorDomain, kGREYInteractionElementNotFoundErrorCode,
                            @"Search action failed", searchActionError);
  } else if (executorError || isSearchTimedOut) {
    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    NSString *desc = [NSString stringWithFormat:@"Interaction timed out after %g seconds while "
                                                @"searching for element.",
                                                interactionTimeout];

    GREYError *timeoutError = GREYErrorMakeWithHierarchy(kGREYInteractionErrorDomain,
                                                         kGREYInteractionTimeoutErrorCode, desc);

    error = GREYErrorNestedMake(kGREYInteractionErrorDomain,
                                kGREYInteractionElementNotFoundErrorCode, @"", timeoutError);
  }

  GREYFatalAssertWithMessage(error != nil, @"Elements found but with an error: %@", error);
  grey_dispatch_sync_on_main_thread(^{
    completionBlock(nil, error);
  });
}

- (id<GREYInteraction>)includeStatusBar {
  _includeStatusBar = YES;
  return self;
}

#pragma mark - GREYInteractionDataSource

/**
 *  Default data source for this interaction if no datasource is set explicitly.
 */
- (id<GREYProvider>)rootElementProvider {
  return [GREYUIWindowProvider providerWithAllWindowsWithStatusBar:_includeStatusBar];
}

#pragma mark - GREYInteraction

- (instancetype)performAction:(id<GREYAction>)action {
  return [self performAction:action error:nil];
}

- (instancetype)performAction:(id<GREYAction>)action error:(NSError **)error {
  
  GREYLogVerbose(@"--Action started--");
  GREYLogVerbose(@"Action to perform: %@", [action name]);

  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];

  __block GREYError *actionError = nil;
  @autoreleasepool {
    // Create the user info dictionary for any notifications and set it up with the action.
    NSMutableDictionary *actionUserInfo = [[NSMutableDictionary alloc] init];
    [actionUserInfo setObject:action forKey:kGREYActionUserInfoKey];
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];

    CFTimeInterval interactionTimeout =
        GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    BOOL synchronizationRequired = GREY_CONFIG_BOOL(kGREYConfigKeySynchronizationEnabled);
    // Obtain all elements from the hierarchy and populate the passed error in case of
    // an element not being found.
    __block id element;
    
    [self matchElementsWithTimeout:interactionTimeout
                   syncBeforeMatch:synchronizationRequired
                   completionBlock:^(NSArray<id> *matchedElements, GREYError *error) {
                     actionError = error;
                     if (!actionError && matchedElements) {
                       // Get the uniquely matched element. If it is nil, then it means that
                       // there has been an error in finding a unique element, such as multiple
                       // matcher error.
                       element = [self grey_uniqueElementInMatchedElements:matchedElements
                                                                  andError:&actionError];
                     }

                     if (element) {
                       [actionUserInfo setObject:element forKey:kGREYActionElementUserInfoKey];
                     }
                     // Post notification in the main thread that the action is to be performed
                     // on the found element.
                     [defaultNotificationCenter
                         postNotificationName:kGREYWillPerformActionNotification
                                       object:nil
                                     userInfo:actionUserInfo];
                   }];

    if (element) {
      GREYLogVerbose(@"Performing action: %@\n with matcher: %@\n with root matcher: %@",
                     [action name], _elementMatcher, _rootMatcher);
      
      BOOL success = [action perform:element error:&actionError];
      
      if (!success) {
        // Action didn't succeed yet no error was set.
        if (!actionError) {
          actionError = GREYErrorMakeWithHierarchy(kGREYInteractionErrorDomain,
                                                   kGREYInteractionActionFailedErrorCode,
                                                   @"Reason for action failure was not provided.");
        }
      }
    } else if (!actionError) {
      // If no elements are found, neither the error is provided.
      actionError = GREYErrorMakeWithHierarchy(kGREYInteractionErrorDomain,
                                               kGREYInteractionActionFailedErrorCode,
                                               @"Reason for action failure was not provided.");
    }

    if (actionError) {
      // Add the error obtained from the action to the user info notification dictionary.
      [actionUserInfo setObject:actionError forKey:kGREYActionErrorUserInfoKey];
    }
    grey_dispatch_sync_on_main_thread(^{
      // Post notification for the process of an action's execution being completed. This
      // notification does not mean that the action was performed successfully.
      [defaultNotificationCenter postNotificationName:kGREYDidPerformActionNotification
                                               object:nil
                                             userInfo:actionUserInfo];
    });
  }
  [stopwatch stop];

  if (actionError) {
    [self grey_handleFailureOfAction:action actionError:actionError error:error];
    GREYLogVerbose(@"Action failed: %@ in %f seconds", [action name], [stopwatch elapsedTime]);
  } else {
    GREYLogVerbose(@"Action succeeded: %@ in %f seconds", [action name], [stopwatch elapsedTime]);
    // For a successful action, reset the visibility checker's saved images.
    [GREYVisibilityChecker resetVisibilityImages];
  }

  GREYLogVerbose(@"--Action finished--");
  
  return self;
}

- (instancetype)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (instancetype)assert:(id<GREYAssertion>)assertion error:(NSError **)error {
  
  GREYLogVerbose(@"--Assertion started--");
  GREYLogVerbose(@"Assertion to perform: %@", [assertion name]);

  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  [stopwatch start];
  __block GREYError *assertionError = nil;

  @autoreleasepool {
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];

    CGFloat interactionTimeout =
        (CGFloat)GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);
    BOOL synchronizationRequired = GREY_CONFIG_BOOL(kGREYConfigKeySynchronizationEnabled);
    
    [self
        matchElementsWithTimeout:interactionTimeout
                 syncBeforeMatch:synchronizationRequired
                 completionBlock:^(NSArray<id> *matchedElements, GREYError *error) {
                   // An error object that holds error due to element not found (if any). It
                   // is used only when an assertion fails because element was nil. That's
                   // when we surface this
                   GREYError *elementNotFoundError = error;

                   // Failure to find elements due to synchronization and report it as an
                   // error.
                   if (elementNotFoundError.domain == kGREYInteractionErrorDomain &&
                       elementNotFoundError.code == kGREYInteractionTimeoutErrorCode) {
                     assertionError = elementNotFoundError;
                   } else {
                     id element = (matchedElements.count != 0)
                                      ? [self grey_uniqueElementInMatchedElements:matchedElements
                                                                         andError:&assertionError]
                                      : nil;

                     // Create the user info dictionary for any notifications and set it up
                     // with the assertion.
                     NSMutableDictionary<NSString *, id> *assertionUserInfo =
                         [[NSMutableDictionary alloc] init];
                     [assertionUserInfo setObject:assertion forKey:kGREYAssertionUserInfoKey];

                     // Post notification for the assertion to be checked on the found
                     // element. We send the notification for an assert even if no element
                     // was found.
                     BOOL multipleMatchesPresent = NO;
                     if (element) {
                       [assertionUserInfo setObject:element
                                             forKey:kGREYAssertionElementUserInfoKey];
                     } else if (assertionError) {
                       // Check for multiple matchers since we don't want the assertion to be
                       // checked when this error surfaces.
                       multipleMatchesPresent =
                           (assertionError.code ==
                                kGREYInteractionMultipleElementsMatchedErrorCode ||
                            assertionError.code ==
                                kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode);
                       [assertionUserInfo setObject:assertionError
                                             forKey:kGREYAssertionErrorUserInfoKey];
                     }
                     [defaultNotificationCenter
                         postNotificationName:kGREYWillPerformAssertionNotification
                                       object:nil
                                     userInfo:assertionUserInfo];
                     GREYLogVerbose(
                         @"Performing assertion: %@\n with matcher: %@\n with root matcher: "
                         @"%@",
                         [assertion name], self -> _elementMatcher, self -> _rootMatcher);

                     // In the case of an assertion, we can have a nil element present as
                     // well. For this purpose, we check the assertion directly and see if
                     // there was any issue. The only case where we are completely sure we do
                     // not need to perform the action is in the case of a multiple matcher.
                     if (!multipleMatchesPresent) {
                       __block BOOL assertionSucceeded = NO;
                       
                       assertionSucceeded = [assertion assert:element error:&assertionError];
                       
                       if (!assertionSucceeded) {
                         // Set the elementNotFoundError to the assertionError since the
                         // error has been utilized already.
                         if ([assertionError.domain isEqualToString:kGREYInteractionErrorDomain] &&
                             (assertionError.code == kGREYInteractionElementNotFoundErrorCode)) {
                           assertionError = elementNotFoundError;
                         }
                         // Assertion didn't succeed yet no error was set.
                         if (!assertionError) {
                           assertionError = GREYErrorMakeWithHierarchy(
                               kGREYInteractionErrorDomain,
                               kGREYInteractionAssertionFailedErrorCode,
                               @"Reason for assertion failure was not provided.");
                         }
                         // Add the error obtained from the action to the user info
                         // notification dictionary.
                         [assertionUserInfo setObject:assertionError
                                               forKey:kGREYAssertionErrorUserInfoKey];
                       }
                     }

                     // Post notification for the process of an assertion's execution on the
                     // specified element being completed. This notification does not mean
                     // that the assertion was performed successfully.
                     [defaultNotificationCenter
                         postNotificationName:kGREYDidPerformAssertionNotification
                                       object:nil
                                     userInfo:assertionUserInfo];
                   }
                 }];
  }
  [stopwatch stop];

  if (assertionError) {
    GREYLogVerbose(@"Assertion failed: %@ in %f seconds", [assertion name],
                   [stopwatch elapsedTime]);
    [self grey_handleFailureOfAssertion:assertion assertionError:assertionError error:error];
  } else {
    GREYLogVerbose(@"Assertion succeeded: %@ in %f seconds", [assertion name],
                   [stopwatch elapsedTime]);
    // For a successful assertion, reset the visibility checker's saved images.
    [GREYVisibilityChecker resetVisibilityImages];
  }

  GREYLogVerbose(@"--Assertion finished--");
  
  return self;
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher error:(NSError **)errorOrNil {
  id<GREYAssertion> assertion = [GREYAssertions assertionWithMatcher:matcher];
  return [self assert:assertion error:errorOrNil];
}

- (instancetype)usingSearchAction:(id<GREYAction>)action
             onElementWithMatcher:(id<GREYMatcher>)matcher {
  _searchActionElementMatcher = matcher;
  _searchAction = action;
  return self;
}

#pragma mark - Private

/**
 *  From the set of matched elements, obtain one unique element for the provided matcher. In case
 *  there are multiple elements matched, then the one selected by the _@c index provided is chosen
 *  else the provided @c interactionError is populated.
 *
 *  @param[out] interactionError A passed error for populating if multiple elements are found.
 *                               If this is nil then cases like multiple matchers cannot be checked
 *                               for.
 *
 *  @return A uniquely matched element, if any.
 */
- (id)grey_uniqueElementInMatchedElements:(NSArray *)elements
                                 andError:(__strong GREYError **)interactionError {
  // If we find that multiple matched elements are present, we narrow them down based on
  // any index passed or populate the passed error if the multiple matches are present and
  // an incorrect index was passed.
  if (elements.count > 1) {
    // If the number of matched elements are greater than 1 then we have to use the index for
    // matching. We perform a bounds check on the index provided here and capture the error seen
    // if it fails.
    if (_index == NSUIntegerMax) {
      *interactionError = [self grey_errorForMultipleMatchingElements:elements
                                  withMatchedElementsIndexOutOfBounds:NO];
      return nil;
    } else if (_index >= elements.count) {
      *interactionError = [self grey_errorForMultipleMatchingElements:elements
                                  withMatchedElementsIndexOutOfBounds:YES];
      return nil;
    } else {
      return [elements objectAtIndex:_index];
    }
  }
  // If you haven't got a multiple / element not found error then you have one single matched
  // element and can select it directly.
  return [elements firstObject];
}

/**
 *  Handles failure of an @c action by capturing it in an error provided.
 *
 *  @param action      The action that failed.
 *  @param actionError Contains the reason for failure.
 *  @param[out] error  The out error (or nil) provided by the user.
 *
 *  @return Junk boolean value to suppress xcode warning to have "a non-void return
 *          value to indicate an error occurred"
 */
- (BOOL)grey_handleFailureOfAction:(id<GREYAction>)action
                       actionError:(GREYError *)actionError
                             error:(NSError **)error {
  GREYFatalAssert(actionError);

  // First check errors that can happen at the inner most level such as timeouts.
  NSDictionary *errorDescriptions =
      [[GREYError grey_nestedErrorDictionariesForError:actionError] objectAtIndex:0];
  NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

  NSString *reason = nil;
  if (errorDescriptions != nil) {
    NSString *errorDomain = errorDescriptions[kErrorDomainKey];
    NSInteger errorCode = [errorDescriptions[kErrorCodeKey] integerValue];
    if (([errorDomain isEqualToString:kGREYInteractionErrorDomain]) &&
        (errorCode == kGREYInteractionTimeoutErrorCode)) {
      errorDetails[kErrorDetailActionNameKey] = action.name;
      errorDetails[kErrorDetailRecoverySuggestionKey] = @"Increase timeout for matching element";
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
      NSArray *keyOrder = @[
        kErrorDetailActionNameKey, kErrorDetailElementMatcherKey, kErrorDetailRecoverySuggestionKey
      ];

      NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                              indent:kGREYObjectFormatIndent
                                                           hideEmpty:YES
                                                            keyOrder:keyOrder];
      reason = [NSString stringWithFormat:@"Matching element timed out.\n"
                                          @"Exception with Action: %@\n",
                                          reasonDetail];
    } else if (([errorDomain isEqualToString:kGREYUIThreadExecutorErrorDomain]) &&
               (errorCode == kGREYUIThreadExecutorTimeoutErrorCode)) {
      errorDetails[kErrorDetailActionNameKey] = action.name;
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

      NSArray *keyOrder = @[ kErrorDetailActionNameKey, kErrorDetailElementMatcherKey ];
      NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                              indent:kGREYObjectFormatIndent
                                                           hideEmpty:YES
                                                            keyOrder:keyOrder];
      reason = [NSString stringWithFormat:@"Timed out while waiting to perform action.\n"
                                          @"Exception with Action: %@\n",
                                          reasonDetail];

      [actionError setErrorInfo:errorDetails];
    }
  }

  // Second, check for errors with less specific reason (such as interaction error).
  if (reason.length == 0 && [actionError.domain isEqualToString:kGREYInteractionErrorDomain]) {
    NSString *searchAPIInfo = [self grey_searchActionDescription];

    switch (actionError.code) {
      case kGREYInteractionElementNotFoundErrorCode: {
        errorDetails[kErrorDetailActionNameKey] = action.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        errorDetails[kErrorDetailRecoverySuggestionKey] =
            @"Check if the element exists in the UI hierarchy printed below. If it exists, "
            @"adjust the matcher so that it accurately matches element.";
        errorDetails[kErrorDetailSearchActionInfoKey] = searchAPIInfo;

        NSArray *keyOrder = @[
          kErrorDetailActionNameKey, kErrorDetailElementMatcherKey,
          kErrorDetailRecoverySuggestionKey
        ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        reason = [NSString stringWithFormat:@"Cannot find UI element.\n"
                                            @"Exception with Action: %@\n",
                                            reasonDetail];

        [actionError setErrorInfo:errorDetails];
        break;
      }
      case kGREYInteractionMultipleElementsMatchedErrorCode: {
        errorDetails[kErrorDetailActionNameKey] = action.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        errorDetails[kErrorDetailRecoverySuggestionKey] =
            @"Create a more specific matcher to uniquely match an element. If that's not "
            @"possible then use atIndex: to select from one of the matched elements. Keep "
            @"in mind when using atIndex: that the order in which elements are "
            @"arranged may change, making your test brittle. If you are matching "
            @"on a UIButton, please use  grey_buttonTitle() with the accessibility "
            @"label instead. For UITextField, please use grey_textFieldValue().";
        errorDetails[kErrorDetailSearchActionInfoKey] = searchAPIInfo;

        NSArray *keyOrder = @[
          kErrorDetailActionNameKey, kErrorDetailElementMatcherKey,
          kErrorDetailRecoverySuggestionKey
        ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        reason = [NSString stringWithFormat:@"Multiple UI elements matched "
                                            @"for the given criteria.\n"
                                            @"Exception with Action: %@\n",
                                            reasonDetail];

        [actionError setErrorInfo:errorDetails];
        break;
      }
      case kGREYInteractionConstraintsFailedErrorCode: {
        NSArray *keyOrder = @[
          kErrorDetailActionNameKey, kErrorDetailElementDescriptionKey,
          kErrorDetailConstraintRequirementKey, kErrorDetailConstraintDetailsKey,
          kErrorDetailRecoverySuggestionKey
        ];
        NSDictionary *errorInfo = [(GREYError *)actionError errorInfo];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorInfo
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];

        reason = [NSString stringWithFormat:@"Cannot perform action due to "
                                            @"constraint(s) failure.\n"
                                            @"Exception with Action: %@\n",
                                            reasonDetail];
        NSString *nestedError = [GREYError grey_nestedDescriptionForError:actionError];
        errorDetails[NSLocalizedFailureReasonErrorKey] = nestedError.description;
        break;
      }
    }
  }

  if (reason.length == 0) {
    errorDetails[kErrorDetailActionNameKey] = action.name;
    errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

    NSArray *keyOrder = @[ kErrorDetailActionNameKey, kErrorDetailElementMatcherKey ];
    NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                            indent:kGREYObjectFormatIndent
                                                         hideEmpty:YES
                                                          keyOrder:keyOrder];
    reason = [NSString stringWithFormat:@"An action failed. "
                                        @"Please refer to the error trace below.\n"
                                        @"Exception with Action: %@\n",
                                        reasonDetail];
  }
  *error = [self grey_errorToReturnForInteractionError:actionError withReason:reason];
  return NO;
}

/**
 *  Handles failure of an @c assertion.
 *
 *  @param assertion      The asserion that failed.
 *  @param assertionError Contains the reason for the failure.
 *  @param[out] error     Error (or @c nil) provided by the user. When @c nil, an error is created
 *                        and sent back to be turned into an exception in the test component.
 *
 *  @return Junk boolean value to suppress xcode warning to have "a non-void return
 *          value to indicate an error occurred"
 */
- (BOOL)grey_handleFailureOfAssertion:(id<GREYAssertion>)assertion
                       assertionError:(GREYError *)assertionError
                                error:(NSError **)error {
  GREYFatalAssert(assertionError);

  // First check errors that can happens at the inner most level
  // for example: executor error
  NSDictionary *errorDescriptions =
      [[GREYError grey_nestedErrorDictionariesForError:assertionError] objectAtIndex:0];
  NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];
  NSString *reason = nil;

  if (errorDescriptions != nil) {
    NSString *errorDomain = errorDescriptions[kErrorDomainKey];
    NSInteger errorCode = [errorDescriptions[kErrorCodeKey] integerValue];
    if (([errorDomain isEqualToString:kGREYInteractionErrorDomain]) &&
        (errorCode == kGREYInteractionTimeoutErrorCode)) {
      errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
      errorDetails[kErrorDetailRecoverySuggestionKey] = @"Increase timeout for matching element";
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
      NSArray *keyOrder = @[
        kErrorDetailAssertCriteriaKey, kErrorDetailElementMatcherKey,
        kErrorDetailRecoverySuggestionKey
      ];

      NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                              indent:kGREYObjectFormatIndent
                                                           hideEmpty:YES
                                                            keyOrder:keyOrder];
      reason = [NSString stringWithFormat:@"Matching element timed out.\n"
                                          @"Exception with Assertion: %@\n",
                                          reasonDetail];

      [assertionError setErrorInfo:errorDetails];
    } else if (([errorDomain isEqualToString:kGREYUIThreadExecutorErrorDomain]) &&
               (errorCode == kGREYUIThreadExecutorTimeoutErrorCode)) {
      errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
      errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

      NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey, kErrorDetailElementMatcherKey ];
      NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                              indent:kGREYObjectFormatIndent
                                                           hideEmpty:YES
                                                            keyOrder:keyOrder];
      reason = [NSString stringWithFormat:@"Timed out while waiting to perform assertion.\n"
                                          @"Exception with Assertion: %@\n",
                                          reasonDetail];

      [assertionError setErrorInfo:errorDetails];
    }
  }

  // second, check for errors with less specific reason (such as interaction error)
  if (reason.length == 0 && [assertionError.domain isEqualToString:kGREYInteractionErrorDomain]) {
    NSString *searchAPIInfo = [self grey_searchActionDescription];

    switch (assertionError.code) {
      case kGREYInteractionElementNotFoundErrorCode: {
        errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        errorDetails[kErrorDetailRecoverySuggestionKey] =
            @"Check if the element exists in the UI hierarchy printed below. If it exists, "
            @"adjust the matcher so that it accurately matches element.";
        errorDetails[kErrorDetailSearchActionInfoKey] = searchAPIInfo;
        NSArray *keyOrder = @[
          kErrorDetailAssertCriteriaKey, kErrorDetailElementMatcherKey,
          kErrorDetailRecoverySuggestionKey
        ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        reason = [NSString stringWithFormat:@"Cannot find UI Element.\n"
                                            @"Exception with Assertion: %@\n",
                                            reasonDetail];

        [assertionError setErrorInfo:errorDetails];
        break;
      }
      case kGREYInteractionMultipleElementsMatchedErrorCode: {
        errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
        errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;
        errorDetails[kErrorDetailRecoverySuggestionKey] =
            @"Create a more specific matcher to narrow matched element";
        errorDetails[kErrorDetailSearchActionInfoKey] = searchAPIInfo;
        NSArray *keyOrder = @[
          kErrorDetailAssertCriteriaKey, kErrorDetailElementMatcherKey,
          kErrorDetailRecoverySuggestionKey
        ];
        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:kGREYObjectFormatIndent
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];
        reason = [NSString stringWithFormat:@"Multiple UI elements matched "
                                            @"for given criteria.\n"
                                            @"Exception with Assertion: %@\n",
                                            reasonDetail];

        [assertionError setErrorInfo:errorDetails];
        break;
      }
    }
  }

  if (reason.length == 0) {
    // Add unique failure messages for failure with unknown reason
    NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

    errorDetails[kErrorDetailAssertCriteriaKey] = assertion.name;
    errorDetails[kErrorDetailElementMatcherKey] = _elementMatcher.description;

    NSArray *keyOrder = @[ kErrorDetailAssertCriteriaKey, kErrorDetailElementMatcherKey ];
    NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                            indent:kGREYObjectFormatIndent
                                                         hideEmpty:YES
                                                          keyOrder:keyOrder];
    reason = [NSString stringWithFormat:@"An assertion failed.\n"
                                        @"Exception with Assertion: %@\n",
                                        reasonDetail];
  }

  *error = [self grey_errorToReturnForInteractionError:assertionError withReason:reason];
  return NO;
}

- (NSError *)grey_errorToReturnForInteractionError:(GREYError *)interactionError
                                        withReason:(NSString *)reason {
  // Obtain the hierarchy before framing the error since this can modify the error as well.
  NSString *hierarchy = [self grey_unifyAndExtractHierarchyFromError:interactionError];
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : interactionError.description,
    NSLocalizedFailureReasonErrorKey : reason,
    kErrorDetailElementMatcherKey : _elementMatcher.description,
  };
  NSMutableDictionary *mutableUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
  if (hierarchy) {
    [mutableUserInfo setObject:hierarchy forKey:kErrorDetailAppUIHierarchyKey];
  }
  NSDictionary *appScreenshots = [self grey_appScreenshotsFromError:interactionError];
  if (appScreenshots) {
    [mutableUserInfo setObject:appScreenshots forKey:kErrorDetailAppScreenshotsKey];
  }
  userInfo = [mutableUserInfo copy];
  return [NSError errorWithDomain:interactionError.domain
                             code:interactionError.code
                         userInfo:userInfo];
}

/**
 *  Provides an error with @c kGREYInteractionMultipleElementsMatchedErrorCode for multiple
 *  elements matching the specified matcher. In case we have multiple matchers and the Index
 *  provided for not matching with it is out of bounds, then we set the error code to
 *  @c kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode.s
 *
 *  @param matchingElements A set of matching elements.
 *  @param outOfBounds      A boolean that flags if the index for finding a matching element
 *                          is out of bounds.
 *
 *  @return Error for matching multiple elements.
 */
- (GREYError *)grey_errorForMultipleMatchingElements:(NSArray *)matchingElements
                 withMatchedElementsIndexOutOfBounds:(BOOL)outOfBounds {
  // Populate an array with the multiple matching elements.
  NSMutableArray *elementDescriptions =
      [[NSMutableArray alloc] initWithCapacity:matchingElements.count];

  [matchingElements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [elementDescriptions addObject:[obj grey_description]];
  }];

  // Populate the multiple matching elements error.
  NSString *errorDescription;
  NSInteger errorCode;
  if (outOfBounds) {
    // Populate with an error specifying that the index provided for matching the multiple elements
    // was out of bounds.
    errorDescription =
        [NSString stringWithFormat:@"Multiple elements were matched: %@ with an "
                                   @"index that is out of bounds of the number of "
                                   @"matched elements. Please use an element "
                                   @"index from 0 to %tu",
                                   elementDescriptions, ([elementDescriptions count] - 1)];
    errorCode = kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode;
  } else {
    // Populate with an error specifying that multiple elements were matched without providing
    // an index.
    errorDescription = [NSString stringWithFormat:@"Multiple elements were matched: %@. Please "
                                                  @"use selection matchers to narrow the "
                                                  @"selection down to single element.",
                                                  elementDescriptions];
    errorCode = kGREYInteractionMultipleElementsMatchedErrorCode;
  }

  // Populate the user info for the multiple matching elements error.
  return GREYErrorMakeWithHierarchy(kGREYInteractionErrorDomain, errorCode, errorDescription);
}

/**
 *  @return A String description of the current search action.
 */
- (NSString *)grey_searchActionDescription {
  if (_searchAction) {
    return [NSString stringWithFormat:@"Search action: %@. \nSearch action element matcher: %@.\n",
                                      _searchAction, _searchActionElementMatcher];
  } else {
    return @"";
  }
}

/**
 *  Performs the @c _searchAction with the @c _searchActionElementMatcher.
 *
 *  @param[out] error The error for performing the action if any.
 *  @return @c YES if no error occurs, otherwise @c NO.
 */
- (BOOL)grey_performSearchActionWithError:(GREYError **)error {
  id<GREYInteraction> interaction =
      [[GREYElementInteraction alloc] initWithElementMatcher:_searchActionElementMatcher];
  [interaction performAction:_searchAction error:error];
  return !(*error);
}

/**
 *  For a GREYError, checks if there is a nested GREYError, extracts and nils out any hierarchy
 *  present from the nested GREYError and sets it as the parent error's appUIHierarchy. If no
 *  nested GREYError is present, then just returns the parent error's hierarchy.
 *
 *  @param error A GREYError in which the UI hierarchy information is to be unified and extracted.
 *
 *  @return An NSString with the extracted UI hierarchy from the provided @c error.
 */
- (NSString *)grey_unifyAndExtractHierarchyFromError:(GREYError *)error {
  NSString *appUIHierarchy;
  // A user can call the assert/perform methods on the app side for a simple interaction created
  // and pass in a simple NSError. We do not have control over this since the GREYInteraction
  // must be public. Added this check to ensure that.
  // TODO: Make all entry point API's error objects implicitly turn into a GREYError object to
  //       remove this check.
  if ([error respondsToSelector:@selector(nestedError)]) {
    GREYError *modifiedError = error.nestedError ?: error;
    if ([modifiedError respondsToSelector:@selector(appUIHierarchy)]) {
      appUIHierarchy = modifiedError.appUIHierarchy;
      if (!appUIHierarchy) {
        NSAssert(NO, @"No hierarchy extracted from error: %@", modifiedError);
      }
      modifiedError.appUIHierarchy = nil;
    }
  }
  return appUIHierarchy;
}

/**
 *  For a GREYError, checks if any screenshots are present on the error or the nested error, save
 *  it as an NSDictionary to return to the test. Also nils out the existing screenshot.
 *
 *  @param error A GREYError in which the app screenshots are to be unified and extracted.
 *
 *  @return An NSDictionary with the extracted app screenshots from the provided @c error.
 *          Can be @c nil if no screenshots were taken on error creation.
 */
- (NSDictionary *)grey_appScreenshotsFromError:(NSError *)error {
  NSDictionary *appScreenshots;
  if ([error isKindOfClass:[GREYError class]]) {
    NSError *modifiedError = [(GREYError *)error nestedError] ?: error;
    if ([modifiedError isKindOfClass:[GREYError class]]) {
      GREYError *modifiedErrorWithScreenshots = (GREYError *)modifiedError;
      appScreenshots = modifiedErrorWithScreenshots.appScreenshots;
      modifiedErrorWithScreenshots.appScreenshots = nil;
    }
  }
  return appScreenshots;
}

@end
