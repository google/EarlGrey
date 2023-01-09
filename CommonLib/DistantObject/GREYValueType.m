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

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

/** Enable the type to be the value type so it will be passed by copy. */
#define EDO_ENABLE_VALUETYPE(__class) \
  @implementation __class (EDOValue)  \
  -(BOOL)edo_isEDOValueType {         \
    return YES;                       \
  }                                   \
  @end

/**
 * These are classes that will always be value type with eDO in an EarlGrey test so that we don't
 * run into issues with internal calls that would not work if they were stubbed as references by
 * eDO.
 *
 * DO NOT CREATE STUBS ON THESE CLASSES WITH GREY_REMOTE_CLASS_IN_APP.
 */
EDO_ENABLE_VALUETYPE(CLLocation)
EDO_ENABLE_VALUETYPE(CLLocationManager)
EDO_ENABLE_VALUETYPE(UIImage)
EDO_ENABLE_VALUETYPE(UIColor)
EDO_ENABLE_VALUETYPE(NSAttributedString)
