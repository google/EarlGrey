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

#import "Service/Sources/EDOObjectMessage.h"
#import "Service/Sources/EDOServiceRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class EDOHostPort;

/** The class request to retrieve the class object. */
@interface EDOClassRequest : EDOServiceRequest

/** Create a request with the class name and device serial. */
+ (instancetype)requestWithClassName:(NSString *)className hostPort:(EDOHostPort *)hostPort;

- (instancetype)init NS_UNAVAILABLE;

@end

/**
 *  The class response for the class request.
 *
 *  @note Both the object and class request will return a object response as both the object and
 *        class is an object. The class response will return the meta class object and the object
 *        itself points to a class object.
 */
@interface EDOClassResponse : EDOObjectResponse
@end

NS_ASSUME_NONNULL_END
