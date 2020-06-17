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

#import "Service/Sources/EDOServiceRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOHostPort;
@class EDOObject;

/** The object request to retrieve the root object associated with the service. */
@interface EDOObjectRequest : EDOServiceRequest

/** Creates an object request with @c hostPort. */
+ (instancetype)requestWithHostPort:(EDOHostPort *)hostPort;

@end

/** The object response for the object request. */
@interface EDOObjectResponse : EDOServiceResponse
/**
 *  The requested distant object. This could be either an EDOObject or a block object.
 *
 *  @note It is possible the distant object is nil, for example, the underlying object is gone.
 */
@property(readonly, nullable) id object;

+ (EDOServiceResponse *)responseWithObject:(EDOObject *_Nullable)object
                                forRequest:(EDOServiceRequest *)request;
@end

NS_ASSUME_NONNULL_END
