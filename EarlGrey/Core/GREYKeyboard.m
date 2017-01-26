//
// Copyright 2016 Google Inc.
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

#import "Core/GREYKeyboard.h"

#include <objc/runtime.h>

#import "Action/GREYTapAction.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYDefines.h"
#import "Common/GREYExposed.h"
#import "Common/GREYStopwatch.h"
#import "Common/GREYError.h"
#import "Common/GREYLogger.h"
#import "Core/GREYInteraction.h"
#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYCondition.h"
#import "Synchronization/GREYRunLoopSpinner.h"
#import "Synchronization/GREYUIThreadExecutor.h"

/**
 *  Action for tapping a keyboard key.
 */
static GREYTapAction *gTapKeyAction;

/**
 *  An enum for representing different keyplanes that can be visible on the keyboard.
 */
typedef NS_ENUM(NSUInteger, GREYKeyboardKeyplaneType) {
  GREYKeyboardKeyplaneTypeAlphabetSmall, // "e" present
  GREYKeyboardKeyplaneTypeAlphabetCapital, // "E" present
  GREYKeyboardKeyplaneTypeNumeric, // "1" present
  GREYKeyboardKeyplaneTypeMoreNumbers // "^" present
};

/**
 *  Flag set to @c YES when the keyboard is shown, @c NO when keyboard is hidden.
 */
static BOOL gIsKeyboardShown = NO;

/**
 *  Possible accessibility label values for the Shift Key.
 */
static NSArray *gShiftKeyLabels;

/**
 *  Accessibility labels for text modification keys, like shift, delete etc.
 */
static NSDictionary *gModifierKeyIdentifierMapping;

/**
 * Time to wait for the keyboard to appear or disappear.
 */
static const NSTimeInterval kKeyboardWillAppearOrDisappearTimeout = 5.0;

/**
 * Time for a keyplane change to happen.
 */
static const NSTimeInterval kKeyboardKeyplaneWillChange = 5.0;

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

@implementation GREYKeyboard : NSObject

+ (void)load {
  @autoreleasepool {
    gTapKeyAction = [[GREYTapAction alloc] initWithType:kGREYTapTypeKBKey];
    NSObject *keyboardObject = [[NSObject alloc] init];
    // Note: more, numbers label must be after shift and SHIFT labels, because it is also used for
    // the key for switching between keyplanes.
    gShiftKeyLabels =
        @[ @"shift", @"Shift", @"SHIFT", @"more, symbols", @"more, numbers", @"more", @"MORE" ];

    gModifierKeyIdentifierMapping = @{
      kSpaceKeyIdentifier : @"space",
      kDeleteKeyIdentifier : @"delete",
      kReturnKeyIdentifier : @"return"
    };

    // Hooks to keyboard lifecycle notification.
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserverForName:UIKeyboardWillShowNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      NSString *elementID = TRACK_STATE_FOR_ELEMENT(kGREYPendingKeyboardTransition, keyboardObject);
      objc_setAssociatedObject(keyboardObject,
                               @selector(grey_keyboardObject),
                               elementID,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardDidShowNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      NSString *elementID = objc_getAssociatedObject(keyboardObject,
                                                     @selector(grey_keyboardObject));
      UNTRACK_STATE_FOR_ELEMENT_WITH_ID(kGREYPendingKeyboardTransition, elementID);
      gIsKeyboardShown = YES;
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardWillHideNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      gIsKeyboardShown = NO;
      NSString *elementID = TRACK_STATE_FOR_ELEMENT(kGREYPendingKeyboardTransition, keyboardObject);
      objc_setAssociatedObject(keyboardObject,
                               @selector(grey_keyboardObject),
                               elementID,
                               OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }];
    [defaultNotificationCenter addObserverForName:UIKeyboardDidHideNotification
                                           object:nil
                                            queue:nil
                                       usingBlock:^(NSNotification *note) {
      NSString *elementID = objc_getAssociatedObject(keyboardObject,
                                                     @selector(grey_keyboardObject));
      UNTRACK_STATE_FOR_ELEMENT_WITH_ID(kGREYPendingKeyboardTransition, elementID);
    }];
  }
}

