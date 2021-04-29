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

#import "GREYThrowDefines.h"
#import "GREYAssert+Private.h"

#include <stdarg.h>

/** These values must set set via GREYIConfigureAssertions() before any assertions are invoked. */

/** The set-file-line block most recently set by GREYIConfigureAssertions. */
static GREYISetFileLineBlock gSetFileLineBlock;
/** The wait-for-app block most recently set by GREYIConfigureAssertions. */
static GREYIWaitForAppToIdleBlock gWaitForAppToIdleBlock;
/** The register-failure block most recently set by GREYIConfigureAssertions. */
static GREYIRegisterFailureBlock gRegisterFailureBlock;

GREYIAssertionsConfiguration GREYIConfigureAssertions(
    GREYISetFileLineBlock _Nonnull setFileLineBlock,
    GREYIWaitForAppToIdleBlock _Nonnull waitForAppToIdleBlock,
    GREYIRegisterFailureBlock _Nonnull registerFailureBlock) {
  GREYThrowInFunctionOnNilParameter(setFileLineBlock);
  GREYThrowInFunctionOnNilParameter(waitForAppToIdleBlock);
  GREYThrowInFunctionOnNilParameter(registerFailureBlock);

  GREYIAssertionsConfiguration oldConfiguration = {gSetFileLineBlock, gWaitForAppToIdleBlock,
                                                   gRegisterFailureBlock};
  gSetFileLineBlock = setFileLineBlock;
  gWaitForAppToIdleBlock = waitForAppToIdleBlock;
  gRegisterFailureBlock = registerFailureBlock;
  return oldConfiguration;
}

void GREYIRestoreConfiguration(GREYIAssertionsConfiguration oldConfiguration) {
  gSetFileLineBlock = oldConfiguration.setFileLineBlock;
  gWaitForAppToIdleBlock = oldConfiguration.waitForAppToIdleBlock;
  gRegisterFailureBlock = oldConfiguration.registerFailureBlock;
}

/** Returns the format string for timeout messages involving the given assertion type. */
static NSString *_Nonnull TimeoutMessageFormat(GREYIAssertionType assertionType) {
  switch (assertionType) {
    case GREYIAssertionTypeFail:
      return @"Test Failed.";
    case GREYIAssertionTypeTrue:
      return @"Couldn't assert that (%s) is true.";
    case GREYIAssertionTypeFalse:
      return @"Couldn't assert that (%s) is false.";
    case GREYIAssertionTypeNotNil:
      return @"Couldn't assert that (%s) is not nil.";
    case GREYIAssertionTypeNil:
      return @"Couldn't assert that (%s) is nil.";
    case GREYIAssertionTypeEqual:
      return @"Couldn't assert that (%s) and (%s) are equal.";
    case GREYIAssertionTypeNotEqual:
      return @"Couldn't assert that (%s) and (%s) are not equal.";
    case GREYIAssertionTypeGreaterThan:
      return @"Couldn't assert that (%s) is greater than (%s).";
    case GREYIAssertionTypeGreaterThanOrEqual:
      return @"Couldn't assert that (%s) is greater than or equal to (%s).";
    case GREYIAssertionTypeLessThan:
      return @"Couldn't assert that (%s) is less than (%s).";
    case GREYIAssertionTypeLessThanOrEqual:
      return @"Couldn't assert that (%s) is less than or equal to (%s).";
    case GREYIAssertionTypeEqualObjects:
      return @"Couldn't assert that (%s) and (%s) are equal objects.";
    case GREYIAssertionTypeNotEqualObjects:
      return @"Couldn't assert that (%s) and (%s) are not equal objects.";
  }
}

void GREYIWaitForAppToIdle(GREYIAssertionType assertionType, ...) {
  GREYThrowInFunctionOnNilParameterWithMessage(
      gWaitForAppToIdleBlock,
      @"GREYIConfigureAssertions() must be called before any assertions are invoked.");
  NSError *error = gWaitForAppToIdleBlock();
  if (error) {
    va_list args;
    va_start(args, assertionType);
    NSString *timeoutDescription =
        [[NSString alloc] initWithFormat:TimeoutMessageFormat(assertionType) arguments:args];
    va_end(args);
    NSString *details = [NSString stringWithFormat:@"Timed out waiting for app to idle. %@", error];
    GREYThrowInFunctionOnNilParameterWithMessage(
        gRegisterFailureBlock,
        @"GREYIConfigureAssertions() must be called before any assertions are invoked.");
    gRegisterFailureBlock(GREYIExceptionTypeTimeout, timeoutDescription, details);
  }
}

