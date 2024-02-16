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

#import "GREYAction.h"
#import "GREYActionsShorthand.h"
#import "GREYInteraction.h"
#import "GREYHostBackgroundDistantObject+GREYApp.h"
#import "GREYMatchersShorthand.h"
#import "GREYAssertionBlock.h"
#import "GREYAssertionDefinesPrivate.h"
#import "GREYConfiguration.h"
#import "GREYHostApplicationDistantObject.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYErrorConstants.h"
#import "GREYFailureHandler.h"
#import "GREYFrameworkException.h"
#import "GREYConstants.h"
#import "GREYDefines.h"  
#import "GREYLogger.h"   
#import "GREYElementMatcherBlock.h"
#import "GREYMatcher.h"
#import "XCTestCase+GREYSystemAlertHandler.h"
#import "GREYAssertionDefines.h"
#import "GREYCondition.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Key for setting a new or retrieving the existing failure handler for EarlGrey. Each failure
 * handler is tied to the main thread's `threadDictionary`. When an EarlGrey call fails, it calls
 * into the currently set failure handler to handle the exception.
 *
 * To set a new failure handler:
 *     @code
 *     [NSThread mainThread].threadDictionary[GREYFailureHandlerKey] = newFailureHandler;
 *     @endcode
 *
 * To get the failure handler:
 *     @code
 *     id<GREYFailureHandler> currentHandler =
 *          [NSThread mainThread].threadDictionary[GREYFailureHandlerKey];
 *     @endcode
 *
 * @note If a handler is not set, one will be created and assigned by EarlGrey.
 *
 * @note EarlGrey internal failures sending to this failure handler expect to interrupt the test by
 *       throwing an exception. When overridding the failure handler without throwing an exception,
 *       users should keep in mind that EarlGrey doesn't recover the app-under-test to the state
 *       before an API is called. If you want to report a failure without interruptting the test,
 *       [XCTTestCase -recordIssue:] is the better option.
 */
GREY_EXTERN NSString *const GREYFailureHandlerKey;

/**
 * Convenience replacement for every EarlGrey method call with
 * EarlGreyImpl::invokedFromFile:lineNumber: so it can get the invocation file and line to report
 * to XCTest on failure.
 */
#define EarlGrey                                                                            \
  [EarlGreyImpl invokedFromFile:[NSString stringWithUTF8String:__FILE__] ?: @"UNKNOWN FILE" \
                     lineNumber:__LINE__]

/** Crash handler block type definiton used for handling app-side crashes. */
typedef void (^GREYHostApplicationCrashHandler)(void);

/**
 * Entry point to the EarlGrey framework.
 * Use methods of this class to initiate interaction with any UI element on the screen.
 */
@interface EarlGreyImpl : NSObject

/**
 * Provides the file name and line number of the code that is calling into EarlGrey.
 * In case of a failure, the information is used to tell XCTest the exact line which caused the
 * failure so it can be highlighted in the IDE.
 *
 * @param fileName   The name of the file where the failing code exists.
 * @param lineNumber The line number of the failing code.
 *
 * @return An EarlGreyImpl instance, with details of the code invoking EarlGrey.
 */
+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber;

/**
 * @remark init is not an available initializer. Use the <b>EarlGrey</b> macro to start an
 * interaction.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a pending interaction with a single UI element on the screen.
 *
 * In this step, a matcher is supplied to EarlGrey which is later used to sift through the elements
 * in the UI Hierarchy. This method only denotes that you have an intent to perform an action and
 * packages a GREYElementInteraction object to do so.
 * The interaction is *actually* started when it's performed with a @c GREYAction or
 * @c GREYAssertion.
 *
 * An interaction will fail when multiple elements are matched. In that case, you will have to
 * refine the @c elementMatcher to match a single element.
 *
 * By default, EarlGrey looks at all the windows from front to back and
 * searches for the UI element. To focus on a specific window or container, use
 * GREYElementInteraction::inRoot: method.
 *
 * For example, this code will match a UI element with accessibility identifier "foo"
 * inside a custom UIWindow of type MyCustomWindow:
 *     @code
 *     [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
 *         inRoot:grey_kindOfClass([MyCustomWindow class])]
 *     @endcode
 *
 * @param elementMatcher The matcher specifying the UI element that will be targeted by the
 *                       interaction.
 *
 * @return A GREYElementInteraction instance, initialized with an appropriate matcher.
 */
- (id<GREYInteraction>)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher
    NS_WARN_UNUSED_RESULT;

/**
 * Dismisses the keyboard programmatically by calling resignFirstResponder on application under
 * test. Populates the provided error if any issue is raised.
 *
 * This behavior can also be triggered by hitting the return key on the keyboard however we do not
 * do that because it can have side-effects e.g. such as inserting a new line for the Notes.app.
 * If the return key is intended to dismiss the keyboard then we recommend using the following
 * EarlGrey statement instead:
 *     @code
 *     [[EarlGrey selectElementWithMatcher:GREYAccessibilityLabel(@"return")]
 *         performAction:grey_tap()];
 *     @endcode
 *
 * @param[out] error Error that will be populated on failure.
 *
 * @throws GREYFrameworkException if there is an issue dismissing the keyboard.
 *
 * @return @c YES if the dismissing of the keyboard was successful, @c NO otherwise.
 */
