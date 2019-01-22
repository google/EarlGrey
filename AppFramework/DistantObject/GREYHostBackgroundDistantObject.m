//
// Copyright 2017 Google Inc.
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

#import "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h"

#import "Service/Sources/EDOHostService.h"

@interface GREYHostBackgroundDistantObject ()

@end

@implementation GREYHostBackgroundDistantObject

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static GREYHostBackgroundDistantObject *instance;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _backgroundQueue =
        dispatch_queue_create("com.google.earlgrey.hostbackground", DISPATCH_QUEUE_SERIAL);
    _service = [EDOHostService serviceWithPort:0 rootObject:self queue:_backgroundQueue];
  }
  return self;
}

- (uint16_t)servicePort {
  return self.service.port.port;
}

@end
