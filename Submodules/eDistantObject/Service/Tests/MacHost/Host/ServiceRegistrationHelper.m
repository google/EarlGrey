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

#import "Service/Tests/MacHost/Host/ServiceRegistrationHelper.h"

#import "Service/Sources/EDOHostService.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

@implementation ServiceRegistrationHelper {
  NSMutableArray<EDOHostService *> *_services;
  dispatch_queue_t _servicesSyncQueue;
  NSString *_serviceNamePrefix;
  NSUInteger _numberOfServices;
}

- (instancetype)initWithServiceNamePrefix:(NSString *)prefix
                         numberOfServices:(NSUInteger)numberOfServices {
  self = [super init];
  if (self) {
    _services = [[NSMutableArray alloc] initWithCapacity:numberOfServices];
    _servicesSyncQueue =
        dispatch_queue_create("com.google.edo.test.servicesSync", DISPATCH_QUEUE_SERIAL);
    _serviceNamePrefix = prefix;
    _numberOfServices = numberOfServices;
  }
  return self;
}

- (void)registerServicesToDevice:(NSString *)deviceID
                           queue:(dispatch_queue_t)queue
                         timeout:(NSTimeInterval)timeout {
  for (NSUInteger i = 0; i < _numberOfServices; i++) {
    NSString *serviceName =
        [NSString stringWithFormat:@"%@%lu", _serviceNamePrefix, (unsigned long)i];
    EDOHostService *service =
        [EDOHostService serviceWithName:serviceName
                       registerToDevice:deviceID
                             rootObject:[[EDOTestDummy alloc] initWithValue:(int)i]
                                  queue:queue
                                timeout:timeout];
    dispatch_sync(_servicesSyncQueue, ^{
      [self->_services addObject:service];
    });
  }
}

@end
