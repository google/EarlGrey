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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "Device/Sources/EDODeviceConnector.h"
#import "Device/Sources/EDODeviceDetector.h"
#import "Device/Sources/EDOUSBMuxUtil.h"

static NSString *const kFakeSerialNumber = @"fake_serial";

// Exposes the internal property for test purpose.
@interface EDODeviceConnector ()
@property(nonatomic) EDODeviceDetector *detector;
@property(nonatomic) NSMutableDictionary *deviceInfo;
@end

@interface EDODeviceConnectorTest : XCTestCase
@end

@implementation EDODeviceConnectorTest

- (void)tearDown {
  [EDODeviceConnector.sharedConnector.deviceInfo removeAllObjects];
  [super tearDown];
}

/** Tests the successful attach and detach workflow. */
- (void)testAttachmentAndDetachmentSuccess {
  EDODeviceDetector *detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                                 listenError:nil
                                              broadcastError:nil
                                                       delay:0
                                                isAttachment:YES];
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  connector.detector = detector;
  XCTAssertTrue([connector.connectedDevices containsObject:kFakeSerialNumber]);
  connector.detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                        listenError:nil
                                     broadcastError:nil
                                              delay:0
                                       isAttachment:NO];
  XCTAssertFalse([connector.connectedDevices containsObject:kFakeSerialNumber]);
}

- (void)testMultipleAttachmentSuccess {
  EDODeviceDetector *detector = [self mockDetectorWithDeviceNumberAdded:2
                                                           repeatCycles:0
                                                         packetInterval:0.1];
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  connector.detector = detector;
  XCTAssertTrue(connector.connectedDevices.count == 2);
}

/** Tests the listen error in connector. */
- (void)testListenFailure {
  NSError *listenError = [NSError errorWithDomain:EDODeviceErrorDomain code:0 userInfo:nil];
  EDODeviceDetector *detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                                 listenError:listenError
                                              broadcastError:nil
                                                       delay:0
                                                isAttachment:YES];
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  connector.detector = detector;
  XCTAssertTrue(connector.connectedDevices.count == 0);
}

/** Tests the broadcast error in connector. */
- (void)testBroadcastFailure {
  NSError *broadcastError = [NSError errorWithDomain:EDODeviceErrorDomain code:0 userInfo:nil];
  EDODeviceDetector *detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                                 listenError:nil
                                              broadcastError:broadcastError
                                                       delay:0
                                                isAttachment:YES];
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  connector.detector = detector;
  XCTAssertFalse([connector.connectedDevices containsObject:kFakeSerialNumber]);
}

- (void)testDelayedAttachment {
  EDODeviceDetector *detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                                 listenError:nil
                                              broadcastError:nil
                                                       delay:5
                                                isAttachment:YES];
  EDODeviceConnector *connector = EDODeviceConnector.sharedConnector;
  connector.detector = detector;
  XCTAssertFalse([connector.connectedDevices containsObject:kFakeSerialNumber]);
  [NSThread sleepForTimeInterval:5];
  XCTAssertTrue([connector.connectedDevices containsObject:kFakeSerialNumber]);
  connector.detector = [self mockDetectorWithSerial:kFakeSerialNumber
                                        listenError:nil
                                     broadcastError:nil
                                              delay:0
                                       isAttachment:NO];
}

- (void)testParallelAttachmentsAndDetachments {
}

#pragma mark - test helper methods

- (id)mockDetectorWithSerial:(NSString *)deviceSerial
                 listenError:(NSError *)listenError
              broadcastError:(NSError *)broadcastError
                       delay:(NSTimeInterval)delay
                isAttachment:(BOOL)isAttachment {
  id mockDetector = OCMClassMock([EDODeviceDetector class]);
  OCMStub([mockDetector listenToBroadcastWithError:[OCMArg anyObjectRef] receiveHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        __strong NSError **errorPointer;
        [invocation getArgument:&errorPointer atIndex:2];
        EDOBroadcastHandler handler;
        [invocation getArgument:&handler atIndex:3];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                         if (listenError) {
                           if (errorPointer) {
                             *errorPointer = listenError;
                           }
                         } else {
                           NSDictionary *packet;
                           if (isAttachment) {
                             packet = @{
                               kEDOMessageTypeKey : kEDOMessageTypeAttachedKey,
                               kEDOMessageDeviceIDKey : @(deviceSerial.hash),
                               kEDOMessagePropertiesKey :
                                   @{kEDOMessageSerialNumberKey : deviceSerial}
                             };
                           } else {
                             packet = @{
                               kEDOMessageTypeKey : kEDOMessageTypeDetachedKey,
                               kEDOMessageDeviceIDKey : @(deviceSerial.hash)
                             };
                           }
                           handler(broadcastError ? nil : packet, broadcastError);
                         }
                       });
      })
      .andReturn(listenError == nil);
  OCMStub([mockDetector cancel]).andDo(^(NSInvocation *invocation) {
    [mockDetector stopMocking];
  });
  return mockDetector;
}

- (id)mockDetectorWithDeviceNumberAdded:(NSUInteger)deviceNumber
                           repeatCycles:(NSUInteger)cycles
                         packetInterval:(NSTimeInterval)packetInterval {
  id mockDetector = OCMClassMock([EDODeviceDetector class]);
  OCMStub([mockDetector listenToBroadcastWithError:[OCMArg anyObjectRef] receiveHandler:OCMOCK_ANY])
      .andDo((^(NSInvocation *invocation) {
        EDOBroadcastHandler handler;
        [invocation getArgument:&handler atIndex:3];
        for (NSUInteger i = 0; i < deviceNumber; i++) {
          NSString *fakeDeviceSerial =
              [NSString stringWithFormat:@"%@%lu", kFakeSerialNumber, (unsigned long)i];
          NSUInteger deviceID = fakeDeviceSerial.hash;
          dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            NSDictionary *attachmentPacket = @{
              kEDOMessageTypeKey : kEDOMessageTypeAttachedKey,
              kEDOMessageDeviceIDKey : @(deviceID),
              kEDOMessagePropertiesKey : @{kEDOMessageSerialNumberKey : fakeDeviceSerial}
            };
            NSDictionary *detachmentPacket = @{
              kEDOMessageTypeKey : kEDOMessageTypeDetachedKey,
              kEDOMessageDeviceIDKey : @(deviceID)
            };
            handler(attachmentPacket, nil);
            for (NSUInteger j = 0; j < cycles; j++) {
              [NSThread sleepForTimeInterval:packetInterval];
              handler(detachmentPacket, nil);
              [NSThread sleepForTimeInterval:packetInterval];
              handler(attachmentPacket, nil);
            }
          });
        }
      }))
      .andReturn(YES);
  OCMStub([mockDetector cancel]).andDo(^(NSInvocation *invocation) {
    [mockDetector stopMocking];
  });
  return mockDetector;
}

@end
