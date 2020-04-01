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

#import "GREYKeyboard.h"

#include <objc/runtime.h>
#include <stdatomic.h>

#import "GREYTapAction.h"
#import "GREYInteraction.h"
#import "GREYAppError.h"
#import "GREYAppStateTracker.h"
#import "GREYAppStateTrackerObject.h"
#import "GREYSyncAPI.h"
#import "GREYUIThreadExecutor.h"
#import "GREYFatalAsserts.h"
#import "GREYErrorConstants.h"
#import "NSError+GREYCommon.h"
#import "GREYAppleInternals.h"
#import "GREYDefines.h"
#import "GREYLogger.h"
#import "GREYUIWindowProvider.h"

/**
 *  Action for tapping a keyboard key.
 */
static GREYTapAction *gTapKeyAction;

/**
 *  Flag set to @c true when the keyboard is shown, @c false when keyboard is hidden.
 */
static atomic_bool gIsKeyboardShown = false;

/**
 *  A character set for all alphabets present on a keyboard.
 */
static NSMutableCharacterSet *gAlphabeticKeyplaneCharacters;

/**
 *  Character identifiers for text modification keys, like shift, delete etc.
 */
static NSDictionary *gModifierKeyIdentifierMapping;

/**
 * Time to wait for the keyboard to appear or disappear.
 */
static const NSTimeInterval kKeyboardWillAppearOrDisappearTimeout = 10.0;

/**
 * Time to wait for a key in the keyplane.
 */
static const CFTimeInterval kRegularKeyplaneUpdateDuration = 0.1f;

/**
 * Time to wait for the keyboard to change automatically when spacebar, delete, or uppercase letter
 * is pressed. In many cases, it takes a while for the keyboard layout to change after one of those
 * letters are typed. Less than 0.7(s) might cause flakiness.
 */
static const CFTimeInterval kAutomaticKeyplaneUpdateDuration = 0.7f;

/**
 *  Identifier for characters that signify a space key.
 */
static NSString *const kSpaceKeyIdentifier = @" ";

/**
 *  Identifier for characters that signify a delete key.
 */
static NSString *const kDeleteKeyIdentifier = @"\b";

/**
 *  Identifier for characters that signify a return key.
 */
static NSString *const kReturnKeyIdentifier = @"\n";

/**
 *  Accessibility identifier for the key for switching planes between alphabetic keyplane and
 *  numeric/symbolic keyplane.
 */
static NSString *const kMoreKeyIdentifier = @"more";

/**
 *  A block to hold a condition to be waited and checked for.
 *
 *  @return @c YES if condition was satisfied @c NO otherwise.
 */
typedef BOOL (^ConditionBlock)(void);

/** Register notification for keyboard display lifecycle events. */
__attribute__((constructor)) static void RegisterKeyboardLifecycleHooks() {
  NSObject *keyboardObject = [[NSObject alloc] init];
  static void *objectKey = &objectKey;
  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  // Hook for keyboard will show event.
  [defaultCenter addObserverForName:UIKeyboardWillShowNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(
                               kGREYPendingKeyboardTransition, keyboardObject);
                           objc_setAssociatedObject(keyboardObject, objectKey, object,
                                                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         }];
  // Hook for keyboard did show event.
  [defaultCenter addObserverForName:UIKeyboardDidShowNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           GREYAppStateTrackerObject *object =
                               objc_getAssociatedObject(keyboardObject, objectKey);
                           UNTRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, object);
                           // There may be a zero size inputAccessoryView to track keyboard data.
                           // This causes UIKeyboardDidShowNotification event to fire even though no
                           // keyboard is visible. So instead of relying on keyboard show/hide event
                           // to detect the keyboard visibility, it is necessary to double check on
                           // the actual frame to determine the true visibility.
                           NSValue *rectValue = note.userInfo[UIKeyboardFrameEndUserInfoKey];
                           CGRect keyboardFrame = rectValue.CGRectValue;
                           UIApplication *sharedApp = UIApplication.sharedApplication;
                           UIWindow *window = GREYGetApplicationKeyWindow(sharedApp);
                           keyboardFrame = [window convertRect:keyboardFrame fromWindow:nil];
                           CGRect windowFrame = window.frame;
                           CGRect frameIntersection =
                               CGRectIntersection(windowFrame, keyboardFrame);
                           bool keyboardVisible = frameIntersection.size.width > 1 &&
                                                  frameIntersection.size.height > 1;
                           atomic_store(&gIsKeyboardShown, keyboardVisible);
                         }];
  // Hook for keyboard will hide event.
  [defaultCenter addObserverForName:UIKeyboardWillHideNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           atomic_store(&gIsKeyboardShown, false);
                           GREYAppStateTrackerObject *object = TRACK_STATE_FOR_OBJECT(
                               kGREYPendingKeyboardTransition, keyboardObject);
                           objc_setAssociatedObject(keyboardObject, objectKey, object,
                                                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                         }];
  // Hook for keyboard did hide event.
  [defaultCenter addObserverForName:UIKeyboardDidHideNotification
                             object:nil
                              queue:nil
                         usingBlock:^(NSNotification *note) {
                           GREYAppStateTrackerObject *object =
                               objc_getAssociatedObject(keyboardObject, objectKey);
                           UNTRACK_STATE_FOR_OBJECT(kGREYPendingKeyboardTransition, object);
                         }];
}

