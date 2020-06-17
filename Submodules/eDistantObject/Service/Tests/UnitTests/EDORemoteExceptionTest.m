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

#import <XCTest/XCTest.h>

#import "Service/Sources/EDOBlockObject.h"
#import "Service/Sources/EDOObject+Private.h"
#import "Service/Sources/EDORemoteException.h"
#import "Service/Sources/EDOServicePort.h"
#import "Service/Sources/NSKeyedArchiver+EDOAdditions.h"
#import "Service/Sources/NSKeyedUnarchiver+EDOAdditions.h"

@interface EDORemoteExceptionTest : XCTestCase
@end

@implementation EDORemoteExceptionTest

- (void)testThrowInvocationException {
  EDORemoteException *exception =
      [[EDORemoteException alloc] initWithName:@"dummy name"
                                        reason:@"dummy reason"
                              callStackSymbols:[NSThread callStackSymbols]];
  XCTAssertThrowsSpecificNamed([self throwInvocationException:exception], EDORemoteException,
                               @"dummy name");
}

- (void)testExceptionSerialization {
  EDORemoteException *exception =
      [[EDORemoteException alloc] initWithName:@"dummy name"
                                        reason:@"dummy reason"
                              callStackSymbols:[NSThread callStackSymbols]];

  NSData *encodedData = [NSKeyedArchiver edo_archivedDataWithObject:exception];
  exception = [NSKeyedUnarchiver edo_unarchiveObjectWithData:encodedData];

  XCTAssertEqualObjects(exception.name, @"dummy name");
  XCTAssertEqualObjects(exception.reason, @"dummy reason");
  NSString *callStackSymbols = [exception.callStackSymbols componentsJoinedByString:@"|"];
  XCTAssertTrue([callStackSymbols containsString:@"testExceptionSerialization"]);
}

- (void)throwInvocationException:(EDORemoteException *)exception {
  @throw exception;  // NOLINT
}

@end
