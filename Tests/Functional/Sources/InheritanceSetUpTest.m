//
// Copyright 2026 Google Inc.
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

#import "BaseIntegrationTest.h"

static BOOL gParentSetUpCalled = NO;
static BOOL gChildSetUpCalled = NO;

@interface ASwizzleParentTest : BaseIntegrationTest
@end

@implementation ASwizzleParentTest

- (void)setUp {
  [super setUp];
  gParentSetUpCalled = YES;
}

- (void)tearDown {
  gParentSetUpCalled = NO;
  [super tearDown];
}

- (void)testParent {
  XCTAssertTrue(gParentSetUpCalled);
}

@end

@interface BSwizzleChildTest : ASwizzleParentTest
@end

@implementation BSwizzleChildTest

- (void)setUp {
  [super setUp];
  gChildSetUpCalled = YES;
}

- (void)tearDown {
  gChildSetUpCalled = NO;
  [super tearDown];
}

- (void)testChild {
  XCTAssertTrue(gParentSetUpCalled);
  XCTAssertTrue(gChildSetUpCalled);
}

@end

@interface CSwizzleGrandChildTest : BSwizzleChildTest
@end

@implementation CSwizzleGrandChildTest

- (void)testGrandChild {
  XCTAssertTrue(gParentSetUpCalled);
  XCTAssertTrue(gChildSetUpCalled);
}

@end
