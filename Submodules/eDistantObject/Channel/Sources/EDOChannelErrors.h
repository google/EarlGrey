//
// Copyright 2019 Google Inc.
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

#ifndef EDOCHANNEL_ERRORS_H_
#define EDOCHANNEL_ERRORS_H_

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const EDOChannelErrorDomain;

NS_ERROR_ENUM(EDOChannelErrorDomain){
    EDOChannelErrorFetchFailed = 100,
};

/** Error code of failure to fetch channel. **/
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOChannelFetchFailedCode;

/**
 *  Key in userInfo, the value is a host port which the error generating channel
 * that connects to it.
 */
FOUNDATION_EXPORT NSErrorUserInfoKey const EDOChannelPortKey;

/** Error code for the channel forwarder. */
typedef NS_ENUM(NSUInteger, EDOForwarderError) {
  /** Indicates the initial handshake fails. */
  EDOForwarderErrorHandshake = -1000,
  /** Indicates the port received is not serializable. */
  EDOForwarderErrorPortSerialization,
  /** Indicates the forwarder fails to establish the connection with the given port. */
  EDOForwarderErrorPortConnection,
  /** Indicates the multiplexer closes or errors on the channel. */
  EDOForwarderErrorMultiplerxerClosed,
  /** Indicates the forwarded channel closes or errors on the channel. */
  EDOForwarderErrorForwardedChannelClosed,
};

#endif
