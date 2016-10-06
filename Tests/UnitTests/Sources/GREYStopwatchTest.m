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

#import <EarlGrey/GREYStopwatch.h>

#import "GREYBaseTest.h"

@interface GREYStopwatchTest : XCTestCase

@end

@implementation GREYStopwatchTest

- (void)testLappingWhenWatchIsStartedAndStopped {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch lapAndReturnTime], @"Stopwatch lapping cannot be done when the "
                                                @"stopwatch wasn't turned on");
  [stopwatch start];
  XCTAssertNoThrow([stopwatch lapAndReturnTime]);
  [stopwatch stop];
  XCTAssertThrows([stopwatch lapAndReturnTime], @"Stopwatch lapping cannot be done when the "
                                                @"stopwatch is off.");
}

- (void)testCheckingElapsedTimeWatchIsStartedAndStopped {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch elapsedTime], @"Stopwatch has to be started to get elapsed time.");
  [stopwatch start];
  [stopwatch stop];
  NSTimeInterval interval;
  XCTAssertNoThrow(interval = [stopwatch elapsedTime]);
  [stopwatch start];
  [self grey_benchmarkOperation];
  NSTimeInterval noStopInterval = [stopwatch elapsedTime];
  XCTAssertGreaterThan(noStopInterval, interval, @"Should be able to get elapsed time without "
                                                 @"calling stop");
  [stopwatch stop];
  XCTAssertGreaterThan([stopwatch elapsedTime], noStopInterval, @"Stopping should make the "
                                                                @"elapsed time now greater.");
}

- (void)testStopwatchTimeOnActionBeingPerformedAndNoActionPerformed {
  GREYStopwatch *noActionStopwatch = [[GREYStopwatch alloc] init];
  [noActionStopwatch start];
  [noActionStopwatch stop];
  NSTimeInterval intervalOnNoActionPerformed = [noActionStopwatch elapsedTime];

  GREYStopwatch *someActionStopwatch = [[GREYStopwatch alloc] init];
  [someActionStopwatch start];
  [self grey_benchmarkOperation];
  [someActionStopwatch stop];
  NSTimeInterval intervalOnSomeActionPerformed = [someActionStopwatch elapsedTime];
  XCTAssertGreaterThan(intervalOnSomeActionPerformed,
                       intervalOnNoActionPerformed,
                       @"Interval on some action being performed was not greater than that on no"
                       @" action being performed");
}

- (void)testStopwatchWithinStopwatch {
  GREYStopwatch *outerStopwatch = [[GREYStopwatch alloc] init];
  [outerStopwatch start];
  GREYStopwatch *innerStopwatch = [[GREYStopwatch alloc] init];
  [innerStopwatch start];
  BOOL someValue = YES;
  NSAssert(someValue, @"This value is always positive");
  [innerStopwatch stop];
  NSTimeInterval timeForInnerStopwatch = [innerStopwatch elapsedTime];
  [outerStopwatch stop];
  NSTimeInterval timeForOuterStopwatch = [outerStopwatch elapsedTime];
  XCTAssertGreaterThan(timeForOuterStopwatch,
                       timeForInnerStopwatch,
                       @"The outer stop watch, should have a higher value.");
}

- (void)testStopwatchTimesWithBenchmark {
  GREYStopwatch *benchmarkStopwatch = [[GREYStopwatch alloc] init];
  GREYStopwatch *testStopwatch = [[GREYStopwatch alloc] init];
  [benchmarkStopwatch start];
  [testStopwatch start];
  [self grey_benchmarkOperation];
  [benchmarkStopwatch stop];
  [testStopwatch stop];
  NSTimeInterval difference =
      ([benchmarkStopwatch elapsedTime] - [testStopwatch elapsedTime]) / 0.5;
  NSTimeInterval minTime = MIN([testStopwatch elapsedTime], [benchmarkStopwatch elapsedTime]) ;

  XCTAssertGreaterThan(minTime, difference, @"The difference between times shouldn't be huge.");
}

- (void)testStopwatchStoppingWithoutStarting {
  GREYStopwatch *stopwatch = [[GREYStopwatch alloc] init];
  XCTAssertThrows([stopwatch stop], @"Calling stop on a stopwatch that isn't started will fail.");
  XCTAssertThrows([stopwatch elapsedTime], @"Calling elapsed time stop on a stopwatch that"
                                                @" isn't started will return a NaN");
}

- (void)testStopwatchWithLappingAndAddingStartAndStopElapsedTimes {
  GREYStopwatch *lappingStopwatch = [[GREYStopwatch alloc] init];
  [lappingStopwatch start];
  [self grey_benchmarkOperation];
  NSTimeInterval lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  NSTimeInterval elapsedTime = [lappingStopwatch elapsedTime];
  [lappingStopwatch start];
  XCTAssert(fabs(elapsedTime - lapTime) < 0.1 * lapTime, @"On being called the first time, elapsed"
            @" and lap times should be very similar");
  [self grey_benchmarkOperation];
  lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  elapsedTime += [lappingStopwatch elapsedTime];
  [lappingStopwatch start];
  XCTAssert(elapsedTime > 1.5 * lapTime, @"On being called after the first time,"
            @" elapsed time should be much greater than lap time");
  [self grey_benchmarkOperation];
  lapTime = [lappingStopwatch lapAndReturnTime];
  [lappingStopwatch stop];
  elapsedTime += [lappingStopwatch elapsedTime];
  XCTAssert(elapsedTime > 2.5 * lapTime, @"On being called after the first time,"
                                         @" elapsed time should be much greater than lap time");
}

#pragma mark - Private

- (void)grey_benchmarkOperation {
  NSMutableArray *array = [[NSMutableArray alloc] initWithArray:@[@"a", @"b", @"c"]];
  for (int i = 1; i < 1000; i++) {
    [array addObject:[NSString stringWithFormat:@"Foo Value : %d", i]];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [view setBackgroundColor:[UIColor greenColor]];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
    [containerView setBackgroundColor:[UIColor redColor]];
    [containerView addSubview:view];
  }
  NSArray *copyArray = [NSArray arrayWithArray:array];
  NSAssert([copyArray count] > 0, @"The array should always contain objects");
}

@end
