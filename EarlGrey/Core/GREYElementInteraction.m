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

#import "Core/GREYElementInteraction.h"

#import "Action/GREYAction.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Assertion/GREYAssertion.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYDefines.h"
#import "Common/GREYExposed.h"
#import "Common/GREYPrivate.h"
#import "Core/GREYElementFinder.h"
#import "Core/GREYInteractionDataSource.h"
#import "Exception/GREYFrameworkException.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Provider/GREYElementProvider.h"
#import "Provider/GREYUIWindowProvider.h"
#import "Synchronization/GREYUIThreadExecutor.h"

/**
 *  Extern variable specifying the error domain for GREYElementInteraction.
 */
NSString *const kGREYInteractionErrorDomain = @"com.google.earlgrey.ElementInteractionErrorDomain";
NSString *const kGREYWillPerformActionNotification = @"GREYWillPerformActionNotification";
NSString *const kGREYDidPerformActionNotification = @"GREYDidPerformActionNotification";
NSString *const kGREYWillPerformAssertionNotification = @"GREYWillPerformAssertionNotification";
NSString *const kGREYDidPerformAssertionNotification = @"GREYDidPerformAssertionNotification";

/**
 *  Extern variables specifying the user info keys for any notifications.
 */
NSString *const kGREYActionUserInfoKey = @"kGREYActionUserInfoKey";
NSString *const kGREYActionElementUserInfoKey = @"kGREYActionElementUserInfoKey";
NSString *const kGREYActionErrorUserInfoKey = @"kGREYActionErrorUserInfoKey";
NSString *const kGREYAssertionUserInfoKey = @"kGREYAssertionUserInfoKey";
NSString *const kGREYAssertionElementUserInfoKey = @"kGREYAssertionElementUserInfoKey";
NSString *const kGREYAssertionErrorUserInfoKey = @"kGREYAssertionErrorUserInfoKey";

typedef void (^GREYInteractionBlock)(id element, NSError *matchError, __strong NSError **error);

@interface GREYElementInteraction() <GREYInteractionDataSource>
@end

@implementation GREYElementInteraction {
  id<GREYMatcher> _rootMatcher;
  id<GREYMatcher> _searchActionElementMatcher;
  id<GREYMatcher> _elementMatcher;
  id<GREYAction> _searchAction;
  // If _index is set to NSUIntegerMax, then it is unassigned.
  NSUInteger _index;
}

@synthesize dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  NSParameterAssert(elementMatcher);

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

/**
 *  Searches for UI elements within the root views and returns all matched UI elements. The given
 *  search action is performed until an element is found.
 *
 *  @param timeout The amount of time during which search actions must be performed to find an
 *                 element.
 *  @param error   The error populated on failure. If an element was found and returned when using
 *                 the search actions then any action or timeout errors that happened in the
 *                 previous search are ignored. However, if an element is not found, the error
 *                 will be propagated.
 *
 *  @return An array of matched UI elements in the data source. If no UI element is found in
 *          @c timeout seconds, a timeout error will be produced and no UI element will be returned.
 */
- (NSArray *)matchedElementsWithTimeout:(CFTimeInterval)timeout error:(__strong NSError **)error {
  NSParameterAssert(error);

  id<GREYInteractionDataSource> strongDataSource = [self dataSource];
  NSAssert(strongDataSource, @"strongDataSource must be set before fetching UI elements");

  GREYElementProvider *entireRootHierarchyProvider =
      [GREYElementProvider providerWithRootProvider:[strongDataSource rootElementProvider]];
  id<GREYMatcher> matcher = _rootMatcher
      ? grey_allOf(_elementMatcher, grey_ancestor(_rootMatcher), nil) : _elementMatcher;
  GREYElementFinder *elementFinder = [[GREYElementFinder alloc] initWithMatcher:matcher];
  NSError *searchActionError = nil;
  CFTimeInterval timeoutTime = CACurrentMediaTime() + timeout;

  while (YES) {
    @autoreleasepool {
      // Find the element in the current UI hierarchy.
      NSArray *elements = [elementFinder elementsMatchedInProvider:entireRootHierarchyProvider];
      if (elements.count > 0) {
        return elements;
      } else if (!_searchAction) {
        NSString *description =
            @"Interaction cannot continue because the desired element was not found.";
        *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                     code:kGREYInteractionElementNotFoundErrorCode
                                 userInfo:@{ NSLocalizedDescriptionKey : description }];
        break;
      } else if (searchActionError) {
        *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                     code:kGREYInteractionElementNotFoundErrorCode
                                 userInfo:@{ NSUnderlyingErrorKey : searchActionError }];
        break;
      } else if (CACurrentMediaTime() >= timeoutTime) {
        NSString *description = [NSString stringWithFormat:@"Interaction timed out after %g "
                                                           @"seconds while searching for element.",
                                                           timeout];
        NSError *timeoutError =
            [NSError errorWithDomain:kGREYInteractionErrorDomain
                                code:kGREYInteractionTimeoutErrorCode
                            userInfo:@{ NSLocalizedDescriptionKey : description }];
        *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                     code:kGREYInteractionElementNotFoundErrorCode
                                 userInfo:@{ NSUnderlyingErrorKey : timeoutError }];
        break;
      }
      // Keep applying search action. Don't fail if this interaction errors out. It might have
      // revealed the element we are looking for.
      [[[GREYElementInteraction alloc] initWithElementMatcher:_searchActionElementMatcher]
          performAction:_searchAction error:&searchActionError];
      // Drain here so that search at the beginning of the loop looks at stable UI.
      [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
    }
  }

  return nil;
}

