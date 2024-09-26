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

#import <Foundation/Foundation.h>

#import "GREYErrorConstants.h"
#import "GREYDefines.h"

@class GREYError;

/**
 * Creates a @c GREYError object for a given @c domain, @c code and @c description. The description
 * is added to the userInfo for @c NSLocalizedDescriptionKey.
 *
 * @note No app side artifacts - screenshots or hierarchy are present here.
 *
 * @param domain      The error domain.
 * @param code        The error code.
 * @param description The error's localized description.
 *
 * @return A @c GREYError object with the given input.
 */
#define GREYErrorMake(domain, code, description)                               \
  I_GREYErrorMake((domain), (code), @{kErrorFailureReasonKey : (description)}, \
                  [NSString stringWithUTF8String:__FILE__], __LINE__,          \
                  [NSString stringWithUTF8String:__PRETTY_FUNCTION__],         \
                  [NSThread callStackSymbols], nil, nil, @[])

/**
 * Creates a @c GREYError object similar to @c GREYErrorMake with a @c userInfo dictionary. This
 * @c userInfo can contain additional information such as the recovery key. Both the @c userInfo and
 * @c description are combined together.
 *
 * @note No app side artifacts - screenshots or hierarchy are present here.
 *
 * @param domain      The error domain.
 * @param code        The error code.
 * @param description The error's localized description.
 * @param userInfo.    The error's userInfo.
 *
 * @return A @c GREYError object with the given input.
 */
#define GREYErrorMakeWithUserInfo(domain, code, description, userInfo)   \
  ({                                                                     \
    NSMutableDictionary *userInfoWithDescription =                       \
        [@{kErrorFailureReasonKey : (description)} mutableCopy];         \
    [userInfoWithDescription addEntriesFromDictionary:userInfo];         \
    I_GREYErrorMake((domain), (code), userInfoWithDescription,           \
                    [NSString stringWithUTF8String:__FILE__], __LINE__,  \
                    [NSString stringWithUTF8String:__PRETTY_FUNCTION__], \
                    [NSThread callStackSymbols], nil, nil, @[]);         \
  })

/**
 * Creates a @c GREYError object with given @c domain, @c code, @c userInfo,
 * @c filePath, @c line, @c functionName, @c errorInfo and @c stackTrace.
 *
 * @param domain       The error domain.
 * @param code         The error code.
 * @param userInfo     The user information that should be included
 *                     in the @c GREYError object.
 * @param filePath     The file path where the error is generated.
 * @param line         The file line where the error is generated.
 * @param functionName The function name where the error is generated.
 * @param stackTrace   The stack trace for the app when the error is generated.
 * @param keyOrder     The key order on how the userInfo details should be logged.
 *
 * @return A @c GREYError object with the given input.
 */
GREY_EXTERN GREYError *I_GREYErrorMake(NSString *domain, NSInteger code,
                                       NSDictionary<NSString *, id> *userInfo, NSString *filePath,
                                       NSUInteger line, NSString *functionName,
                                       NSArray<NSString *> *stackTrace, NSString *appUIHierarchy,
                                       NSDictionary<NSString *, UIImage *> *appScreenshots,
                                       NSArray<NSString *> *keyOrder);

/**
 * The string for a generic error in EarlGrey.
 */
GREY_EXTERN NSString *const kGREYGenericErrorDomain;

/**
 * The code for a generic error in EarlGrey.
 */
GREY_EXTERN NSInteger const kGREYGenericErrorCode;

/**
 * Key used to retrieve the action name from an error object for a failed action.
 */
GREY_EXTERN NSString *const kErrorDetailActionNameKey;

/**
 * Key used to retrieve the search action info from an error object for a failed action.
 */
GREY_EXTERN NSString *const kErrorDetailSearchActionInfoKey;

/**
 * Key used to retrieve the assert criteria from an error object for a failed assertion.
 */
GREY_EXTERN NSString *const kErrorDetailAssertCriteriaKey;

/**
 * Key used to retrieve the detailed recovery suggestion from an error object.
 */
GREY_EXTERN NSString *const kErrorDetailRecoverySuggestionKey;

/**
 * Key used to retrieve the list of elements matched when multiple elements are matched.
 */
GREY_EXTERN NSString *const kErrorDetailElementsMatchedKey;

/**
 * Key used to retrieve the error domain from an error object.
 */
GREY_EXTERN NSString *const kErrorDomainKey;

/**
 * Key used to retrieve the error code from an error object.
 */
GREY_EXTERN NSString *const kErrorCodeKey;

/**
 * Key used to retrieve the error description from an error object.
 */
GREY_EXTERN NSString *const kErrorDescriptionKey;

/**
 * Key used to retrieve the failure reason from an error object. It's also used to store failure
 * reason in @c userInfo dictionary.
 */
GREY_EXTERN NSString *const kErrorFailureReasonKey;

/**
 * Key used to retrieve the screenshot at the point-of-failure in the application.
 */
GREY_EXTERN NSString *const kGREYAppScreenshotAtFailure;

/**
 * Key used to retrieve a screenshot of the whole system, including system alerts, notifications
 * etc. in the test at the point the exception is raised.
 */
GREY_EXTERN NSString *const kGREYTestScreenshotAtFailure;

/**
 * Key used to retrieve the visibility checker's most recent screenshot before failure
 * from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kGREYScreenshotBeforeImage;

/**
 * Key used to retrieve the expected visibility checker's most recent screenshot after failure
 * from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kGREYScreenshotExpectedAfterImage;

/**
 * Key used to retrieve the actual visibility checker's most recent screenshot after failure
 * from an error object's app screenshots.
 */
GREY_EXTERN NSString *const kGREYScreenshotActualAfterImage;

/**
 * The error class for the error objects generated by EarlGrey.
 */
@interface GREYError : NSError

/**
 * The name of the test case class where the error is generated.
 */
@property(nonatomic, readonly) NSString *testCaseClassName;

/**
 * The name of the test case method where the error is generated.
 */
@property(nonatomic, readonly) NSString *testCaseMethodName;

/**
 * The source code file path where the error is generated.
 */
@property(nonatomic, readonly) NSString *filePath;

/**
 * The source code line number where the error is generated.
 */
@property(nonatomic, readonly) NSUInteger line;

/**
 * The source code function name where the error is generated.
 */
@property(nonatomic, readonly) NSString *functionName;

/**
 * The description set in the userInfo from the error creation macros.
 */
@property(nonatomic, readwrite) NSString *underlyingErrorDescription;

/**
 * The stack trace when the error is generated.
 */
@property(nonatomic, readonly) NSArray *stackTrace;

/**
 * The window hierarchy when the error is generated.
 */
@property(nonatomic, readonly) NSString *appUIHierarchy;

/**
 * The screenshots for the app when the error is generated.
 */
@property(nonatomic, readonly) NSDictionary *appScreenshots;

/**
 * Nested error within current error.
 */
@property(nonatomic, readonly) GREYError *nestedError;

/**
 * UserInfo key order for printing the error.
 */
@property(nonatomic, readonly) NSArray<NSString *> *keyOrder;

/**
 * @remark init is not an available initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * @return A version of the error to be printed in exceptions. Mainly removes the hierarchy.
 */
- (NSString *)exceptionDescription;

@end
