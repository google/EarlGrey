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

#import "AppFramework/EarlGreyApp/EarlGreyApp.h"
#import "CommonLib/DistantObject/GREYHostApplicationDistantObject.h"
#import "Service/Sources/EDORemoteVariable.h"

/** GREYHostApplicationDistantObject extension for the geometry test. */
@interface GREYHostApplicationDistantObject (GeometryTest)

/**
 * Takes a CGRect and returns it with respect to a fixed coordinate system.
 *
 * @param rect A CGRect that conforms to a variable coordinate system.
 *
 * @return A CGRect set to the fixed coordinate system in the app.
 */
- (CGRect)fixedCoordinateRectFromRect:(CGRect)rect;

/**
 * Takes a CGRect and returns it with respect to a variable coordinate system.
 *
 * @param rect A CGRect that conforms to a fixed coordinate system.
 *
 * @return A CGRect set to the variable coordinate system in the app.
 */
- (CGRect)variableCoordinateRectFromRect:(CGRect)rect;

@end
