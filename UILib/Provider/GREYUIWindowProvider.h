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

#import "GREYProvider.h"

@class UIApplication;
@class UIWindow;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Fetches the key window of @c application.
 *
 *  @param application The UIApplication to look for key window.
 *
 *  @return A UIWindow instance that specifies the key window of the @c application.
 */
UIWindow *GREYGetApplicationKeyWindow(UIApplication *application);

/**
 *  A provider for UIApplication windows. By default, all application windows are returned unless
 *  this provider is initialized with custom windows.
 */
@interface GREYUIWindowProvider : NSObject <GREYProvider>

/**
 *  Class method to get a provider with the specified @c windows.
 *
 *  @param windows An array of UIApplication windows to populate the provider.
 *
 *  @return A GREYUIWindowProvider instance populated with the UIApplication windows in @c windows.
 */
+ (instancetype)providerWithWindows:(NSArray<UIWindow *> *)windows;

/**
 *  Class method to get a provider with all the windows currently registered with the app.
 *
 *  @param includeStatusBar Should the status bar be included in the list of windows.
 *
 *  @remark Will create a local status bar if iOS 13+.
 *
 *  @return A GREYUIWindowProvider instance populated by all windows currently
 *          registered with the app.
 */
+ (instancetype)providerWithAllWindowsWithStatusBar:(BOOL)includeStatusBar;

/**
 *  @param includeStatusBar Include the status bar in the window hierarchy.
 *
 *  @remark Will create a local status bar if iOS 13+.
 *
 *  @return A set of all application windows ordered by window-level from back to front.
 */
+ (NSArray<UIWindow *> *)allWindowsWithStatusBar:(BOOL)includeStatusBar;

/**
 *  Returns all application windows in front of @c window, including itself, ordered by
 *  window-level from back to front.
 *
 *  @param window           Window to start collecting from.
 *  @param includeStatusBar Include the status bar in the window hierarchy.
 *
 *  @remark Will create a local status bar if iOS 13+.
 *
 *  @return A set of all application windows ordered by window-level from back to front.
 */
+ (NSArray<UIWindow *> *)windowsFromLevelOfWindow:(UIWindow *)window
                                    withStatusBar:(BOOL)includeStatusBar;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Designated Initializer.
 *
 *  @param windows          UIWindows to populate the provider with.
 *  @param includeStatusBar Should the status bar window be included in the list of windows.
 *
 *  @return A GREYUIWindowProvider instance, populated with the specified windows.
 */
- (instancetype)initWithWindows:(NSArray<UIWindow *> *)windows
                  withStatusBar:(BOOL)includeStatusBar NS_DESIGNATED_INITIALIZER;

/**
 *  Initializes this provider with all application windows.
 *
 *  @param includeStatusBar Should the status bar be included in the list of windows.
 *
 *  @remark Will create a local status bar if iOS 13+.
 *
 *  @return A GREYUIWindowProvider instance populated by all windows currently
 *          registered with the app.
 */
- (instancetype)initWithAllWindowsWithStatusBar:(BOOL)includeStatusBar;

#pragma mark - GREYProvider

/**
 *  @return An enumerator for @c windows populating the window provider.
 */
- (NSEnumerator *)dataEnumerator;

@end

NS_ASSUME_NONNULL_END
