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

/** The generic eDO service exception, usually containing an embedded NSError object. */
FOUNDATION_EXPORT NSExceptionName const EDOServiceGenericException;

/** The value type exception when -alloc is invoked on a value type. */
FOUNDATION_EXPORT NSExceptionName const EDOServiceAllocValueTypeException;

/** The remoteWeak interface misuse exception, usually used in NSException. */
FOUNDATION_EXPORT NSExceptionName const EDOWeakObjectRemoteWeakMisuseException;

/** The weak eDO object release exception, usually used in NSException. */
FOUNDATION_EXPORT NSExceptionName const EDOWeakObjectWeakReleaseException;

/** The weak reference block object exception, usually used in NSException. */
FOUNDATION_EXPORT NSExceptionName const EDOWeakReferenceBlockObjectException;

/** The eDO parameter type check exception, usually used in NSException.*/
FOUNDATION_EXPORT NSExceptionName const EDOParameterTypeException;

/** Key in userInfo, describing the embedded NSError object. */
FOUNDATION_EXPORT NSString *const EDOExceptionUnderlyingErrorKey;

/** Key in userInfo, describing the remote service's port. */
FOUNDATION_EXPORT NSString *const EDOExceptionPortKey;

NS_ASSUME_NONNULL_END
