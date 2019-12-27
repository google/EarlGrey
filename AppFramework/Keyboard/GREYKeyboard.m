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
#import "GREYRunLoopSpinner.h"
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
 *  A retry time interval in which we re-tap the shift key to ensure the alphabetic keyplane
 *  changed.
 */
static const NSTimeInterval kMaxShiftKeyToggleDuration = 3.0;

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

  __block BOOL success = YES;
  for (NSUInteger i = 0; ((i < string.length) && success); i++) {
    NSString *characterAsString = [NSString stringWithFormat:@"%C", [string characterAtIndex:i]];
    NSLog(@"Attempting to type key %@.", characterAsString);

    id key = [GREYKeyboard waitAndFindKeyForCharacter:characterAsString
                                              timeout:kRegularKeyplaneUpdateDuration];
    // If key is not on the screen, try looking for it on another keyplane.
    if (!key) {
      unichar currentCharacter = [characterAsString characterAtIndex:0];
      if ([gAlphabeticKeyplaneCharacters characterIsMember:currentCharacter]) {
        GREYLogVerbose(@"Detected an alphabetic key.");
        // Switch to alphabetic keyplane if we are on numbers/symbols keyplane.
        NSString *moreSymbolsKeyAxIdentifier = @"more";
        if (![GREYKeyboard isAlphabeticKeyplaneShown]) {
          id moreLettersKey =
              [GREYKeyboard waitAndFindKeyForCharacter:moreSymbolsKeyAxIdentifier
                                               timeout:kRegularKeyplaneUpdateDuration];
          if (!moreLettersKey) {
            return [GREYKeyboard setErrorForkeyNotFoundWithCharacter:moreSymbolsKeyAxIdentifier
                                                     forTypingString:string
                                                               error:errorOrNil];
          }
          [GREYKeyboard tapKey:moreLettersKey error:errorOrNil];
          key = [GREYKeyboard waitAndFindKeyForCharacter:characterAsString
                                                 timeout:kRegularKeyplaneUpdateDuration];
        }
        // If key is not on the current keyplane, use shift to switch to the other one.
        if (!key) {
          key = [GREYKeyboard toggleShiftAndFindKeyWithCharacter:characterAsString
                                                           error:errorOrNil];
        }
      } else {
        GREYLogVerbose(@"Detected a non-alphabetic key.");
        // Switch to numbers/symbols keyplane if we are on alphabetic keyplane.
        if ([GREYKeyboard isAlphabeticKeyplaneShown]) {
          NSString *moreNumberKeyAxIdentifier = @"more";
          id moreNumbersKey =
              [GREYKeyboard waitAndFindKeyForCharacter:moreNumberKeyAxIdentifier
                                               timeout:kRegularKeyplaneUpdateDuration];
          if (!moreNumbersKey) {
            return [GREYKeyboard setErrorForkeyNotFoundWithCharacter:moreNumberKeyAxIdentifier
                                                     forTypingString:string
                                                               error:errorOrNil];
          }
          [GREYKeyboard tapKey:moreNumbersKey error:errorOrNil];
          key = [GREYKeyboard waitAndFindKeyForCharacter:characterAsString
                                                 timeout:kRegularKeyplaneUpdateDuration];
        }
        // If key is not on the current keyplane, use shift to switch to the other one.
        if (!key) {
          if (![GREYKeyboard toggleShiftKeyWithError:errorOrNil]) {
            success = NO;
            break;
          }
          key = [GREYKeyboard waitAndFindKeyForCharacter:characterAsString
                                                 timeout:kRegularKeyplaneUpdateDuration];
        }
        // If key is not on either number or symbols keyplane, it could be on alphabetic keyplane.
        // This is the case for @ _ - on UIKeyboardTypeEmailAddress on iPad.
        NSString *moreNumbersKeyAxIdentifier = @"more";
        if (!key) {
          id moreLettersKey =
              [GREYKeyboard waitAndFindKeyForCharacter:moreNumbersKeyAxIdentifier
                                               timeout:kRegularKeyplaneUpdateDuration];
          if (!moreLettersKey) {
            return [GREYKeyboard setErrorForkeyNotFoundWithCharacter:moreNumbersKeyAxIdentifier
                                                     forTypingString:string
                                                               error:errorOrNil];
          }
          [GREYKeyboard tapKey:moreLettersKey error:errorOrNil];
          key = [GREYKeyboard waitAndFindKeyForCharacter:characterAsString
                                                 timeout:kRegularKeyplaneUpdateDuration];
        }
      }
      // If key is still not shown on screen, show error message.
      if (!key) {
        return [GREYKeyboard setErrorForkeyNotFoundWithCharacter:characterAsString
                                                 forTypingString:string
                                                           error:errorOrNil];
      }
    }
    // A period key for an email UITextField on iOS9 and above types the email domain (.com, .org)
    // by default. That is not the desired behavior so check below disables it.
    __block BOOL keyboardTypeWasChangedFromEmailType = NO;
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

    // Keyboard was found; this action should always succeed.
    [GREYKeyboard tapKey:key error:errorOrNil];
    // When space, delete or uppercase letter is typed, the keyboard will automatically change to
    // lower alphabet keyplane. In many cases, it takes some time for the keyboard to update its
    // keyplane to lower alphabet keyplane. So you would have to extend the period of time for
    // waiting for the letter 'q'. Otherwise, a wrong key will be tapped as EarlGrey would think the
    // key is already updated on screen.
    // On iPad, the layout changes faster than accessibility, so we need to wait for accessibility
    // change.
    unichar character = [characterAsString characterAtIndex:0];
    if ([characterAsString isEqualToString:kSpaceKeyIdentifier] ||
        [characterAsString isEqualToString:kDeleteKeyIdentifier] ||
        [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]) {
      [GREYKeyboard waitAndFindKeyForCharacter:@"q" timeout:kAutomaticKeyplaneUpdateDuration];
    }

    if (keyboardTypeWasChangedFromEmailType) {
      // Set the keyboard type back to the Email Type.
      [firstResponder setKeyboardType:UIKeyboardTypeEmailAddress];
    }
  }

  return success;
}

