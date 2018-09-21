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

#import "AppFramework/Additions/NSException+GREYApp.h"

#import "AppFramework/Error/GREYAppFailureHandler.h"
#import "CommonLib/Exceptions/GREYFailureHandler.h"
#import "CommonLib/Exceptions/GREYFrameworkException.h"

id<GREYFailureHandler> GREYGetFailureHandler(void);

id<GREYFailureHandler> GREYGetFailureHandler() {
  static NSString *const kGREYAppFailureHandlerKey = @"GREYAppFailureHandlerKey";

  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  id<GREYFailureHandler> failureHandler = [TLSDict valueForKey:kGREYAppFailureHandlerKey];
  if (!failureHandler) {
    failureHandler = [[GREYAppFailureHandler alloc] init];
    [TLSDict setValue:failureHandler forKey:kGREYAppFailureHandlerKey];
  }
  return failureHandler;
}

@implementation NSException (GREYApp)

+ (void)grey_raise:(NSString *)name withError:(GREYError *)error {
  id<GREYFailureHandler> failureHandler = GREYGetFailureHandler();
  NSString *reason = [GREYError grey_nestedDescriptionForError:error];
  [failureHandler handleException:[GREYFrameworkException exceptionWithName:name reason:reason]
                          details:@""];
}

@end
