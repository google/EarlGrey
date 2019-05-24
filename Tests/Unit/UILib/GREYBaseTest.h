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

#import <XCTest/XCTest.h>

#import "UILib/GREYScreenshotter+Private.h"

// A wrapper for OCMock to get a corresponding NSValue for the struct.
#define OCMOCK_STRUCT(atype, variable) [NSValue valueWithBytes:&variable objCType:@encode(atype)]

// Declare the CGRect variable.
extern const CGRect kTestRect;

// Base test class for every UILib unit test.
@interface GREYBaseTest : XCTestCase

// Returns mocked shared application.
- (id)mockSharedApplication;

// Adds |screenshot| to be returned by GREYScreenshotter.
// |screenshot| is added to a list of screenshot that will be returned in-order at each invocation
// of takeScreenshot. After exhausting the screenshot list, subsequent invocations will return nil.
- (void)addToScreenshotListReturnedByScreenshotter:(UIImage *)screenshot;

@end

@interface GREYScreenshotter (UnitTest)

// Original version of the save image method (for related test)
+ (NSString *)greyswizzled_fakeSaveImageAsPNG:(UIImage *)image
                                       toFile:(NSString *)filename
                                  inDirectory:(NSString *)directoryPath;

@end
