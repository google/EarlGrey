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

#import "GREYError.h"

#import "GREYErrorFormatter.h"

NSString *const kGREYGenericErrorDomain = @"com.google.earlgrey.GenericErrorDomain";
NSInteger const kGREYGenericErrorCode = 0;
NSString *const kErrorDetailFailureNameKey = @"Failure Name";
NSString *const kErrorDetailActionNameKey = @"Failed Action";
NSString *const kErrorDetailSearchActionInfoKey = @"Search API Info";
NSString *const kErrorDetailAssertCriteriaKey = @"Failed Assertion";
NSString *const kErrorDetailRecoverySuggestionKey = @"Recovery Suggestion";
NSString *const kErrorDetailElementsMatchedKey = @"Elements Matched";

NSString *const kErrorDomainKey = @"Error Domain";
NSString *const kErrorCodeKey = @"Error Code";
NSString *const kErrorDescriptionKey = @"Description";
NSString *const kErrorFailureReasonKey = @"Failure Reason";

NSString *const kErrorTestCaseClassNameKey = @"TestCase Class";
NSString *const kErrorTestCaseMethodNameKey = @"TestCase Method";
NSString *const kErrorFilePathKey = @"File Path";
NSString *const kErrorFileNameKey = @"File Name";
NSString *const kErrorLineKey = @"Line";
NSString *const kErrorFunctionNameKey = @"Function Name";
NSString *const kErrorUserInfoKey = @"User Info";
NSString *const kErrorErrorInfoKey = @"Error Info";
NSString *const kErrorStackTraceKey = @"Stack Trace";
NSString *const kErrorAppUIHierarchyKey = @"App UI Hierarchy";
NSString *const kErrorAppScreenShotsKey = @"App Screenshots";

NSString *const kGREYAppScreenshotAtFailure = @"App-side Screenshot at Point-of-Failure";
NSString *const kGREYTestScreenshotAtFailure = @"Test-side Screenshot at Failure";
NSString *const kGREYScreenshotBeforeImage = @"Visibility Checker Most Recent Before Image";
NSString *const kGREYScreenshotExpectedAfterImage =
    @"Visibility Checker Most Recent Expected After Image";
NSString *const kGREYScreenshotActualAfterImage =
    @"Visibility Checker Most Recent Actual After Image";

/**
 * Redefinition of the GREYError class to make properties readwrite.
 */
@interface GREYError ()
@property(nonatomic, readwrite) NSString *testCaseClassName;
@property(nonatomic, readwrite) NSString *testCaseMethodName;
@property(nonatomic, readwrite) NSString *filePath;
@property(nonatomic, readwrite) NSUInteger line;
@property(nonatomic, readwrite) NSString *functionName;
@property(nonatomic, readwrite) NSDictionary<NSString *, id> *errorInfo;
@property(nonatomic, readwrite) NSArray<NSString *> *multipleElementsMatched;
@property(nonatomic, readwrite) NSArray<NSString *> *stackTrace;
@property(nonatomic, readwrite) NSString *appUIHierarchy;
@property(nonatomic, readwrite) NSDictionary<NSString *, UIImage *> *appScreenshots;
@property(nonatomic, readwrite) GREYError *nestedError;
@property(nonatomic, readwrite) NSArray<NSString *> *keyOrder;
@end

GREYError *I_GREYErrorMake(NSString *domain, NSInteger code, NSDictionary<NSString *, id> *userInfo,
                           NSString *filePath, NSUInteger line, NSString *functionName,
                           NSArray<NSString *> *stackTrace, NSString *appUIHierarchy,
                           NSDictionary<NSString *, UIImage *> *appScreenshots,
                           NSArray<NSString *> *keyOrder) {
  GREYError *error = [[GREYError alloc] initWithDomain:domain code:code userInfo:userInfo];

  error.filePath = filePath;
  error.line = line;
  error.functionName = functionName;
  error.stackTrace = stackTrace;
  error.appUIHierarchy = appUIHierarchy;
  error.appScreenshots = appScreenshots;
  error.keyOrder = [keyOrder copy];
  return error;
}

@implementation GREYError {
  NSString *_testCaseClassName;
  NSString *_testCaseMethodName;
  NSString *_filePath;
  NSUInteger _line;
  NSString *_functionName;
  NSDictionary<NSString *, id> *_errorInfo;
  NSArray<NSString *> *_multipleElementsMatched;
  NSArray<NSString *> *_stackTrace;
  NSString *_appUIHierarchy;
  NSDictionary<NSString *, UIImage *> *_appScreenshots;
}

@dynamic nestedError;

- (GREYError *)nestedError {
  return self.userInfo[NSUnderlyingErrorKey];
}

+ (instancetype)errorWithDomain:(NSString *)domain
                           code:(NSInteger)code
                       userInfo:(NSDictionary<NSString *, id> *)userInfo {
  return [super errorWithDomain:domain code:code userInfo:userInfo];
}

- (NSString *)description {
  return GREYFormattedDescriptionForError(self);
}

- (NSString *)localizedDescription {
  return [self description];
}
@end