+ (BOOL)typeString:(NSString *)string
    inFirstResponder:(id)firstResponder
               error:(__strong NSError **)errorOrNil {
  NSError *typingError;

  if ([string length] < 1) {
    GREYPopulateErrorOrLog(&typingError,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionActionFailedErrorCode,
                           @"Failed to type, because the string provided was empty.");
  } else if (!gIsKeyboardShown) {
    NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                             @"because keyboard was not shown on screen.",
                             string];

    GREYPopulateErrorOrLog(&typingError,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionActionFailedErrorCode,
                           description);
  } else {
    for (NSUInteger i = 0; i < string.length; i++) {
      NSString *characterAsString = [NSString stringWithFormat:@"%C", [string characterAtIndex:i]];
      NSLog(@"Attempting to type key %@.", characterAsString);
      BOOL keyIsAShiftedAlphabet = NO;
      // Find if the key is present on the screen.
      id key = [GREYKeyboard grey_findKeyForCharacter:characterAsString];
      // If the key isn't found, then change the keyplane.
      if (!key) {
        unichar currentCharacter = [characterAsString characterAtIndex:0];
        // Check if the key is alphabetic or not.
        if ([[NSCharacterSet letterCharacterSet] characterIsMember:currentCharacter]) {
          GREYLogVerbose(@"Detected an alphabetic key.");
          if (![GREYKeyboard grey_isAlphabeticKeyplaneShown]) {
            // If you're already on a non-alphabetic keyplane, move to it by hitting the
            // 'more, letters' key.
            key = [GREYKeyboard grey_keyOnTappingModifierKeyWithLabel:@"more, letters"
                                                  forFindingCharacter:characterAsString
                                                             inString:string
                                                            withError:&typingError];
            if (typingError) {
              break;
            }
          }
          // Alphabetic keyplane already visible. If the key is not present here then it needs
          // to be shifted.
          if (!key) {
            GREYLogVerbose(@"Keyplane Change Needed before tapping on alphabet key that should "
                           @"be: %@", key);
            keyIsAShiftedAlphabet = YES;
            key = [GREYKeyboard grey_toggleShiftAndFindKeyWithAccessibilityLabel:characterAsString
                                                                       withError:&typingError];
          }
        } else {
          GREYLogVerbose(@"Detected a non-alphabetic key.");
          // If we're on the alphabetic keyplane here, then we need to move to the non-alphabetic
          // one.
          if ([GREYKeyboard grey_isAlphabeticKeyplaneShown]) {
            key = [GREYKeyboard grey_keyOnTappingModifierKeyWithLabel:@"more, numbers"
                                                  forFindingCharacter:characterAsString
                                                             inString:string
                                                            withError:&typingError];
            if (typingError) {
              break;
            }
          }
          // If key is not on the current keyplane, change the keyplane by hitting the shift button
          // which should be represented by the "more, symbols" label.
          if (!key) {
            GREYLogVerbose(@"Keyplane Change Needed before tapping on key: %@", key);
            key = [GREYKeyboard grey_toggleShiftAndFindKeyWithAccessibilityLabel:characterAsString
                                                                       withError:&typingError];
          }
        }
        // If key is not on either number or symbols keyplane, it could be on alphabetic keyplane.
        // This is the case for @ _ - on UIKeyboardTypeEmailAddress on an iPad.
        if (!key) {
          key = [GREYKeyboard grey_keyOnTappingModifierKeyWithLabel:@"more, letters"
                                                forFindingCharacter:characterAsString
                                                           inString:string
                                                          withError:&typingError];
          if (typingError) {
            break;
          }
        }

        // After perusing the keyboard, if a key is still not found, then raise an error.
        if (!key) {
          [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:characterAsString
                                                          forTypingString:string
                                                                    error:&typingError];
          break;
        }
      }
      // Key is found, tap on the keyboard.
      [GREYKeyboard grey_tapKeyboardKey:key
                     forCharacterString:characterAsString
                           withShifting:keyIsAShiftedAlphabet
                       onFirstResponder:firstResponder];
    }
  }

  // If any error was set, it means that the typing failed. Set any error provided and return.
  if (typingError) {
    if (errorOrNil) {
      *errorOrNil = typingError;
    }
    return NO;
  }
  return YES;
}

