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

#import <EarlGrey/GREYDefines.h>

/**
 * @file
 * @brief GREYBeaconImageProtocol header file.
 */

/**
 *  The URL scheme used by EarlGrey beacon image.
 */
GREY_EXTERN NSString *const kGREYBeaconScheme;

/**
 *  The path at which EarlGrey beacon image is served.
 */
GREY_EXTERN NSString *const kGREYBeaconImagePath;

/**
 *  A NSURLProtocol subclass for handling beacon image requests. Earlgrey beacon image is a
 *  1X1 invisible PNG image that EarlGrey injects into the webpage for synchronization, we serve
 *  it using this class to avoid hitting the network, this allows us to synchronize even when
 *  network is unreachable.
 */
@interface GREYBeaconImageProtocol : NSURLProtocol
@end
