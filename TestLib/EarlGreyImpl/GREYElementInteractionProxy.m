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

#import "TestLib/EarlGreyImpl/GREYElementInteractionProxy.h"

#import "AppFramework/DistantObject/GREYHostBackgroundDistantObject+GREYApp.h"
#import "CommonLib/Assertion/GREYAssertionDefines.h"
#import "CommonLib/Assertion/GREYFatalAsserts.h"
#import "CommonLib/Assertion/GREYThrowDefines.h"
#import "CommonLib/Error/GREYErrorConstants.h"
#import "CommonLib/Exceptions/GREYFailureHandler.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"

@implementation GREYElementInteractionProxy {
  /** App-side interaction instance. */
  GREYElementInteraction *_remoteElementInteraction;
}

@dynamic dataSource;

- (instancetype)initWithElementMatcher:(id<GREYMatcher>)elementMatcher {
  GREYThrowOnNilParameter(elementMatcher);

  self = [super init];
  if (self) {
    _remoteElementInteraction =
        [GREYHostBackgroundDistantObject.sharedInstance interactionWithMatcher:elementMatcher];
  }
  return self;
}

- (id<GREYInteraction>)performAction:(id)action {
  return [self performAction:action error:nil];
}

- (id<GREYInteraction>)performAction:(id)action error:(__autoreleasing NSError **)errorOrNil {
  __strong NSError *interactionError = nil;
  [_remoteElementInteraction performAction:action error:&interactionError];
  [self grey_handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion {
  return [self assert:assertion error:nil];
}

- (id<GREYInteraction>)assert:(id<GREYAssertion>)assertion
                        error:(__autoreleasing NSError **)errorOrNil {
  __strong NSError *interactionError = nil;
  [_remoteElementInteraction assert:assertion error:&interactionError];
  [self grey_handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher {
  return [self assertWithMatcher:matcher error:nil];
}

- (id<GREYInteraction>)assertWithMatcher:(id<GREYMatcher>)matcher
                                   error:(__autoreleasing NSError **)errorOrNil {
  __strong NSError *interactionError = nil;
  [_remoteElementInteraction assertWithMatcher:matcher error:&interactionError];
  [self grey_handleInteractionError:interactionError outError:errorOrNil];
  return self;
}

- (id<GREYInteraction>)inRoot:(id<GREYMatcher>)rootMatcher {
  [_remoteElementInteraction inRoot:rootMatcher];
  return self;
}

- (id<GREYInteraction>)usingSearchAction:(id<GREYAction>)action
                    onElementWithMatcher:(id<GREYMatcher>)matcher {
  [_remoteElementInteraction usingSearchAction:action onElementWithMatcher:matcher];
  return self;
}

- (id<GREYInteraction>)atIndex:(NSUInteger)index {
  [_remoteElementInteraction atIndex:index];
  return self;
}

- (id<GREYInteractionDataSource>)dataSource {
  return _remoteElementInteraction.dataSource;
}

- (void)setDataSource:(id<GREYInteractionDataSource>)dataSource {
  _remoteElementInteraction.dataSource = dataSource;
}

- (id<GREYInteraction>)includeStatusBar {
  return [_remoteElementInteraction includeStatusBar];
}

#pragma mark - Private

/**
 *  Handles and sets the error based on the interaction related placeholder error value.
 *
 *  @param interactionError Error returned from the interaction.
 *  @param errorOrNil       Error passed in by the user.
 *
 *  @return @c NO if any error is returned from the interaction, @c YES otherwise.
 */
- (BOOL)grey_handleInteractionError:(__strong NSError *)interactionError
                           outError:(__autoreleasing NSError **)errorOrNil {
  if (interactionError) {
    if (errorOrNil) {
      *errorOrNil = interactionError;
    } else {
      GREYFrameworkException *exception =
          [GREYFrameworkException exceptionWithName:[interactionError domain]
                                             reason:[interactionError localizedDescription]
                                           userInfo:[interactionError userInfo]];
      id<GREYFailureHandler> failureHandler = GREYGetFailureHandler();
      NSString *errorDetails = [[exception userInfo] valueForKey:kErrorDetailElementMatcherKey];
      [failureHandler handleException:exception details:errorDetails];
    }
    return NO;
  } else {
    return YES;
  }
}

@end