#pragma mark - GREYInteractionDataSource

/**
 *  Default data source for this interaction if no datasource is set explicitly.
 */
- (id<GREYProvider>)rootElementProvider {
  return [GREYUIWindowProvider providerWithAllWindows];
}

#pragma mark - GREYInteraction

- (instancetype)performAction:(id<GREYAction>)action {
  return [self performAction:action error:nil];
}

- (instancetype)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (instancetype)assertWithMatcher:(id<GREYMatcher>)matcher error:(__strong NSError **)errorOrNil {
  return [self assert:[GREYAssertions grey_createAssertionWithMatcher:matcher] error:errorOrNil];
}

- (instancetype)usingSearchAction:(id<GREYAction>)action
             onElementWithMatcher:(id<GREYMatcher>)matcher {
  NSParameterAssert(action);
  NSParameterAssert(matcher);

  _searchActionElementMatcher = matcher;
  _searchAction = action;
  return self;
}

- (instancetype)performAction:(id<GREYAction>)action error:(__strong NSError **)errorOrNil {
  NSParameterAssert(action);

  NSString *name = [NSString stringWithFormat:@"Action '%@'", action.name];
  [self grey_performInteraction:name
                failedException:kGREYActionFailedException
                     errorOrNil:errorOrNil
               interactionBlock:^(id element, NSError *matchError, __strong NSError **error) {
    NSParameterAssert(error);

    if ([[UIApplication sharedApplication] _isSpringBoardShowingAnAlert] &&
        ![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
      NSString *description = @"System alert view is displayed.";
      *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                   code:kGREYInteractionSystemAlertViewIsDisplayedErrorCode
                               userInfo:@{ NSLocalizedDescriptionKey : description }];
    } else if (matchError) {
      *error = matchError;
    }
    NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithDictionary:@{ kGREYActionUserInfoKey : action }];
    if (element) {
      [userInfo setObject:element forKey:kGREYActionElementUserInfoKey];
    }
    if (*error) {
     [userInfo setObject:*error forKey:kGREYActionErrorUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kGREYWillPerformActionNotification
                                                        object:nil
                                                      userInfo:userInfo];
    // We only call perform:error: if element is not nil, as it is a default constraint for all
    // actions. WillPerformAction and DidPerformAction notifications will always be sent, even if
    // element is nil. Don't perform if error was already set (such as multiple elements error).
    if (!*error && element && ![action perform:element error:error]) {
      if (!*error) {
        // Action didn't succeed yet no error was set.
        NSString *description = [NSString stringWithFormat:@"%@ failed: no details given.", name];
        *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                     code:kGREYInteractionActionFailedErrorCode
                                 userInfo:@{ NSLocalizedDescriptionKey : description }];
      }
    }
    if (*error) {
      [userInfo setObject:*error forKey:kGREYActionErrorUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kGREYDidPerformActionNotification
                                                        object:nil
                                                      userInfo:userInfo];
  }];
  // Drain once to update idling resources and redraw the screen.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  return self;
}