@implementation GREYKeyboard : NSObject

/**
 *  Possible character identifying strings values for the Shift Key.
 */
+ (NSArray *)shiftKeyIdentifyingCharacters {
  return @[ @"shift", @"Shift", @"SHIFT" ];
}

+ (void)initialize {
  if (self == [GREYKeyboard self]) {
    gTapKeyAction = [[GREYTapAction alloc] initWithType:kGREYTapTypeKBKey];
    NSCharacterSet *lowerCaseSet = [NSCharacterSet lowercaseLetterCharacterSet];
    gAlphabeticKeyplaneCharacters = [NSMutableCharacterSet uppercaseLetterCharacterSet];
    [gAlphabeticKeyplaneCharacters formUnionWithCharacterSet:lowerCaseSet];

    gModifierKeyIdentifierMapping = @{
      kSpaceKeyIdentifier : @"space",
      kDeleteKeyIdentifier : @"delete",
      kReturnKeyIdentifier : @"return"
    };
  }
}

+ (BOOL)typeString:(NSString *)string
    inFirstResponder:(id)firstResponder
               error:(__strong NSError **)errorOrNil {
  if (string.length == 0) {
    I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                        kGREYInteractionActionFailedErrorCode,
                        @"Failed to type because the provided string was empty.");

    return NO;
  } else if (!atomic_load(&gIsKeyboardShown)) {
    NSString *description = [NSString stringWithFormat:@"Failed to type '%@' because keyboard was "
                                                       @"not shown on screen.",
                                                       string];
    I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                        kGREYInteractionActionFailedErrorCode, description);

    return NO;
  }

  for (NSUInteger index = 0; index < string.length; index++) {
    NSString *characterAsString =
        [NSString stringWithFormat:@"%C", [string characterAtIndex:index]];
    NSLog(@"Attempting to type key %@.", characterAsString);

    id key = SearchKeyWithCharacter(characterAsString, errorOrNil);
    if (!key) {
      // Error might already be populated due to a failure in SearchKeyWithCharacter function.
      if (*errorOrNil) {
        return NO;
      }
      return SetErrorForKeyNotFound(characterAsString, string, errorOrNil);
    }

    __block BOOL keyboardTypeWasChangedFromEmailType = NO;
    // A period key for an email UITextField on iOS9 and above types the email domain (.com, .org)
    // by default. That is not the desired behavior so check below disables it.
    if ([characterAsString isEqualToString:@"."]) {
      __block BOOL isEmailField = NO;
      grey_dispatch_sync_on_main_thread(^{
        isEmailField = [firstResponder respondsToSelector:@selector(keyboardType)] &&
                       [firstResponder keyboardType] == UIKeyboardTypeEmailAddress;
        if (isEmailField) {
          [firstResponder setKeyboardType:UIKeyboardTypeDefault];
          keyboardTypeWasChangedFromEmailType = YES;
        }
      });
    }

    TapKey(key, errorOrNil);

    if (keyboardTypeWasChangedFromEmailType) {
      // Set the keyboard type back to the Email Type.
      [firstResponder setKeyboardType:UIKeyboardTypeEmailAddress];
    }

    // When space, delete or uppercase letter is typed, the keyboard will automatically change
    // to lower alphabet keyplane. In many cases, it takes some time for the keyboard to update
    // its keyplane to lower alphabet keyplane. So you would have to extend the period of time
    // for waiting for the letter 'q'. Otherwise, a wrong key will be tapped as EarlGrey would
    // think the key is already updated on screen. On iPad, the layout changes faster than
    // accessibility, so we need to wait for accessibility change.
    unichar character = [characterAsString characterAtIndex:0];
    if ([characterAsString isEqualToString:kSpaceKeyIdentifier] ||
        [characterAsString isEqualToString:kDeleteKeyIdentifier] ||
        [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]) {
      WaitAndFindKeyForCharacter(@"q", kAutomaticKeyplaneUpdateDuration);
    }
  }

  return YES;
}

