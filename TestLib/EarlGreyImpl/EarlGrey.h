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

#import "GREYAction.h"
#import "GREYActionsShorthand.h"
#import "GREYHostBackgroundDistantObject+GREYApp.h"
#import "GREYMatchersShorthand.h"
#import "GREYAssertionBlock.h"
#import "GREYConfiguration.h"
#import "GREYHostApplicationDistantObject.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYDefines.h"
#import "GREYElementMatcherBlock.h"
#import "GREYMatcher.h"
#import "XCTestCase+GREYSystemAlertHandler.h"
#import "GREYAssertionDefines.h"
#import "GREYCondition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Key for setting a new or retrieving the existing failure handler for EarlGrey. Each failure
 *  handler is tied to the existing thread object's dictionary. When an EarlGrey call fails, it
 *  calls into the currently set failure handler to handle the exception.
 *
 *  To set a new failure handler (for the current thread):
 *   @code
 *   [NSThread currentThread].threadDictionary[GREYFailureHandlerKey] = newHandler;
 *   @endcode
 *
 *  To get the failure handler (for the current thread):
 *   @code
 *   id<GREYFailureHandler> currentHandler =
 *       [NSThread currentThread].threadDictionary[GREYFailureHandlerKey];
 *   @endcode
 *
 *  @note It's possible that the current thread does not have a handler, in which case one will be
 *        created and assigned by EarlGrey when it's called.
 */
GREY_EXTERN NSString *const GREYFailureHandlerKey;

/**
 *  Convenience replacement for every EarlGrey method call with
 *  EarlGreyImpl::invokedFromFile:lineNumber: so it can get the invocation file and line to
 *  report to XCTest on failure.
 */
#define EarlGrey                                                                            \
  [EarlGreyImpl invokedFromFile:[NSString stringWithUTF8String:__FILE__] ?: @"UNKNOWN FILE" \
                     lineNumber:__LINE__]

/**
 *  Entry point to the EarlGrey framework.
 *  Use methods of this class to initiate interaction with any UI element on the screen.
 */
@interface EarlGreyImpl : NSObject

/**
 *  Provides the file name and line number of the code that is calling into EarlGrey.
 *  In case of a failure, the information is used to tell XCTest the exact line which caused
 *  the failure so it can be highlighted in the IDE.
 *
 *  @param fileName   The name of the file where the failing code exists.
 *  @param lineNumber The line number of the failing code.
 *
 *  @return An EarlGreyImpl instance, with details of the code invoking EarlGrey.
 */
+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber;

/**
 *  @remark init is not an available initializer. Use the <b>EarlGrey</b> macro to start an
 *  interaction.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Creates a pending interaction with a single UI element on the screen.
 *
 *  In this step, a matcher is supplied to EarlGrey which is later used to sift through the elements
 *  in the UI Hierarchy. This method only denotes that you have an intent to perform an action and
 *  packages a GREYElementInteraction object to do so.
 *  The interaction is *actually* started when it's performed with a @c GREYAction or
 *  @c GREYAssertion.
 *
 *  An interaction will fail when multiple elements are matched. In that case, you will have to
 *  refine the @c elementMatcher to match a single element.
 *
 *  By default, EarlGrey looks at all the windows from front to back and
 *  searches for the UI element. To focus on a specific window or container, use
 *  GREYElementInteraction::inRoot: method.
 *
 *  For example, this code will match a UI element with accessibility identifier "foo"
 *  inside a custom UIWindow of type MyCustomWindow:
 *      @code
 *      [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
 *          inRoot:grey_kindOfClass([MyCustomWindow class])]
 *      @endcode
 *
 *  @param elementMatcher The matcher specifying the UI element that will be targeted by the
 *                        interaction.
 *
 *  @return A GREYElementInteraction instance, initialized with an appropriate matcher.
 */
- (id<GREYInteraction>)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher;

/**
 *  Convenience wrapper to invoke GREYFailureHandler::handleException:details: on the failure
 *  handler for the current thread.
 *
 *  @param exception The exception to be handled.
 *  @param details   Any extra details about the failure.
 */
- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details;

