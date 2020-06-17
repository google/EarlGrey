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

#import "Service/Sources/EDOHostService+Handlers.h"

#import "Service/Sources/EDOClassMessage.h"
#import "Service/Sources/EDOInvocationMessage.h"
#import "Service/Sources/EDOMethodSignatureMessage.h"
#import "Service/Sources/EDOObjectAliveMessage.h"
#import "Service/Sources/EDOObjectMessage.h"
#import "Service/Sources/EDOObjectReleaseMessage.h"

@implementation EDOHostService (Handlers)

+ (NSDictionary *)handlers {
  static NSMutableDictionary *handlers;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    handlers = [[NSMutableDictionary alloc] init];
    NSArray *requestClasses = @[
      [EDOClassRequest class],
      [EDOInvocationRequest class],
      [EDOMethodSignatureRequest class],
      [EDOObjectAliveRequest class],
      [EDOObjectRequest class],
      [EDOObjectReleaseRequest class],
    ];

    [requestClasses enumerateObjectsUsingBlock:^(Class clz, NSUInteger idx, BOOL *stop) {
      handlers[NSStringFromClass(clz)] = [clz requestHandler];
    }];
  });
  return handlers;
}

@end
