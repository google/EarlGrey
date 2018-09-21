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

#import <Foundation/Foundation.h>

#import "CommonLib/Error/GREYError.h"

@interface NSException (GREYApp)
/**
 *  Raise a @c GREYFrameworkException with the provided @c name, @c details and @c error.
 *
 *  @param name    The name of the exception.
 *  @param error   The error that is the major reason of the exception.
 *
 *  @remark This is available only for internal usage purposes.
 */
+ (void)grey_raise:(NSString *)name withError:(GREYError *)error;
@end