- (instancetype)assert:(id<GREYAssertion>)assertion error:(__strong NSError **)errorOrNil {
  NSParameterAssert(assertion);

  NSString *name = [NSString stringWithFormat:@"Assertion '%@'", assertion.name];
  [self grey_performInteraction:name
                failedException:kGREYAssertionFailedException
                     errorOrNil:errorOrNil
               interactionBlock:^(id element, NSError *matchError, __strong NSError **error) {
    NSParameterAssert(error);

    NSMutableDictionary *userInfo =
        [NSMutableDictionary dictionaryWithDictionary:@{ kGREYAssertionUserInfoKey : assertion }];
    if (element) {
      [userInfo setObject:element forKey:kGREYAssertionElementUserInfoKey];
    }
    if (*error) {
     [userInfo setObject:*error forKey:kGREYAssertionErrorUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kGREYWillPerformAssertionNotification
                                                        object:nil
                                                      userInfo:userInfo];
    // Don't assert if error was already set (such as multiple elements error).
    if (!*error && ![assertion assert:element error:error]) {
      if (!*error) {
        // Assertion didn't succeed yet no error was set.
        NSString *description = [NSString stringWithFormat:@"%@ failed: no details given.", name];
        *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                     code:kGREYInteractionAssertionFailedErrorCode
                                 userInfo:@{ NSLocalizedDescriptionKey : description }];
      }
    }
    if ([(*error).domain isEqualToString:kGREYInteractionErrorDomain] &&
        (*error).code == kGREYInteractionElementNotFoundErrorCode) {
      *error = matchError;
    }
    if (*error) {
      [userInfo setObject:*error forKey:kGREYAssertionErrorUserInfoKey];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kGREYDidPerformAssertionNotification
                                                        object:nil
                                                      userInfo:userInfo];
  }];
  return self;
}

# pragma mark - Private

- (BOOL)grey_performInteraction:(NSString *)interactionName
                failedException:(NSString *)exceptionName
                     errorOrNil:(__strong NSError **)errorOrNil
               interactionBlock:(GREYInteractionBlock)interactionBlock {
  I_CHECK_MAIN_THREAD();
  NSParameterAssert(interactionName);
  NSParameterAssert(exceptionName);
  NSParameterAssert(interactionBlock);

  NSError *executorError;
  __block NSError *internalError = nil;
  __weak __typeof__(self) weakSelf = self;
  CFTimeInterval timeout = GREY_CONFIG_DOUBLE(kGREYConfigKeyInteractionTimeoutDuration);

  BOOL executed = [[GREYUIThreadExecutor sharedInstance] executeSyncWithTimeout:timeout block:^{
    __typeof__(self) strongSelf = weakSelf;
    NSAssert(strongSelf, @"strongSelf must not be nil");

    @autoreleasepool {
      NSError *matchError = nil;
      NSArray *elements = [strongSelf matchedElementsWithTimeout:timeout error:&matchError];
      id element = [strongSelf grey_uniqueElementInMatchedElements:elements error:&internalError];
      interactionBlock(element, matchError, &internalError);
    }
    // If we encountered a failure and are going to raise an exception, raise it right away before
    // the main runloop drains any further.
    if (internalError && !errorOrNil) {
      [strongSelf grey_failInteraction:interactionName exception:exceptionName error:internalError];
    }
  } error:&executorError];

  // Failure to execute due to timeout should be represented as interaction timeout.
  if ([executorError.domain isEqualToString:kGREYUIThreadExecutorErrorDomain] &&
      executorError.code == kGREYUIThreadExecutorTimeoutErrorCode) {
    NSString *description = [NSString stringWithFormat:@"%@ failed: timed out after %g seconds.",
                                                       interactionName, timeout];
    internalError = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                        code:kGREYInteractionTimeoutErrorCode
                                    userInfo:@{ NSUnderlyingErrorKey      : executorError,
                                                NSLocalizedDescriptionKey : description }];
  } else if (!executed) {
    NSAssert(executorError, @"executorError should be set if execution failed");
    internalError = executorError;
  }
  if (internalError && errorOrNil) {
    *errorOrNil = internalError;
  } else if (internalError) {
    [self grey_failInteraction:interactionName exception:exceptionName error:internalError];
  }
  // Method accepting NSError ** should have a non-void return value.
  return !internalError;
}

/**
 *  Handles failure of an @c interaction.
 *
 *  @param interactionName      Name of the failing action or assertion.
 *  @param defaultExceptionName Default exception name for this type of interaction.
 *  @param error                NSError object with information about the failure.
 *  @throws NSException with the interaction failure is always thrown.
 */