+ (BOOL)waitForKeyboardToAppear {
  if (atomic_load(&gIsKeyboardShown)) {
    return YES;
  }
  return WaitConditionUntilTimeout(kKeyboardWillAppearOrDisappearTimeout, ^BOOL {
    return (!atomic_load(&gIsKeyboardShown));
  });
}

+ (BOOL)keyboardShownWithError:(NSError **)error {
  __block NSError *synchError = nil;
  __block BOOL keyboardShown = NO;
  GREYUIThreadExecutor *sharedExecutor = [GREYUIThreadExecutor sharedInstance];
  BOOL success = [sharedExecutor executeSyncWithTimeout:10
                                                  block:^{
                                                    keyboardShown = atomic_load(&gIsKeyboardShown);
                                                  }
                                                  error:&synchError];
  if (!success) {
    *error = synchError;
    return NO;
  } else {
    return keyboardShown;
  }
}

+ (BOOL)dismissKeyboardWithoutReturnKeyWithError:(NSError **)error {
  __block GREYError *executionError = nil;
  GREYUIThreadExecutor *sharedExecutor = [GREYUIThreadExecutor sharedInstance];
  [sharedExecutor executeSyncWithTimeout:5
                                   block:^{
                                     // Even though this is checked previously in the caller
                                     // on the test side, check this again as the UI might
                                     // have updated while the eDO call was being made.
                                     if (!atomic_load(&gIsKeyboardShown)) {
                                       executionError = GREYErrorMakeWithHierarchy(
                                           kGREYKeyboardDismissalErrorDomain,
                                           GREYKeyboardDismissalFailedErrorCode,
                                           @"Failed to dismiss keyboard as it was not shown.");
                                     } else {
                                       UIApplication *sharedApp = UIApplication.sharedApplication;
                                       [sharedApp sendAction:@selector(resignFirstResponder)
                                                          to:nil
                                                        from:nil
                                                    forEvent:nil];
                                     }
                                   }
                                   error:&executionError];
  if (executionError) {
    *error = executionError;
    return NO;
  }
  return YES;
}

#pragma mark - Private

/**
 *  Searches for @c characterString key in the system keyboard, retrying upto 3 times until it's
 *  found. It could fail when tapping "more" or "shift" fails for any reason.
 *  TODO(b/152765896): It also fails when keyplane automatically changes back to lower keyplane
 *  sometime after pressing space bar.
 *
 *  @param characterString The character to look for in the keyboard.
 *  @param[out] errorOrNil Error populated on failure.
 *
 *  @return Key corresponding to the requested @c characterString or @c nil if it wasn't found.
 */
static id SearchKeyWithCharacter(NSString *characterString, __strong NSError **errorOrNil) {
  id key;
  int attempts = 0;
  NSError *error;
  while (!key && attempts++ < 3) {
    key = WaitAndFindKeyForCharacter(characterString, kRegularKeyplaneUpdateDuration);
    if (key) {
      break;
    }

    unichar currentCharacter = [characterString characterAtIndex:0];
    BOOL isKeyplaneAlphabetic = IsAlphabeticKeyplaneShown();
    BOOL success = NO;
    if ([gAlphabeticKeyplaneCharacters characterIsMember:currentCharacter]) {
      success = isKeyplaneAlphabetic ? ToggleShiftKeyWithError(&error) : TapOnMoreKeyplane(&error);
    } else if (!isKeyplaneAlphabetic) {
      success = ToggleShiftKeyWithError(&error);
    } else {
      success = TapOnMoreKeyplane(&error);
    }
    if (!success) {
      continue;
    }
    // We should be on the correct keyplane. Either on alphabetic or symbolic/numeric.
    key = WaitAndFindKeyForCharacter(characterString, kRegularKeyplaneUpdateDuration);
    if (!key && ToggleShiftKeyWithError(&error)) {
      key = WaitAndFindKeyForCharacter(characterString, kRegularKeyplaneUpdateDuration);
    }
  }

  if (!key && error) {
    *errorOrNil = error;
  }
  return key;
}

