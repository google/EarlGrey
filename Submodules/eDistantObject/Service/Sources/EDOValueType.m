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

/** Enable the type to be the value type so it will be passed by copy. */
#define EDO_ENABLE_VALUETYPE(__class) \
  @implementation __class (EDOValue)  \
  -(BOOL)edo_isEDOValueType {         \
    return YES;                       \
  }                                   \
  @end

EDO_ENABLE_VALUETYPE(NSCalendar)
EDO_ENABLE_VALUETYPE(NSData)
EDO_ENABLE_VALUETYPE(NSDate)
EDO_ENABLE_VALUETYPE(NSDateComponents)
EDO_ENABLE_VALUETYPE(NSIndexSet)
EDO_ENABLE_VALUETYPE(NSIndexPath)
EDO_ENABLE_VALUETYPE(NSString)
EDO_ENABLE_VALUETYPE(NSTimeZone)
EDO_ENABLE_VALUETYPE(NSValue)
EDO_ENABLE_VALUETYPE(NSURL)
