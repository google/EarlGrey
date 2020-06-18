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

#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDOServiceRequest.h"

NS_ASSUME_NONNULL_BEGIN

/** The request to retrieve the instance method signature for a class. */
@interface EDOMethodSignatureRequest : EDOServiceRequest

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Create a request with the given class and selector.
 *
 *  @param object   The pointer to the object.
 *  @param port     The service port to validate whether the underlying object are for the
 *                  same service.
 *  @param selector The selector.
 */
+ (instancetype)requestWithObject:(EDOPointerType)object
                             port:(EDOServicePort *_Nullable)port
                         selector:(SEL)selector;

@end

/** The response for the method signature request. */
@interface EDOMethodSignatureResponse : EDOServiceResponse

/** The Objective C type encoded signature for the selector. */
@property(readonly, nullable) NSString *signature;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