+ (BOOL)waitForKeyboardToAppear {
  if (gIsKeyboardShown) {
    return YES;
  }
  GREYCondition *keyboardIsShownCondition =
      [[GREYCondition alloc] initWithName:@"Keyboard will appear." block:^BOOL {
        return gIsKeyboardShown;
      }];
  return [keyboardIsShownCondition waitWithTimeout:kKeyboardWillAppearOrDisappearTimeout];
}

#pragma mark - Private

/**
 *  Tap the key on the keyboard that is to be entered in the typing field while handling any other
 *  tasks to be performed.
 *
 *  @param key                   The keyboard key to be tapped.
 *  @param characterAsString     The character to be entered in the field being typed in.
 *  @param keyIsAShiftedAlphabet Is the character a shifted alphabet that will cause a keyplane
 *                               change on being tapped.
 *  @param firstResponder        The keyboard's current first responder.
 */
+ (void)grey_tapKeyboardKey:(id)key
         forCharacterString:(NSString *)characterAsString
               withShifting:(BOOL)keyIsAShiftedAlphabet
           onFirstResponder:(id)firstResponder {
  // A period key for an email UITextField on iOS9 and above types the email domain (.com, .org)
  // by default. That is not the desired behavior so check below disables it.
  BOOL keyboardTypeWasChangedFromEmailType =
      [GREYKeyboard grey_preventEmailDomainAutocorrectionOnFirstResponder:firstResponder
                                                             forCharacter:characterAsString];
  // Keyboard was found; this action should always succeed.
  [GREYKeyboard grey_tapKey:key withKeyplaneToggling:keyIsAShiftedAlphabet];

  // Drain the main thread for 0.25 seconds in case a delete, space key or a capitalized key is
  // pressed instead of accounting for all the ways these presses can require a Keyplane change.
  unichar character = [characterAsString characterAtIndex:0];
  if ([characterAsString isEqualToString:kDeleteKeyIdentifier] ||
      [characterAsString isEqualToString:kSpaceKeyIdentifier] ||
      [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:character]) {
    [[GREYUIThreadExecutor sharedInstance] drainUntilIdleWithTimeout:0.25];
  }

  if (keyboardTypeWasChangedFromEmailType) {
    // Set the keyboard type back to the Email Type.
    [firstResponder setKeyboardType:UIKeyboardTypeEmailAddress];
  }
}

/**
 *  Tap a keyplane modifier key on the keyboard and wait for the keyplane to change.
 *
 *  @param label           The accessibility label of thekeyboard key to be tapped.
 *  @param character       The character to be entered in the field being typed in.
 *  @param string          The entire string being typed in the typing field.
 *  @param[out] errorOrNil The NSError to be populated on a failure on tapping the modifier key.
 *
 *  @return The keyboard key to be tapped.
 */
+ (id)grey_keyOnTappingModifierKeyWithLabel:(NSString *)label
                        forFindingCharacter:(NSString *)character
                                   inString:(NSString *)string
                                  withError:(__strong NSError **)errorOrNil {
  GREYLogVerbose(@"Keyplane Change Needed before typing: %@", character);
  NSUInteger currentKeyplane = [GREYKeyboard grey_currentKeyplane];
  id modifierKey = [GREYKeyboard grey_findKeyForCharacter:label];
  // Logout an error if the key is not found.
  if (!modifierKey) {
    [GREYKeyboard grey_setErrorForkeyNotFoundWithAccessibilityLabel:label
                                                    forTypingString:string
                                                              error:errorOrNil];
    return nil;
  }
  [GREYKeyboard grey_tapKey:modifierKey withKeyplaneToggling:YES];
  [GREYKeyboard grey_ensureKeyplaneChangedFrom:currentKeyplane];
  return [GREYKeyboard grey_findKeyForCharacter:character];
}

