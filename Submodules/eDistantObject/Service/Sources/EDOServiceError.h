//
// Copyright 2019 Google LLC.
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

NS_ASSUME_NONNULL_BEGIN

// To enable the linter recognize this be an Objective-C file.
@class NSString;

FOUNDATION_EXPORT NSErrorDomain const EDOServiceErrorDomain;

NS_ERROR_ENUM(EDOServiceErrorDomain){
    EDOServiceErrorCannotConnect = -1000,
    EDOServiceErrorConnectTimeout,
    EDOServiceErrorRequestNotHandled,
    EDOServiceErrorNamingServiceUnavailable,
};

/** Key in userInfo, the value is an NSString describing the request being sent. */
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOErrorRequestKey;

/** Key in userInfo, the value is an NSString describing the response that's received. */
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOErrorResponseKey;

/** Key in userInfo, the value is an EDOHostPort describing the remote service's port. */
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOErrorPortKey;

/** Key in userInfo, the value is an NSNumber describing the attemp to connect to the service. */
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOErrorConnectAttemptKey;

NS_ASSUME_NONNULL_END
