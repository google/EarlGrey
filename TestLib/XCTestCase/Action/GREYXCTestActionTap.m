//
// Copyright 2024 Google Inc.
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

#import "GREYXCTestActionTap.h"
#import "NSObject+GREYCommon.h"

@implementation GREYXCTestActionTap

- (void)performOnElement:(id)element {
#if TARGET_OS_TV
#else
  UIView *viewContainer = [element grey_viewContainingSelf];
  CGSize windowSize = viewContainer.window.frame.size;
  CGPoint elementOrigin = [element accessibilityActivationPoint];

  CGVector accesspointOffset =
      CGVectorMake(elementOrigin.x / windowSize.width, elementOrigin.y / windowSize.height);
  XCUIApplication *application = [[XCUIApplication alloc] init];

  XCUIElement *window = [application.windows elementBoundByIndex:0];
  [[window coordinateWithNormalizedOffset:accesspointOffset] tap];
#endif
}

@end
