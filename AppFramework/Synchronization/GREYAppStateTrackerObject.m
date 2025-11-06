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

#import "GREYAppStateTrackerObject.h"

#import "GREYAppState.h"

static CFCalendarRef gGREYAppStateTrackerObjectCalendar;

@implementation GREYAppStateTrackerObject {
  CFAbsoluteTime _absoluteStateAssignmentTime;
}

+ (void)initialize {
  if (self == [GREYAppStateTrackerObject class]) {
    gGREYAppStateTrackerObjectCalendar =
        CFCalendarCreateWithIdentifier(kCFAllocatorSystemDefault, kCFGregorianCalendar);
    CFTimeZoneRef tz = CFTimeZoneCopySystem();
    CFCalendarSetTimeZone(gGREYAppStateTrackerObjectCalendar, tz);
    CFRelease(tz);
  }
}

- (instancetype)initWithDeallocationTracker:(GREYObjectDeallocationTracker *)deallocationTracker {
  self = [super init];
  if (self) {
    _state = kGREYIdle;
    _object = deallocationTracker;
    _absoluteStateAssignmentTime = CFAbsoluteTimeGetCurrent();
  }
  return self;
}

#pragma mark - Setter

- (void)setState:(GREYAppState)state {
  _state = state;
  _stateAssignmentCallStack = [NSThread callStackSymbols];
  _absoluteStateAssignmentTime = CFAbsoluteTimeGetCurrent();
}

- (NSString *)timeOfStateAssignment {
  // Print out a date with millisecond precision. This is the same way CFLog does it.
  double atf;
  int32_t ms = (int32_t)floor(1000.0 * modf(_absoluteStateAssignmentTime, &atf));
  int32_t year, month, day, hour, minute, second;
  CFCalendarDecomposeAbsoluteTime(gGREYAppStateTrackerObjectCalendar, _absoluteStateAssignmentTime,
                                  "yMdHms", &year, &month, &day, &hour, &minute, &second);
  return [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d.%03d", year, month, day, hour,
                                    minute, second, ms];
}
@end