/**
 * Tap on "more" to switch between alphabetic keyplane and numeric/symbolic keyplane.
 *
 * @param[out] errorOrNil Error populated on failure.
 *
 * @return A @c BOOL indicating whether the tap was successful or not.
 */
static BOOL TapOnMoreKeyplane(__strong NSError **errorOrNil) {
  id moreKey = WaitAndFindKeyForCharacter(kMoreKeyIdentifier, kRegularKeyplaneUpdateDuration);
  if (!moreKey) {
    return NO;
  }
  TapKey(moreKey, errorOrNil);
  if (*errorOrNil) {
    return NO;
  }
  return YES;
}

/**
 *  A utility method to wait for a particular condition to be satisfied. If a condition is not
 *  met then the current thread's run loop is run and the condition is checked again, an activity
 *  that is repeated until the timeout provided expires.
 *
 *  @param condition The ConditionBlock to be checked.
 *  @param timeInterval The timeout interval to check for the condition.
 *
 *  @return @c YES if the condition specified in the ConditionBlock was satisfied before the
 *          timeout. @c NO otherwise.
 */
static BOOL WaitConditionUntilTimeout(NSTimeInterval timeInterval, ConditionBlock condition) {
  GREYFatalAssertWithMessage(condition != nil, @"Condition Block must not be nil.");
  GREYFatalAssertWithMessage(timeInterval > 0, @"Time interval has to be greater than zero.");
  CFTimeInterval startTime = CACurrentMediaTime();
  while (condition()) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
    if ((CACurrentMediaTime() - startTime) >= timeInterval) {
      return NO;
    }
  }
  return YES;
}

/**
 *  Private API to toggle shift, because tapping on the key was flaky and required a 0.35 second
 *  wait due to accidental touch detection. The 0.35 seconds is the value within which, if a second
 *  tap occurs, then a double tap is registered.
 *
 *  @param[out] errorOrNil Error populated on failure.
 *
 *  @return YES if the shift toggle succeeded, else NO.
 */
static BOOL ToggleShiftKeyWithError(__strong NSError **errorOrNil) {
  GREYLogVerbose(@"Tapping on Shift key.");
  UIKeyboardImpl *keyboard = GetKeyboardObject();
  // Clear time Shift key was pressed last to make sure the keyboard will not ignore this event.
  // If we do not reset this value, we would need to wait at least 0.35 seconds after toggling
  // Shift before we could reliably toggle it again. This is likely related to the double-tap
  // gesture used for shift-lock (also called caps-lock).
  grey_dispatch_sync_on_main_thread(^{
    [[keyboard _layout] setValue:[NSNumber numberWithDouble:0.0] forKey:@"_shiftLockFirstTapTime"];
  });

  for (NSString *shiftKeyCharacter in [GREYKeyboard shiftKeyIdentifyingCharacters]) {
    id key = WaitAndFindKeyForCharacter(shiftKeyCharacter, kRegularKeyplaneUpdateDuration);
    if (key) {
      // Shift key was found; this action should always succeed.
      TapKey(key, errorOrNil);
      return YES;
    }
  }
  I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                      kGREYInteractionActionFailedErrorCode,
                      @"GREYKeyboard: No known SHIFT key was found in the hierarchy.");
  return NO;
}

/**
 *  Get the key on the keyboard for a character to be typed.
 *
 *  @param character The character that needs to be typed.
 *  @param timeout   Amount of time to wait for the character until it times out.
 *
 *  @return A UI element that signifies the key to be tapped for typing action.
 */
static id WaitAndFindKeyForCharacter(NSString *character, CFTimeInterval timeout) {
  GREYFatalAssert(character);

  BOOL ignoreCase = NO;
  // If the key is a modifier key then we need to do a case-insensitive comparison and change the
  // character to identify the key to the corresponding modifier key character.
  __block NSString *modifierKeyIdentifier = [gModifierKeyIdentifierMapping objectForKey:character];
  if (modifierKeyIdentifier) {
    // Check for the return key since we can have a different character value depending upon the
    // keyboard.
    UIKeyboardImpl *currentKeyboard = GetKeyboardObject();
    if ([character isEqualToString:kReturnKeyIdentifier]) {
      grey_dispatch_sync_on_main_thread(^{
        modifierKeyIdentifier = [currentKeyboard returnKeyDisplayName];
      });
    }
    character = modifierKeyIdentifier;
    ignoreCase = YES;
  }

  // iOS 9 changes & to ampersand.
  if ([character isEqualToString:@"&"]) {
    character = @"ampersand";
  }

  __block id result = nil;
  GREYFatalAssertNonMainThread();
  grey_dispatch_sync_on_main_thread(^{
    CFTimeInterval startTime = CACurrentMediaTime();
    while (!result && (CACurrentMediaTime() - startTime) < timeout) {
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
      result = GetKeyForCharacterValueInKeyboardLayout(character, ignoreCase);
    }
  });
  return result;
}