/**
 *  A utility method to continuously toggle the shift key on an alphabet keyplane until
 *  the correct character case is found.
 *
 *  @param      accessibilityLabel The accessibility label of the key for which
 *                                 the case is being changed.
 *  @param[out] errorOrNil         Error populated on failure.
 *
 *  @return The case toggled key for the accessibility label, or @c nil if it isn't found.
 */
+ (id)grey_toggleShiftAndFindKeyWithAccessibilityLabel:(NSString *)accessibilityLabel
                                           withError:(__strong NSError **)errorOrNil {
  id key = nil;
  NSUInteger currentKeyplane = [GREYKeyboard grey_currentKeyplane];
  GREYLogVerbose(@"Tapping on Shift key.");
  UIKeyboardImpl *keyboard = [GREYKeyboard grey_keyboardObject];
  // Clear the time when shift key was pressed last to make sure the keyboard will not ignore this
  // event. If we do not reset this value, we would need to wait at least 0.35 seconds after
  // toggling Shift before we could reliably toggle it again. This is likely related to the
  // double-tap gesture used for shift-lock (also called caps-lock).
  [[keyboard _layout] setValue:[NSNumber numberWithDouble:0.0] forKey:@"_shiftLockFirstTapTime"];

  // Search For the Shift Key the list of possible Shift Key Labels.
  for (NSString *shiftKeyLabel in gShiftKeyLabels) {
    key = [GREYKeyboard grey_findKeyForCharacter:shiftKeyLabel];
    if (key) {
      break;
    }
  }
  if (!key) {
    // Shift Key Not Found.
    GREYPopulateErrorOrLog(errorOrNil,
                           kGREYInteractionErrorDomain,
                           kGREYInteractionActionFailedErrorCode,
                           @"GREYKeyboard: No known SHIFT key was found in the hierarchy.");
  } else {
    // Shift key was found; this action should always succeed.
    [GREYKeyboard grey_tapKey:key withKeyplaneToggling:YES];
    [GREYKeyboard grey_ensureKeyplaneChangedFrom:currentKeyplane];
    key = [GREYKeyboard grey_findKeyForCharacter:accessibilityLabel];
  }

  return key;
}

/**
 *  Get the key on the keyboard for a character to be typed.
 *
 *  @param character The character that needs to be typed.
 *
 *  @return A UI element that signifies the key to be tapped for typing action.
 */
+ (id)grey_findKeyForCharacter:(NSString *)character {
  NSParameterAssert(character);
  BOOL ignoreCase = NO;
  NSString *accessibilityLabel = character;
  // If the key is a modifier key then we need to do a case-insensitive comparison and change the
  // accessibility label to the corresponding modifier key accessibility label.
  NSString *modifierKeyIdentifier = [gModifierKeyIdentifierMapping objectForKey:character];
  if (modifierKeyIdentifier) {
    // Check for the return key since we can have a different accessibility label
    // depending upon the keyboard.
    UIKeyboardImpl *currentKeyboard = [GREYKeyboard grey_keyboardObject];
    if ([character isEqualToString:kReturnKeyIdentifier]) {
      modifierKeyIdentifier = [currentKeyboard returnKeyDisplayName];
    }
    accessibilityLabel = modifierKeyIdentifier;
    ignoreCase = YES;
  }

  // iOS 9 changes & to ampersand.
  if ([accessibilityLabel isEqualToString:@"&"] && iOS9_OR_ABOVE()) {
    accessibilityLabel = @"ampersand";
  }

  return [GREYKeyboard grey_keyInArrayOfAccessibilityLabels:@[ accessibilityLabel ]
                        inKeyboardLayoutWithCaseSensitivity:ignoreCase];
}

