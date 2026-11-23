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

NS_ASSUME_NONNULL_BEGIN

/**
 * Fetches the key window of @c application.
 *
 * @param application The UIApplication to look for key window.
 *
 * @return A UIWindow instance that specifies the key window of the @c application.
 */
UIWindow *_Nullable GREYUILibUtilsGetApplicationKeyWindow(UIApplication *application);

UIWindow *_Nullable GREYUILibUtilsGetKeyboardWindow(void);  // NOLINT

/**
 *
 * @remark Will create an array of windows related to the connected scenes.
 *
 * @return A set of all application windows.
 */
NSArray<UIWindow *> *GREYUILibUtilsGetAllWindowsFromConnectedScenes(void);  // NOLINT

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
+ (nullable UIScreen *)screen;

/**
 * @return A UIWindow which is the window on which all the scenes/view are rendered
 *
 * @note @c window is exposed as a class method instead of a C function,  because class
 * methods can be invoked by other processes including test processes via eDO unlike C functions
 */
+ (nullable UIWindow *)window;

/**
 * @return The app's currently connected scenes.
 *
 * @note @c windowScene is exposed as a class method instead of a C function,  because class
 * methods can be invoked by other processes including test processes via eDO unlike C functions.
 */
+ (NSSet<UIScene *> *)connectedScenes API_AVAILABLE(ios(13.0));

/**
 * @return The active @c UIWindowScene for the application, prioritizing foreground-active
 *         application scenes (and the key window's scene) over inactive or accessory scenes, or
 *         @c nil if no window scene is connected.
 */
+ (nullable UIWindowScene *)activeWindowScene API_AVAILABLE(ios(13.0));

#if TARGET_OS_IOS
/**
 * Requests a geometry update on @c scene to rotate to @c interfaceOrientation.
 *
 * @param scene                The target @c UIWindowScene to rotate.
 * @param interfaceOrientation The target interface orientation.
 * @param errorHandler         A block invoked with value-type error details if the system rejects
 *                             the geometry update request.
 *
 * @return @c YES if the geometry update request was dispatched to @c scene, @c NO if
 *         @c interfaceOrientation is invalid or @c scene is @c nil.
 */
+ (BOOL)rotateWindowScene:(nullable UIWindowScene *)scene
    toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
              errorHandler:(nullable void (^)(NSString *_Nullable domain, NSInteger code,
                                              NSString *_Nullable localizedDescription))errorHandler
    API_AVAILABLE(ios(13.0));
#endif  // TARGET_OS_IOS

/**
 * @return The frame for the keyboard present on the screen.
 */
+ (CGRect)scaledKeyboardFrame;

@end

NS_ASSUME_NONNULL_END
