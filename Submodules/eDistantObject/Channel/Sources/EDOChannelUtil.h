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

#import <Foundation/Foundation.h>

#ifndef EDOCHANNEL_UTIL_H_
#define EDOCHANNEL_UTIL_H_

#if defined(__cplusplus)
extern "C" {
#endif

/** Gets the size of the frame header. */
size_t EDOGetPayloadHeaderSize(void);

/** Gets the size of the payload from the frame header. */
size_t EDOGetPayloadSizeFromFrameData(dispatch_data_t data);

/**
 *  Creates @c dispatch_data_t from NSData that has the frame header and is ready to be sent.
 *
 *  @param data   The data to be sent.
 *  @param queue  The dispatch queue on which to release the @c data.
 *
 *  @return The dispatch data containing the frame header and the given data.
 */
dispatch_data_t EDOBuildFrameFromDataWithQueue(NSData *data, dispatch_queue_t queue);

#if defined(__cplusplus)
}  //   extern "C"
#endif

#endif
