//
// Copyright 2020 Google Inc.
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
 * Since this file is part of the implementation of the new message-optional macros,
 * force the header file to define the macros.
 */
#define EG2_MESSAGE_OPTIONAL_ASSERTS

#import "GREYAssertDefaultConfiguration.h"

#import <Foundation/Foundation.h>

#import "GREYAssertionDefinesPrivate.h"
#import "GREYError.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYAssert+Private.h"
#import "GREYWaitFunctions.h"

/** Returns the current EarlGrey failure handler. */
static inline id<GREYFailureHandler> GetFailureHandler() {
  return [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];
}

void GREYIAssertDefaultConfiguration() {
  // Configure the assert macros to talk to the EarlGrey environment.
  GREYISetFileLineBlock setFileLineBlock =
      ^void(const char *_Nonnull fileName, NSUInteger lineNumber) {
        id<GREYFailureHandler> failureHandler = GetFailureHandler();
        if ([failureHandler respondsToSelector:@selector(setInvocationFile:andInvocationLine:)]) {
          NSString *invocationFile = [NSString stringWithUTF8String:fileName];
          if (invocationFile) {
            [failureHandler setInvocationFile:invocationFile andInvocationLine:lineNumber];
          }
        }
      };
  GREYIWaitForAppToIdleBlock waitForAppToIdleBlock = ^NSError *_Nullable(void) {
    NSError *error;
    BOOL success = GREYWaitForAppToIdleWithError(&error);
    if (success) {
      return nil;
    }
    if (!error) {
      // Reading the code behind GREYWaitForAppToIdleWithError() suggests this can never happen,
      // but it's not guaranteed in the method contract, so coding defensively here.
      error = GREYErrorMake(kGREYUIThreadExecutorErrorDomain, kGREYUIThreadExecutorTimeoutErrorCode,
                            @"Unknown error in GREYWaitForAppToIdleWithError.");
    }
    return error;
  };
  GREYIRegisterFailureBlock registerFailureBlock =
      ^void(GREYIExceptionType type, NSString *_Nonnull description, NSString *_Nonnull details) {
        NSString *exceptionName;
        switch (type) {
          case GREYIExceptionTypeTimeout:
            exceptionName = kGREYTimeoutException;
            break;
          case GREYIExceptionTypeAssertionFailed:
            exceptionName = kGREYAssertionFailedException;
            break;
        }  // switch(type)
        GREYFrameworkException *exception = [GREYFrameworkException exceptionWithName:exceptionName
                                                                               reason:description];
        id<GREYFailureHandler> failureHandler = GetFailureHandler();
        [failureHandler handleException:exception details:details];
      };
  (void)GREYIConfigureAssertions(setFileLineBlock, waitForAppToIdleBlock, registerFailureBlock);
}
