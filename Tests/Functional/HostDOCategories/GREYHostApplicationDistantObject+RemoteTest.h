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

#import <UIKit/UIKit.h>

#import "EarlGreyApp.h"
#import "GREYHostApplicationDistantObject.h"

/** GREYHostApplicationDistantObject extension for the remote test. */
@interface GREYHostApplicationDistantObject (RemoteTest)

/**
 *  Create a string by appending a string "make".
 *
 *  @param  str The string to append.
 *  @return The new string appending "make".
 */
- (NSString *)makeAString:(NSString *)str;

/**
 *  Call back to the test process to ask for its saved host port number.
 *
 *  @return The port number for the test process.
 */
- (uint16_t)testHostPortNumber;

/**
 *  @return If the layers for all the app's windows have their speed greater than one.
 */
- (BOOL)allWindowsLayerSpeedIsGreaterThanOne;

/**
 *  @return If the layers for all the app's windows have their speed equal to one.
 */
- (BOOL)allWindowsLayerSpeedIsEqualToOne;

/**
 *  @return A GREYMatcher that returns the first matched element.
 */
- (id<GREYMatcher>)matcherForFirstElement;

/**
 *  @return A GREYAction that taps on a matched element if it has an accessibility ID.
 */
- (id<GREYAction>)actionForTapOnAccessibleElement;

/**
 *  @return A GREYAction that returns the text of an element.
 */
- (id<GREYAction>)actionForGettingTextFromMatchedElement;

/**
 *  @return A GREYAssertion that taps on a matched element if it has an alpha value greater than 0.
 */
- (id<GREYAssertion>)assertionThatAlphaIsGreaterThanZero;

/**
 *  Setup an observer for listening to UITextField notifications.
 */
- (void)setUpObserverForReplaceText;

/**
 *  @return @c YES, if a UITextFieldTextDidBeginEditingNotification is fired on the main thread in
 *          the app, @c NO otherwise.
 */
- (BOOL)textFieldTextDidBeginEditingNotificationFiredOnMainThread;

/**
 *  @return The UIInterfaceOrientation of the app under test.
 */
- (UIInterfaceOrientation)appOrientation;

@end