/**
 *  Get the key on the keyboard for the given @c character.
 *
 *  @param character  The character to be searched.
 *  @param ignoreCase A Boolean that is @c YES if searching for the key requires ignoring
 *                    the case. This is seen in the case of modifier keys that have
 *                    differing cases across iOS versions.
 *
 *  @return A key that has the given character.
 */
static id GetKeyForCharacterValueInKeyboardLayout(NSString *character, BOOL ignoreCase) {
  UIKeyboardImpl *keyboard = GetKeyboardObject();
  // Type of layout is private class UIKeyboardLayoutStar, which implements UIAccessibilityContainer
  // Protocol and contains accessibility elements for keyboard keys that it shows on the screen.
  id layout = [keyboard _layout];
  GREYFatalAssertWithMessage(layout, @"Layout instance must not be nil");
  if ([layout accessibilityElementCount] != NSNotFound) {
    for (NSInteger i = 0; i < [layout accessibilityElementCount]; ++i) {
      id key = [layout accessibilityElementAtIndex:i];
      NSString *axLabel = [key accessibilityLabel];
      if ((ignoreCase && [axLabel caseInsensitiveCompare:character] == NSOrderedSame) ||
          (!ignoreCase && [axLabel isEqualToString:character])) {
        return key;
      }
      NSString *axID = [key accessibilityIdentifier];
      if (axID && [axID isEqualToString:character]) {
        return key;
      }
    }
  }
  return nil;
}

/**
 *  A flag to check if the alphabetic keyplane is currently visible on the keyboard.
 *
 *  @return @c YES if the alphabetic keyplane is being shown on the keyboard, else @c NO.
 */
static BOOL IsAlphabeticKeyplaneShown() {
  // Chose q/Q as the key to look for to determine if alphabetic keyplane is shown because q/Q
  // comes first when iterating keys in UIKeyboardImpl.
  return WaitAndFindKeyForCharacter(@"q", kRegularKeyplaneUpdateDuration) != nil ||
         WaitAndFindKeyForCharacter(@"Q", kRegularKeyplaneUpdateDuration) != nil;
}

/**
 *  Provides the active keyboard instance.
 *
 *  @return The active UIKeyboardImpl instance.
 */
static UIKeyboardImpl *GetKeyboardObject() {
  UIKeyboardImpl *keyboard = [UIKeyboardImpl activeInstance];
  GREYFatalAssertWithMessage(keyboard, @"Keyboard instance must not be nil");
  return keyboard;
}

/**
 *  Utility method to tap on a key on the keyboard.
 *
 *  @param      key           The key to be tapped.
 *  *param[out] errorOrNil    The error to be populated. If this is @c nil,
 *                            then an error message is logged.
 */
static BOOL TapKey(id key, __strong NSError **errorOrNil) {
  GREYFatalAssert(key);

  BOOL success = [gTapKeyAction perform:key error:errorOrNil];
  if (!success) {
    return NO;
  }
  grey_dispatch_sync_on_main_thread(^{
    NSLog(@"Tapped on key: %@.", [key accessibilityLabel]);
    [[GetKeyboardObject() taskQueue] waitUntilAllTasksAreFinished];
  });
  return YES;
}

/**
 *  Populates or prints an error whenever a key with a specified @c character isn't found during
 *  typing a string.
 *
 *  @param character       A character denoting the accessibility label, identifier or text of the
 *                         key
 *  @param typingString    The string being typed when the key was not found
 *  @param[out] errorOrNil The error to be populated. If this is @c nil, then an error message is
 *                         logged.
 *
 *  @return NO every time since entering the method means an error has happened.
 */
static BOOL SetErrorForKeyNotFound(NSString *character, NSString *typingString,
                                   __strong NSError **errorOrNil) {
  NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                                                     @"because key '%@' could not be found "
                                                     @"on the keyboard.",
                                                     typingString, [character description]];
  I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                      kGREYInteractionElementNotFoundErrorCode, description);
  return NO;
}

@end
