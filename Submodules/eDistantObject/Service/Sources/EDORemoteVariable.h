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

NS_ASSUME_NONNULL_BEGIN

/**
 *  EDORemoteVariable wraps out parameters for use beyond the scope of the current remote
 *  invocation.
 *
 *  If an object receives a remote invocation containing an out parameter, that parameter is only
 *  valid within the scope of the execution of the containing invocation. If the out parameter needs
 *  to be stored and dereferenced later (after the remote invocation), the later dereference will
 *  crash due to an invalid memory access. In such cases, this class should be used instead of an
 *  out parameter because it will persist past the lifetime of the remote invocation.
 */
@interface EDORemoteVariable <ObjectType> : NSObject

/** The wrapped out parameter. */
@property(nullable) ObjectType object;

@end

NS_ASSUME_NONNULL_END
