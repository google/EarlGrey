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

@class EDOObject;

NS_ASSUME_NONNULL_BEGIN

/** The data object that holds an exception being thrown in remote invocation. */
@interface EDORemoteException : NSException <NSSecureCoding>

/** The merged call stack traces of both client process and host process. */
@property(readonly, copy) NSArray<NSString *> *callStackSymbols;

/** EDORemoteException cannot be initialized with default data members. */
- (instancetype)init NS_UNAVAILABLE;

/** EDORemoteException doesn't support transporting @c NSException::userInfo over processes. */
- (instancetype)initWithName:(NSExceptionName)name
                      reason:(nullable NSString *)reason
                    userInfo:(nullable NSDictionary<id, id> *)userInfo NS_UNAVAILABLE;

/** Creates an exception with host-side only information. */
- (instancetype)initWithName:(NSExceptionName)name
                      reason:(nullable NSString *)reason
            callStackSymbols:(NSArray<NSString *> *)callStackSymbols NS_DESIGNATED_INITIALIZER;

/** @see -[NSCoding initWithCoder:]. */
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