/**
 *  Get the key on the keyboard for the given accessibility label.
 *
 *  @param accessibilityLabel The accessibility key of the key to be searched.
 *  @param ignoreCase         A Boolean that is @c YES if searching for the key requires ignoring
 *                            the case. This is seen in the case of modifier keys that have
 *                            differing cases across iOS versions.
 *
 *  @return A key that has the given accessibility label.
 */
+ (id)grey_keyInArrayOfAccessibilityLabels:(NSArray *)arrayOfLabels
       inKeyboardLayoutWithCaseSensitivity:(BOOL)ignoreCase {
  UIKeyboardImpl *keyboard = [GREYKeyboard grey_keyboardObject];
  // Type of layout is private class UIKeyboardLayoutStar, which implements UIAccessibilityContainer
  // Protocol and contains accessibility elements for keyboard keys that it shows on the screen.
  id layout = [keyboard _layout];
  NSAssert(layout, @"Layout instance must not be nil");
  if ([layout accessibilityElementCount] != NSNotFound) {
    for (NSInteger i = 0; i < [layout accessibilityElementCount]; ++i) {
      id key = [layout accessibilityElementAtIndex:i];
      for (NSString *accessibilityLabel in arrayOfLabels) {
        if ((ignoreCase &&
             [[key accessibilityLabel] caseInsensitiveCompare:accessibilityLabel] == NSOrderedSame) ||
            (!ignoreCase && [[key accessibilityLabel] isEqualToString:accessibilityLabel])) {
          return key;
        }
      }
    }
  }
  return nil;
}

/**
 *  Provides the active keyboard instance.
 *
 *  @return The active UIKeyboardImpl instance.
 */
+ (UIKeyboardImpl *)grey_keyboardObject {
  UIKeyboardImpl *keyboard = [UIKeyboardImpl activeInstance];
  NSAssert(keyboard, @"Keyboard instance must not be nil");
  return keyboard;
}

/**
 *  Utility method to tap on a key on the keyboard.
 *
 *  @param key            The key to be tapped.
 *  @param toggleKeyplane @c YES if the keyplane is to be toggled on hitting the key.
 */
+ (void)grey_tapKey:(id)key withKeyplaneToggling:(BOOL)toggleKeyplane {
  NSParameterAssert(key);
  NSLog(@"Tapping on key: %@.", [key accessibilityLabel]);
  NSUInteger keyplaneBeforeTapping = [GREYKeyboard grey_currentKeyplane];
  [gTapKeyAction perform:key error:nil];
  // Commit the implicit animations triggered on tapping on a keyboard key.
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  [CATransaction flush];
  [[[GREYKeyboard grey_keyboardObject] taskQueue] waitUntilAllTasksAreFinished];
  [[GREYUIThreadExecutor sharedInstance] drainOnce];
  // In case there are any keyplane animations post hitting a key, such as on hitting a shift key
  // then wait for them.
  if (toggleKeyplane) {
    [GREYKeyboard grey_ensureKeyplaneChangedFrom:keyplaneBeforeTapping];
  }
}

/**
 *  Populates or prints an error whenever a key with an accessibility label isn't found during
 *  typing a string.
 *
 *  @param accessibilityLabel The accessibility label of the key
 *  @param string             The string being typed when the key was not found
 *  @param[out] errorOrNil    The error to be populated. If this is @c nil,
 *                            then an error message is logged.
 *
 *  @return NO every time since entering the method means an error has happened.
 */
+ (BOOL)grey_setErrorForkeyNotFoundWithAccessibilityLabel:(NSString *)accessibilityLabel
                                          forTypingString:(NSString *)string
                                                    error:(__strong NSError **)errorOrNil {
  NSString *description = [NSString stringWithFormat:@"Failed to type string '%@', "
                                                     @"because key [K] could not be found "
                                                     @"on the keyboard.",
                                                     string];
  NSDictionary *glossary = @{ @"K" : [accessibilityLabel description] };
  GREYPopulateErrorNotedOrLog(errorOrNil,
                              kGREYInteractionErrorDomain,
                              kGREYInteractionElementNotFoundErrorCode,
                              description,
                              glossary);
  return NO;
}

