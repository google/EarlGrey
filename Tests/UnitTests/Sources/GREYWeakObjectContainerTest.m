//
// Copyright 2016 Google Inc.
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

#import <EarlGrey/GREYWeakObjectContainer.h>

#import "GREYBaseTest.h"

@interface GREYWeakObjectContainerTest : GREYBaseTest
@end

@implementation GREYWeakObjectContainerTest

- (void)testRetrievingObject {
  NSObject *object = [[NSObject alloc] init];
  GREYWeakObjectContainer *container = [[GREYWeakObjectContainer alloc] initWithObject:object];
  XCTAssertNotNil([container object], @"Contained object should still referenced");
  XCTAssertEqual(object, [container object], @"Objects should have the same pointer value");
}

- (void)testRetrievingDeallocatedObject {
  GREYWeakObjectContainer *container;
  @autoreleasepool {
    __autoreleasing NSObject *object = [[NSObject alloc] init];
    container = [[GREYWeakObjectContainer alloc] initWithObject:object];
    XCTAssertNotNil([container object], @"Contained object should still referenced");
    XCTAssertEqual(object, [container object], @"Objects should have the same pointer value");
  }
  XCTAssertNil([container object], @"Contained object should have been deallocated.");
}

@end