/**
 *  Rotate the device to a given @c deviceOrientation. All device orientations except for
 *  @c UIDeviceOrientationUnknown are supported. If a non-nil @c error is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param      deviceOrientation The desired orientation of the device.
 *  @param[out] error             Error that will be populated on failure. If @c nil, the a test
 *                                failure will be reported if the rotation attempt fails.
 *
 *  @throws GREYFrameworkException if the action fails and @c error is @c nil.
 *  @return @c YES if the rotation was successful, @c NO otherwise. If @c error is @c nil and
 *          the operation fails, it will throw an exception.
 */
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error;

/**
 *  Dismisses the keyboard programmatically by calling resignFirstResponder on application under
 *  test. Populates the provided error if any issue is raised.
 *
 *  This behavior can also be triggered by hitting the return key on the keyboard however we do not
 *  do that because it can have side-effects e.g. such as inserting a new line for the Notes.app.
 *  If the return key is intended to dismiss the keyboard then we recommend using the following
 *  EarlGrey statement instead:
 *
 *   @code
 *   [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")]
 *       performAction:grey_tap()];
 *   @endcode
 *
 *  @param[out] error Error that will be populated on failure.
 *
 *  @throws GREYFrameworkException if there is an issue dismissing the keyboard.
 *
 *  @return @c YES if the dismissing of the keyboard was successful, @c NO otherwise.
 */
- (BOOL)dismissKeyboardWithError:(NSError **)error;

/**
 *  Open the deeplink url from Safari and simulate the user action to accept opening the app.
 *  As a result any foregrounded application will be implicitly backgrounded. On failure, Safari
 *  application will remain in the foreground.
 *
 *  This method only works with Xcode 9 or above.
 *
 *  Due to Apple testing framework having an implicit 5 seconds timeout for app launch during
 *  test case, the test case using this method could potentially fail high-loaded machines.
 *  The workaround is to warm up the Safari app in app test @c setUp().
 *
 *  For example:
 *  @code
 *  XCUIApplication *safariApp =
 *      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
 *  if ([safariApp state] == XCUIApplicationStateNotRunning ||
 *    [safariApp state] == XCUIApplicationStateUnknown) {
 *    [safariApp activate];
 *  }
 *  @endcode
 *
 *  The code above should be put in your test's @c setUp() method.
 *
 *  @param URL The deeplink @c URL string that is going to be opened.
 *  @param application The XCUIApplication to use to trigger the deeplink.
 *  @param[out] error  Error that will be populated on failure. If @c nil, a test failure will
 *                     be reported instead.
 *
 *  @return @c YES if the opening the deeplink was successful, @c NO otherwise.
 */
- (BOOL)openDeeplinkURL:(NSString *)URL
          inApplication:(XCUIApplication *)application
                  error:(NSError **)error;

/**
 *  Shakes the device. If a non-nil @c error is provided, it will
 *  be populated with the failure reason if the orientation change fails, otherwise a test failure
 *  will be registered.
 *
 *  @param[out] error Error that will be populated on failure. If @c nil, the a test
 *                    failure will be reported if the shake attempt fails.
 *
 *  @throws GREYFrameworkException if the action fails and @c error is @c nil.
 *  @return @c YES if the shake was successful, @c NO otherwise. If @c error is @c nil and
 *          the operation fails, it will throw an exception.
 */
- (BOOL)shakeDeviceWithError:(NSError **)error;

/**
 *  Returns a @c BOOL that tells if the Keyboard is shown. This is not synchronous. Please ensure
 *  that any changes
 *
 *  @param[out] error Error that will be populated if the app does not idle in time.
 */
- (BOOL)isKeyboardShownWithError:(NSError **)error;

/**
 *  Fetches a remote class object from the app process. The caller of this method should pass
 *  the local class object in its process as @c theClass. EarlGrey will map @c theClass to the
 *  appropriate class object in the app process and return that.
 *
 *  @param theClass The class object to fetch from the app process.
 *
 *  @return A class object, which is the same type as @c theClass in the app process. Invocations
 *          made to the returned Class object will be executed in app process.
 */
- (Class)remoteClassInApp:(Class)theClass;

@end

NS_ASSUME_NONNULL_END