- (BOOL)dismissKeyboardWithError:(NSError **)error;

#if defined(__IPHONE_11_0)
/**
 * Open a deeplink URL from Safari and simulate the user action to accept opening the app.
 * As a result, any foregrounded application will be implicitly backgrounded. On failure, Safari
 * application will remain in the foreground. Use XCUITest APIs to dismiss it.
 *
 * Due to Apple's testing framework having an implicit 5 seconds timeout for app launches, the test
 * case may fail if it takes longer than that to launch Safari. The workaround is to warm up the
 * Safari app in test's @c -setUp method using the snippet below:
 *
 *     @code
 *     XCUIApplication *safariApp =
 *         [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
 *     if ([safariApp state] == XCUIApplicationStateNotRunning ||
 *       [safariApp state] == XCUIApplicationStateUnknown) {
 *       [safariApp activate];
 *     }
 *     @endcode
 *
 * @param URL         The deeplink @c URL string that is going to be opened.
 * @param application The XCUIApplication to use to trigger the deep link.
 * @param[out] error  Error that will be populated on failure. If @c nil, a test failure will be
 *                    reported instead.
 *
 * @return @c YES if the opening the deeplink was successful, @c NO otherwise.
 *
 */
- (BOOL)openDeepLinkURL:(NSString *)URL
        withApplication:(XCUIApplication *)application
                  error:(NSError **)error;
#endif  // defined(__IPHONE_11_0)

/**
 * Shakes the device. If a non-nil @c error is provided, it will
 * be populated with the failure reason if the orientation change fails, otherwise a test failure
 * will be registered.
 *
 * @param[out] error Error that will be populated on failure. If @c nil, the a test failure will be
 *                   reported if the shake attempt fails.
 *
 * @throws GREYFrameworkException if the action fails and @c error is @c nil.
 *
 * @return @c YES if the shake was successful, @c NO otherwise. If @c error is @c nil and
 *         the operation fails, it will throw an exception.
 */
- (BOOL)shakeDeviceWithError:(NSError **)error;

/**
 * Returns a @c BOOL that tells if the Keyboard is shown. This is not synchronous and should be
 * wrapped in a GREYAssert...() call.
 *
 * @param[out] error Error that will be populated if the app does not idle in time.
 */
- (BOOL)isKeyboardShownWithError:(NSError **)error;

/**
 * Sets the handler block which will be called when EarlGrey detects that the app-under-test has
 * crashed. Before each test case's -setUp and -tearDown, EarlGrey checks if the app-under-test
 * has crashed. If it has, EarlGrey calls this block. Tests can set a handler to restart the
 * app-under-test and configure its state as necessary.
 *
 * @note This method must be called on main thread.
 * @note The @c handler will be invoked if and only if your tests don't override the default
 *       implementation of EDOClientService::errorHandler.
 *
 * @param handler The handler block that will be invoked before XCTestCase::setUp or
 *                XCTestCase::tearDown (depending on which happens next) if the app-under-test
 *                crashes.
 */
- (void)setHostApplicationCrashHandler:(nullable GREYHostApplicationCrashHandler)handler;

/**
 * Convenience wrapper to invoke GREYFailureHandler::handleException:details: on the failure
 * handler for the current thread.
 *
 * @param exception The exception to be handled.
 * @param details   Any extra details about the failure.
 */
- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details;

/**
 * Sets the dispatch policy of all remote calls from app-under-test to the test process. The
 * default value is @c GREYRemoteExecutionDispatchPolicyMain.
 *
 * By default, the remote call to this class and its descendant objects, i.e. the objects being
 * sent to app-under-test from test's main queue, is executed on test's main queue, and is blocked
 * by the running testcase until its main runloop is spun.
 *
 * By setting it to @c GREYRemoteExecutionDispatchPolicyBackground, this configuration will make
 * such kind of remote calls execute on a different thread, without the need to spin the main
 * runloop.
 *
 * @note It is an error to change the remote execution dispatch policy after the remote service
 *       connection is established, which happens when the app-under-test is launched. Doing so
 *       would result in an exception being thrown.
 *
 * @param dispatchPolicy The new dispatch policy to apply.
 */
- (void)setRemoteExecutionDispatchPolicy:(GREYRemoteExecutionDispatchPolicy)dispatchPolicy;

