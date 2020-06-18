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

/** The notification when an iOS device is attached to MacOS. */
extern NSString *const EDODeviceDidAttachNotification;
/** The notification when an iOS device is dettached to MacOS. */
extern NSString *const EDODeviceDidDetachNotification;

/** The key to extract info from notifications of device attachment/detachment events. */
extern NSString *const EDODeviceSerialKey;
extern NSString *const EDODeviceIDKey;

/**
 *  This singleton class connects to the listen port of @c EDOHostService on physical iOS device
 *  from Mac.
 *
 *  When fetching @c connectedDevices, the connector will implicitly connect to usbmuxd, and then
 *  return all connected device. Listening to
 *  @c EDODeviceDidAttachNotification/EDODeviceDidDetachNotification
 *  will work after connector starts listening. By calling connectToDevice:onPort:error:, a channel
 *  connected to the listen port in the iOS device will be created.
 */
@interface EDODeviceConnector : NSObject

/** The serial numbers of connected devices. */
@property(readonly) NSArray<NSString *> *connectedDevices;
/** Shared device connector. */
@property(readonly, class) EDODeviceConnector *sharedConnector;

- (instancetype)init NS_UNAVAILABLE;

/**
 *  Synchronously connects to a given @c deviceSerial and @c port listening on the connected device
 *  of that device serial.
 *
 *  @param deviceSerial The device serial string of the device to connect.
 *  @param port         The listen port number running on the target device.
 *  @param error        The out error indicating failures of connect to the listen port.
 *
 *  @return The dispatch I/O channel connected to the target device and ready to use. @c NULL if
 *          any error occurred during the connection.
 */
- (dispatch_io_t)connectToDevice:(NSString *)deviceSerial
                          onPort:(UInt16)port
                           error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