- (void)grey_failInteraction:(NSString *)interactionName
                   exception:(NSString *)defaultExceptionName
                       error:(NSError *)error {
  NSParameterAssert(interactionName);
  NSParameterAssert(defaultExceptionName);
  NSParameterAssert(error);

  if ([error.domain isEqualToString:kGREYInteractionErrorDomain]) {
    NSString *searchActionDescription = @"";
    if (_searchAction) {
      searchActionDescription =
          [NSString stringWithFormat:@"Search action: %@. \nSearch action element matcher: %@.\n",
                                     _searchAction, _searchActionElementMatcher];
    }
    // Customize exception based on the error.
    switch (error.code) {
      case kGREYInteractionElementNotFoundErrorCode: {
        NSString *reason =
            [NSString stringWithFormat:@"%@ was not performed because no UI element matching %@ "
                                       @"was found.", interactionName, _elementMatcher];
        I_GREYRegisterFailure(kGREYNoMatchingElementException,
                              reason,
                              @"%@Complete error: %@",
                              searchActionDescription,
                              error);
      }
      case kGREYInteractionMultipleElementsMatchedErrorCode: {
        NSString *reason =
            [NSString stringWithFormat:@"%@ was not performed because multiple UI elements "
                                       @"matching %@ were found. Use grey_allOf(...) to create a "
                                       @"more specific matcher.", interactionName, _elementMatcher];
        // We print the localized description here to prevent multiple matchers info from being
        // displayed twice - once in the error and once in the userInfo dict.
        I_GREYRegisterFailure(kGREYMultipleElementsFoundException,
                              reason,
                              @"%@Complete error: %@",
                              searchActionDescription,
                              error.localizedDescription);
      }
      case kGREYInteractionSystemAlertViewIsDisplayedErrorCode: {
        NSString *reason = [NSString stringWithFormat:@"%@ was not performed because a system "
                                                      @"alert view was displayed.",
                                                      interactionName];
        I_GREYRegisterFailure(defaultExceptionName,
                              reason,
                              @"%@Complete error: %@",
                              searchActionDescription,
                              error);
      }
    }
  }
  // TODO: Add unique failure messages for timeout and other well-known reasons for failure.
  NSString *reason = [NSString stringWithFormat:@"%@ failed.", interactionName];
  I_GREYRegisterFailure(defaultExceptionName,
                        reason,
                        @"Element matcher: %@\nComplete error: %@",
                        _elementMatcher,
                        error);
}

/**
 *  From the set of matched elements, obtain one unique element for the provided matcher. In case
 *  there are multiple elements matched, then the one selected by the _@c index provided is chosen
 *  else the provided @c error is populated.
 *
 *  @param[out] error The error to be populated on failure. Must not be nil.
 *
 *  @return A uniquely matched element, if any.
 */
- (id)grey_uniqueElementInMatchedElements:(NSArray *)elements error:(__strong NSError **)error {
  NSParameterAssert(error);

  // If we find that multiple matched elements are present, we narrow them down based on
  // any index passed or populate the passed error if the multiple matches are present and
  // an incorrect index was passed.
  if (elements.count > 1) {
    // If the number of matched elements are greater than 1 then we have to use the index for
    // matching. We perform a bounds check on the index provided here and throw an exception if
    // it fails.
    if (_index == NSUIntegerMax) {
      NSMutableArray *elementDescriptions = [NSMutableArray arrayWithCapacity:elements.count];
      [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [elementDescriptions addObject:[obj grey_description]];
      }];
      NSString *description =
          [NSString stringWithFormat:@"Multiple elements were matched: %@. Use selection matchers"
                                     @"to narrow the selection down to a single element.",
                                     elementDescriptions];
      *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                   code:kGREYInteractionMultipleElementsMatchedErrorCode
                               userInfo:@{ NSLocalizedDescriptionKey : description }];
      return nil;
    } else if (_index >= elements.count) {
      NSMutableArray *elementDescriptions = [NSMutableArray arrayWithCapacity:elements.count];
      [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [elementDescriptions addObject:[obj grey_description]];
      }];
      NSString *description =
          [NSString stringWithFormat:@"Multiple elements were matched: %@ but index %lu@ is out of "
                                     @"bounds of the number of matched elements. Modify selection "
                                     @"matchers or use element index between 0 and %tu.",
                                     elementDescriptions,
                                     (unsigned long)_index,
                                     [elementDescriptions count] - 1];
      *error = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                   code:kGREYInteractionMatchedElementIndexOutOfBoundsErrorCode
                               userInfo:@{ NSLocalizedDescriptionKey : description }];
      return nil;
    } else {
      return [elements objectAtIndex:_index];
    }
  }
  // No error: there are 0 or 1 elements in the array and we can return the first one, if any.
  return [elements firstObject];
}

@end
