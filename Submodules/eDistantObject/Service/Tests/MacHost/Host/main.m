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

#import "Device/Sources/EDODeviceConnector.h"
#import "Service/Sources/EDOHostService.h"
#import "Service/Tests/MacHost/Host/ServiceRegistrationHelper.h"
#import "Service/Tests/TestsBundle/EDOTestDummy.h"

// Default service registration timeout.
const NSTimeInterval kDefaultTimeout = 1000;
// Argument key for target device id (device serial).
NSString *const kDeviceIDArgumentKey = @"udid";
// Argument key for service registration timeout.
NSString *const kTimeoutArgumentKey = @"timeout";

/**
 *  Starts 30 @c EDOHostService and registers them on target device, and keeps the process running.
 *  This is to test multiple services registration and communication, and validating the system is
 *  still stable under the pressure.
 *
 *  Pass -udid $(DEVICE_ID) to specify a connected target device.
 *  Pass -timeout $(TIMEOUT) to specify a timeout for service registration.
 */
int main(int argc, const char *argv[]) {
  NSString *deviceSerial = [NSUserDefaults.standardUserDefaults stringForKey:kDeviceIDArgumentKey];
  [NSUserDefaults.standardUserDefaults registerDefaults:@{
    kTimeoutArgumentKey : @(kDefaultTimeout)
  }];

  // If no target device specified and there is only one connected device, register service on it.
  // This is for the convenience of local testing.
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  if (![connector.connectedDevices containsObject:deviceSerial] &&
      connector.connectedDevices.count == 1) {
    deviceSerial = connector.connectedDevices.firstObject;
  }

  NS_VALID_UNTIL_END_OF_SCOPE ServiceRegistrationHelper *helper =
      [[ServiceRegistrationHelper alloc] initWithServiceNamePrefix:@"com.google.test.MacTestService"
                                                  numberOfServices:30];
  NSTimeInterval timeout = [NSUserDefaults.standardUserDefaults doubleForKey:kTimeoutArgumentKey];
  if (deviceSerial) {
    // TODO(ynzhang): catch the timeout issue and return a specific error.
    [helper registerServicesToDevice:deviceSerial queue:dispatch_get_main_queue() timeout:timeout];
    NSLog(@"Started the service for device %@ to connect.", deviceSerial);
    [NSRunLoop.mainRunLoop run];
  } else {
    NSLog(@"Cannot determine the target device to connect or no device available.");
    return -1;
  }
}
