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

#import "Measure/Sources/EDONumericMeasure.h"

#import <XCTest/XCTest.h>

@interface EDONumericMeasureTest : XCTestCase
@end

@implementation EDONumericMeasureTest

- (void)testFreshMeasure {
  EDONumericMeasure *measure = [EDONumericMeasure measure];
  XCTAssertEqual(measure.measureCount, 0U);
  XCTAssertThrows(measure.average);
  XCTAssertTrue([measure complete]);
  XCTAssertEqual(measure.average, 0);
  XCTAssertEqual(measure.maximum, DBL_MIN);
  XCTAssertEqual(measure.minimum, DBL_MAX);
  XCTAssertFalse([measure complete]);
}

- (void)testMeasureWithOneValue {
  EDONumericMeasure *measure = [EDONumericMeasure measure];
  [measure addSingleValue:100];
  XCTAssertTrue([measure complete]);

  XCTAssertEqual(measure.measureCount, 1U);
  XCTAssertEqualWithAccuracy(measure.average, 100, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.minimum, 100, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.maximum, 100, DBL_EPSILON);
}

- (void)testMeasureIgnoredAfterCompletion {
  EDONumericMeasure *measure = [EDONumericMeasure measure];
  [measure addSingleValue:50];
  XCTAssertTrue([measure complete]);

  [measure addSingleValue:100];
  XCTAssertEqual(measure.measureCount, 1U);
  XCTAssertEqualWithAccuracy(measure.average, 50, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.minimum, 50, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.maximum, 50, DBL_EPSILON);
}

- (void)testMeasureWithMultipleValues {
  EDONumericMeasure *measure = [EDONumericMeasure measure];
  for (NSNumber *value in @[ @10, @20, @30, @40 ]) {
    [measure addSingleValue:value.doubleValue];
  }
  XCTAssertTrue([measure complete]);

  XCTAssertEqual(measure.measureCount, 4U);
  XCTAssertEqualWithAccuracy(measure.average, 25, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.minimum, 10, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.maximum, 40, DBL_EPSILON);
}

- (void)testMeasureWithMultipleQueues {
  EDONumericMeasure *measure = [EDONumericMeasure measure];

  dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
  for (int i = 1; i <= 100; ++i) {
    dispatch_async(concurrentQueue, ^{
      for (NSNumber *value in @[ @(10 * i), @(20 * i), @(30 * i), @(40 * i) ]) {
        [measure addSingleValue:value.doubleValue];
      }
    });
  }
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"measureCount == 400"];
  XCTNSPredicateExpectation *expect = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate
                                                                                    object:measure];
  [self waitForExpectations:@[ expect ] timeout:4];
  XCTAssertTrue([measure complete]);

  // Use a broader tolerance as this seems to produce more errors on some machines.
  XCTAssertEqualWithAccuracy(measure.average, 1262.5, 0.1);
  XCTAssertEqualWithAccuracy(measure.minimum, 10, DBL_EPSILON);
  XCTAssertEqualWithAccuracy(measure.maximum, 4000, DBL_EPSILON);
}

@end
