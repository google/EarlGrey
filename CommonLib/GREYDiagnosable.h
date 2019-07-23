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

#import "GREYDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  @return Prefixed @c diagnosticsID for "core" matcher, action, and assertion.
 */
NSString *GREYCorePrefixedDiagnosticsID(NSString *diagnosticsID);

/** Private protocol for diagnostics purpose. */
@protocol GREYDiagnosable <NSObject>

@optional
/**
 *  Identifier with which diagnosable objects will have their diagnostics information associated.
 *  This is for internal use only. Please Do NOT override this externally.
 */
- (NSString *)diagnosticsID;

@end

NS_ASSUME_NONNULL_END
