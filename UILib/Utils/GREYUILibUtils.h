//
// Copyright 2022 Google Inc.
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

#import <UIKit/UIKit.h>

/**
 * Fetches the key window of @c application.
 *
 * @param application The UIApplication to look for key window.
 *
 * @return A UIWindow instance that specifies the key window of the @c application.
 */
UIWindow *GREYUILibUtilsGetApplicationKeyWindow(UIApplication *application);

UIWindow *GREYUILibUtilsGetKeyboardWindow(void);  // NO_LINT

/**
 * A provider for UIApplication windows. By default, all application windows are returned unless
 * this provider is initialized with custom windows.
 */
@interface GREYUILibUtils : NSObject

/**
 * @return A UIScreen screen which is the highest level view in the hierarchy of elements
 *
 * @note If this API is called in a unit test class, the test should wait for UIScene to become
 * active with UISceneDelegate, otherwise the API might fail or become flaky.
 *
 * @note @c screen is exposed as a class method instead of a C function,  because class
 * methods can be invoked by other processes including test processes via eDO unlike C functions
 */
+ (UIScreen *)screen;

/**
 * @return A UIWindow which is the window on which all the scenes/view are rendered
 *
 * @note @c window is exposed as a class method instead of a C function,  because class
 * methods can be invoked by other processes including test processes via eDO unlike C functions
 */
+ (UIWindow *)window;

@end
