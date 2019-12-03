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

#import "GREYFrameworkException.h"
#import "GREYHostApplicationDistantObject+IntentionalCrash.h"

@implementation GREYHostApplicationDistantObject (IntentionalCrash)

- (void)delayedExceptionWithTime:(NSTimeInterval)waitTime {
  dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * waitTime));
  dispatch_after(startTime, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    [[GREYFrameworkException
        exceptionWithName:@"GREYIntentionalException"
                   reason:@"This exception is thrown intentionally from test side."] raise];
  });
}

@end