/**
 * Sets a global root matcher that will be utilized for all subsequent EarlGrey calls until
 * it is reset to null.
 *
 * @note Use only in the case of having Multiple UIWindowScene's where elements might have their
 *       accessibility duplicated across different different windows. This can be used to clamp to
 *       one UIWindow on the screen at a time. Setting to a different, more constrained matcher can
 *       lead to issues when resetting the tests.
 *
 * @param rootWindowMatcher A GREYMatcher which can select the particular window to be used in any
 *                          subsequent EarlGrey calls. Can be reset by passing nil.
 */
- (void)setRootMatcherForSubsequentInteractions:(nullable id<GREYMatcher>)rootWindowMatcher;

#pragma mark - iOS Only API's

#if TARGET_OS_IOS
/**
 * Rotate the device to a given @c deviceOrientation. All device orientations except for
 * @c UIDeviceOrientationUnknown are supported. If a non-nil @c error is provided, it will
 * be populated with the failure reason if the orientation change fails, otherwise a test failure
 * will be registered.
 *
 * @param      deviceOrientation The desired orientation of the device.
 * @param[out] error             Error that will be populated on failure. If @c nil, the a test
 *                               failure will be reported if the rotation attempt fails.
 *
 * @throws GREYFrameworkException if the action fails and @c error is @c nil.
 *
 * @return @c YES if the rotation was successful, @c NO otherwise. If @c error is @c nil and
 *         the operation fails, it will throw an exception.
 */
- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation error:(NSError **)error;

#pragma mark - System Alert Handling

/** Standalone API for XCTestCase::grey_systemAlertTextWithError:. */
- (NSString *)SystemAlertTextWithError:(NSError **)error;

/** Standalone API for XCTestCase::grey_systemAlertType:. */
- (GREYSystemAlertType)SystemAlertType;

/** Standalone API for XCTestCase::grey_acceptSystemDialogWithError:. */
- (BOOL)AcceptSystemDialogWithError:(NSError **)error NS_SWIFT_NOTHROW;

/** Standalone API for XCTestCase::grey_denySystemDialogWithError:. */
- (BOOL)DenySystemDialogWithError:(NSError **)error NS_SWIFT_NOTHROW;

/** Standalone API for XCTestCase::grey_tapSystemDialogButtonWithText:error:. */
- (BOOL)TapSystemDialogButtonWithText:(NSString *)text error:(NSError **)error NS_SWIFT_NOTHROW;

/** Standalone API for XCTestCase::grey_typeSystemAlertText:forPlaceholderText:error:. */
- (BOOL)TypeSystemAlertText:(nullable NSString *)textToType
         forPlaceholderText:(nullable NSString *)placeholderText
                      error:(NSError **)error NS_SWIFT_NOTHROW;

/** Standalone API for XCTestCase::grey_waitForAlertVisibility:withTimeout:. */
- (BOOL)WaitForAlertVisibility:(BOOL)visible withTimeout:(CFTimeInterval)seconds;

#pragma mark - Activity Sheet Handling

/**
 * @return A BOOL specifying if an activity sheet is present on the screen.
 *
 * @param[out] error An NSError populated with any steps that show more information about a
 *                   negative result.
 */
- (BOOL)activitySheetPresentWithError:(NSError **)error API_AVAILABLE(ios(17));

/**
 * @return A BOOL specifying if an activity sheet is absent on the screen.
 *
 * @param[out] error An NSError populated with any steps that show more information about a
 *                   negative result.
 */
- (BOOL)activitySheetAbsentWithError:(NSError **)error API_AVAILABLE(ios(17));

/**
 * @return A BOOL specifying if an activity sheet is present on the screen with the given @c URL.
 *
 * @param      URL   An NSString for the URL present on the navigation bar of the activity sheet.
 * @param[out] error An NSError populated with any steps that show more information about a
 *                   negative result.
 */
- (BOOL)activitySheetPresentWithURL:(NSString *)URL error:(NSError **)error API_AVAILABLE(ios(17));

/**
 * @return A BOOL specifying if a button within an activity sheet is present.
 *
 * @param      identifier The identifier to specify the button / cell / view in the activity sheet.
 * @param[out] error      An NSError populated with any steps that show more information about a
 *                        negative result.
 */
- (BOOL)buttonPresentInActivitySheetWithId:(NSString *)identifier
                                     error:(NSError **)error API_AVAILABLE(ios(17));

/**
 * @return A BOOL specifying if a button within an activity sheet was tapped.
 *
 * @param      identifier The identifier to specify the button / cell / view in the activity sheet.
 * @param[out] error      An NSError populated with any steps that show more information about a
 *                        negative result.
 */
- (BOOL)tapButtonInActivitySheetWithId:(NSString *)identifier
                                 error:(NSError **)error API_AVAILABLE(ios(17));

/**
 * @return A BOOL specifying if an activity sheet was closed by tapping on the sheet's close button.
 *
 * @param[out] error      An NSError populated with any steps that show more information about a
 *                        negative result.
 */
- (BOOL)closeActivitySheetWithError:(NSError **)error API_AVAILABLE(ios(17));

#endif  // TARGET_OS_IOS

@end

NS_ASSUME_NONNULL_END