/** Returns the format string for the failure description for the given assertion type. */
static NSString *_Nonnull FailureDescriptionFormat(GREYIAssertionType assertionType) {
  switch (assertionType) {
    case GREYIAssertionTypeFail:
      return @"Test failed";
    case GREYIAssertionTypeTrue:
      return @"(%s) is false";
    case GREYIAssertionTypeFalse:
      return @"(%s) is true";
    case GREYIAssertionTypeNotNil:
      return @"(%s) is nil";
    case GREYIAssertionTypeNil:
      return @"((%s) is nil) failed: (%@) is not nil";
    case GREYIAssertionTypeEqual:
      return @"((%s) equal to (%s)) failed: (%@) is not equal to (%@)";
    case GREYIAssertionTypeNotEqual:
      return @"((%s) not equal to (%s)) failed: (%@) is equal to (%@)";
    case GREYIAssertionTypeGreaterThan:
      return @"((%s) greater than (%s)) failed: (%@) is not greater than (%@)";
    case GREYIAssertionTypeGreaterThanOrEqual:
      return @"((%s) greater than or equal to (%s)) failed: "
             @"(%@) is not greater than or equal to (%@)";
    case GREYIAssertionTypeLessThan:
      return @"((%s) less than (%s)) failed: (%@) is not less than (%@)";
    case GREYIAssertionTypeLessThanOrEqual:
      return @"((%s) less than or equal to (%s)) failed: "
             @"(%@) is not less than or equal to (%@)";
    case GREYIAssertionTypeEqualObjects:
      return @"((%s) equal to (%s)) failed: (%@) is not equal to (%@)";
    case GREYIAssertionTypeNotEqualObjects:
      return @"((%s) not equal to (%s)) failed: (%@) is equal to (%@)";
  }
}

NSString *_Nonnull GREYIFailureDescription(GREYIAssertionType assertionType, ...) {
  va_list args;
  va_start(args, assertionType);
  NSString *failureDescription =
      [[NSString alloc] initWithFormat:FailureDescriptionFormat(assertionType) arguments:args];
  va_end(args);
  return failureDescription;
}

void GREYISetFileLineAsFailable(const char *_Nonnull fileName, NSUInteger lineNumber) {
  GREYThrowInFunctionOnNilParameterWithMessage(
      gSetFileLineBlock,
      @"GREYIConfigureAssertions() must be called before any assertions are invoked.");
  gSetFileLineBlock(fileName, lineNumber);
}

void GREYIAssertionFail(NSString *_Nonnull descriptionFormat, ...) {
  va_list args;
  va_start(args, descriptionFormat);
  NSString *description = [[NSString alloc] initWithFormat:descriptionFormat arguments:args];
  va_end(args);
  NSString *descriptionWithDetails = [NSString stringWithFormat:@"%@\n", description];
  GREYThrowInFunctionOnNilParameterWithMessage(
      gRegisterFailureBlock,
      @"GREYIConfigureAssertions() must be called before any assertions are invoked.");
  gRegisterFailureBlock(GREYIExceptionTypeAssertionFailed, description, descriptionWithDetails);
}

void GREYIAssertionFailure(NSString *_Nonnull description, NSString *_Nullable detailsFormat, ...) {
  NSString *_Nonnull details = @"";
  if (detailsFormat) {
    va_list args;
    va_start(args, detailsFormat);
    details = [[NSString alloc] initWithFormat:detailsFormat arguments:args];
    va_end(args);
  }
  NSString *descriptionWithDetails = @"";
  if (details.length) {
    descriptionWithDetails = [NSString stringWithFormat:@"%@\n\n%@", description, details];
  } else {
    descriptionWithDetails = [NSString stringWithFormat:@"%@\n", description];
  }
  GREYThrowInFunctionOnNilParameterWithMessage(
      gRegisterFailureBlock,
      @"GREYIConfigureAssertions() must be called before any assertions are invoked.");
  gRegisterFailureBlock(GREYIExceptionTypeAssertionFailed, description, descriptionWithDetails);
}
