//
// Copyright 2019 Google Inc.
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

/**
 *  This category provides APIs to statically blacklist a class to be used in remote invocation.
 *
 *  It provides a way to prevent certain types of instances being created in the wrong process
 *  and sent to system APIs as a remote object. For example, iOS app cannot add a remote UIView
 *  as the subview of another native UIView. If a type is blacklisted in remote invocation,
 *  its instance, which is created in this process by mistake, will throw an exception when it
 *  appears in a remote invocation.
 */
@interface NSObject (EDOBlacklistedType)

/**
 *  Blacklists this type to be a parameter of remote invocation.
 *
 *  If a class is blacklisted, its instances are not allowed to be either parameters or return
 *  values in remote invocation.
 */
+ (void)edo_disallowRemoteInvocation;

/** The boolean to indicate if @c self is blacklisted in remote invocation. */
@property(readonly, class) BOOL edo_remoteInvocationDisallowed;

@end

NS_ASSUME_NONNULL_END
