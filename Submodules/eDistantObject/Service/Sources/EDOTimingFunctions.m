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

#import "Service/Sources/EDOTimingFunctions.h"

#include <dispatch/dispatch.h>

double EDOGetMillisecondsSinceMachTime(uint64_t machTime) {
  uint64_t elapsedTime = mach_absolute_time() - machTime;

  static mach_timebase_info_data_t timebaseInfo;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mach_timebase_info(&timebaseInfo);
  });
  uint64_t nanos = elapsedTime * timebaseInfo.numer / timebaseInfo.denom;

  return (double)nanos / NSEC_PER_MSEC;
}