/**
 *  A method that checks if the alphabetic keyplane is currently visible on the keyboard.
 *
 *  @return @c YES if the alphabetic keyplane is being shown on the keyboard, else @c NO.
 */
+ (BOOL)grey_isAlphabeticKeyplaneShown {
  // Arbitrarily choose e/E as the key to look for to determine if alphabetic keyplane is shown.
  return [GREYKeyboard grey_findKeyForCharacter:@"e"] != nil ||
         [GREYKeyboard grey_findKeyForCharacter:@"E"] != nil;
}

/**
 *  A convenience method to return the current keyplane visible on the keyboard.
 *
 *  @return A @c GREYKeyboardKeyplaneType signifying the current keyplane visible on the keyboard.
 */
+ (GREYKeyboardKeyplaneType)grey_currentKeyplane {
  NSArray *arrayOfKeyplaneIdentifyingKeys = @[ @"e", @"E", @"1", @"^" ];
  id key = [GREYKeyboard grey_keyInArrayOfAccessibilityLabels:arrayOfKeyplaneIdentifyingKeys
                          inKeyboardLayoutWithCaseSensitivity:YES];
  if ([[key accessibilityLabel] isEqualToString:@"e"]) {
    return GREYKeyboardKeyplaneTypeAlphabetSmall;
  } else if ([[key accessibilityLabel] isEqualToString:@"E"]) {
    return GREYKeyboardKeyplaneTypeAlphabetCapital;
  } else if ([[key accessibilityLabel] isEqualToString:@"1"]) {
    return GREYKeyboardKeyplaneTypeNumeric;
  } else if ([[key accessibilityLabel] isEqualToString:@"^"]) {
    return GREYKeyboardKeyplaneTypeMoreNumbers;
  } else {
    NSAssert(NO, @"Invalid keyboard keyplane present.");
    return NSNotFound;
  }
}

/**
 *  Drain the main thread until the keyboard's keyplane changes from the one provided.
 *
 *  @param originalKeyplane The keyboard keyplane that is to be changed from.
 */
+ (void)grey_ensureKeyplaneChangedFrom:(NSUInteger)originalKeyplane {
  [GREYKeyboard grey_spinRunloopForKeyboardWithTimeout:kKeyboardKeyplaneWillChange
                                  andStoppingCondition:^BOOL {
    return [GREYKeyboard grey_currentKeyplane] != originalKeyplane;
  }];
}

/**
 *  To wait for a keyboard animation or gesture, spin the runloop.
 *
 *  @param timeout The timeout of the runloop spinner.
 *  @param stopConditionBlock The condition block used to stop the runloop spinner.
 *
 *  @return @c YES if the keyboard type was changed if an email was being typed, else @c NO.
 */
+ (void)grey_spinRunloopForKeyboardWithTimeout:(NSTimeInterval)timeout
                          andStoppingCondition:(BOOL (^)(void))stopConditionBlock {
  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];
  runLoopSpinner.timeout = timeout;
  runLoopSpinner.maxSleepInterval = DBL_MAX;
  [runLoopSpinner spinWithStopConditionBlock:stopConditionBlock];
}

/**
 *  Prevent an email keyboard from converting every period into an email domain.
 *
 *  @param firstResponder The current firstResponder of the keyboard.
 *  @param character      The current character being typed.
 *
 *  @return @c YES if the keyboard type was changed if an email was being typed, else @c NO.
 */
+ (BOOL)grey_preventEmailDomainAutocorrectionOnFirstResponder:(id)firstResponder
                                                 forCharacter:(NSString *)character {
  if (iOS9_OR_ABOVE() &&
      [character isEqualToString:@"."] &&
      [firstResponder respondsToSelector:@selector(keyboardType)] &&
      [firstResponder keyboardType] == UIKeyboardTypeEmailAddress) {
    [firstResponder setKeyboardType:UIKeyboardTypeDefault];
    return YES;
  }
  return NO;
}

@end