+ (BOOL)waitForKeyboardToAppear {
  if (atomic_load(&gIsKeyboardShown)) {
    return YES;
  }
  return [GREYKeyboard waitUntilTimeout:kKeyboardWillAppearOrDisappearTimeout
                        forConditionMet:^BOOL {
                          return (!atomic_load(&gIsKeyboardShown));
                        }];
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
+ (BOOL)waitUntilTimeout:(NSTimeInterval)timeInterval forConditionMet:(ConditionBlock)condition {
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
 *  A utility method to continuously toggle the shift key on an alphabet keyplane until
 *  the correct character case is found.
 *
 *  @param      character  The character which could be an accessibility label, identifier or text
 *                         of the key for which the case is being changed.
 *  @param[out] errorOrNil Error populated on failure.
 *
 *  @return The case toggled key for the @c character, or @c nil if it isn't found.
 */
+ (id)toggleShiftAndFindKeyWithCharacter:(NSString *)character
                                   error:(__strong NSError **)errorOrNil {
  __block id key = nil;
  BOOL (^conditionBlock)(void) = ^BOOL {
    NSError *error;
    [GREYKeyboard toggleShiftKeyWithError:&error];
    if (!error) {
      key = [GREYKeyboard waitAndFindKeyForCharacter:character
                                             timeout:kRegularKeyplaneUpdateDuration];
    }
    return key == nil;
  };

  BOOL result = [GREYKeyboard waitUntilTimeout:kMaxShiftKeyToggleDuration
                               forConditionMet:conditionBlock];

  if (!result) {
    I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain, kGREYInteractionTimeoutErrorCode,
                        @"GREYKeyboard : Shift Key toggling timed out "
                        @"since key with correct case wasn't found");
  }
  return key;
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
+ (BOOL)toggleShiftKeyWithError:(__strong NSError **)errorOrNil {
  GREYLogVerbose(@"Tapping on Shift key.");
  UIKeyboardImpl *keyboard = [GREYKeyboard keyboardObject];
  // Clear time Shift key was pressed last to make sure the keyboard will not ignore this event.
  // If we do not reset this value, we would need to wait at least 0.35 seconds after toggling
  // Shift before we could reliably toggle it again. This is likely related to the double-tap
  // gesture used for shift-lock (also called caps-lock).
  grey_dispatch_sync_on_main_thread(^{
    [[keyboard _layout] setValue:[NSNumber numberWithDouble:0.0] forKey:@"_shiftLockFirstTapTime"];
  });

  for (NSString *shiftKeyCharacter in self.shiftKeyIdentifyingCharacters) {
    id key = [GREYKeyboard waitAndFindKeyForCharacter:shiftKeyCharacter
                                              timeout:kRegularKeyplaneUpdateDuration];
    if (key) {
      // Shift key was found; this action should always succeed.
      [GREYKeyboard tapKey:key error:errorOrNil];
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
+ (id)waitAndFindKeyForCharacter:(NSString *)character timeout:(CFTimeInterval)timeout {
  GREYFatalAssert(character);

  BOOL ignoreCase = NO;
  // If the key is a modifier key then we need to do a case-insensitive comparison and change the
  // character to identify the key to the corresponding modifier key character.
  __block NSString *modifierKeyIdentifier = [gModifierKeyIdentifierMapping objectForKey:character];
  if (modifierKeyIdentifier) {
    // Check for the return key since we can have a different character value depending upon the
    // keyboard.
    UIKeyboardImpl *currentKeyboard = [GREYKeyboard keyboardObject];
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
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
  runLoopSpinner.timeout = timeout;
  runLoopSpinner.maxSleepInterval = DBL_MAX;
  // TODO(b/146386258): Use grey_dispatch_sync instead of runloop spinner.
  [runLoopSpinner spinWithStopConditionBlock:^BOOL {
    result = [self keyForCharacterValue:character inKeyboardLayoutWithCaseSensitivity:ignoreCase];
    return result != nil;
  }];
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
+ (id)keyForCharacterValue:(NSString *)character
    inKeyboardLayoutWithCaseSensitivity:(BOOL)ignoreCase {
  UIKeyboardImpl *keyboard = [GREYKeyboard keyboardObject];
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
+ (BOOL)isAlphabeticKeyplaneShown {
  // Chose q/Q as the key to look for to determine if alphabetic keyplane is shown because q/Q
  // comes first when iterating keys in UIKeyboardImpl.
  return [GREYKeyboard waitAndFindKeyForCharacter:@"q"
                                          timeout:kRegularKeyplaneUpdateDuration] != nil ||
         [GREYKeyboard waitAndFindKeyForCharacter:@"Q"
                                          timeout:kRegularKeyplaneUpdateDuration] != nil;
}

/**
 *  Provides the active keyboard instance.
 *
 *  @return The active UIKeyboardImpl instance.
 */
+ (UIKeyboardImpl *)keyboardObject {
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
+ (void)tapKey:(id)key error:(__strong NSError **)errorOrNil {
  GREYFatalAssert(key);

  [gTapKeyAction perform:key error:errorOrNil];
  grey_dispatch_sync_on_main_thread(^{
    NSLog(@"Tapped on key: %@.", [key accessibilityLabel]);
    [[[GREYKeyboard keyboardObject] taskQueue] waitUntilAllTasksAreFinished];
  });
}

/**
 *  Populates or prints an error whenever a key with a specified @c character isn't found during
 *  typing a string.
 *
 *  @param character       A character denoting the accessibility label, identifier or text of the
 *                         key
 *  @param string          The string being typed when the key was not found
 *  @param[out] errorOrNil The error to be populated. If this is @c nil, then an error message is
 *                         logged.
 *
 *  @return NO every time since entering the method means an error has happened.
 */
+ (BOOL)setErrorForkeyNotFoundWithCharacter:(NSString *)character
                            forTypingString:(NSString *)string
                                      error:(__strong NSError **)errorOrNil {
  NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                                                     @"because key '%@' could not be found "
                                                     @"on the keyboard.",
                                                     string, [character description]];
  I_GREYPopulateError(errorOrNil, kGREYInteractionErrorDomain,
                      kGREYInteractionElementNotFoundErrorCode, description);
  return NO;
}

@end
