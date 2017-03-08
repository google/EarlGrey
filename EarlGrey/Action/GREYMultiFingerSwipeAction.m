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

#import "GREYMultiFingerSwipeAction.h"

#import "Action/GREYPathGestureUtils.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSString+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Common/GREYError.h"
#import "Event/GREYSyntheticEvents.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"

@implementation GREYMultiFingerSwipeAction {
    /**
     *  The direction in which the content must be scrolled.
     */
    GREYDirection _direction;
    /**
     *  The duration within which the swipe action must be complete.
     */
    CFTimeInterval _duration;
    /**
     *  Start point for the swipe specified as percentage of swipped element's accessibility frame.
     */
    CGPoint _startPercents;
    /**
     *  Number of parallel swipes
     */
    NSUInteger _numberOfSwipes;
}
    
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                   numberOfSwipes:(NSUInteger)numberOfSwipes
                     percentPoint:(CGPoint)percents {
    NSAssert(percents.x > 0.0f && percents.x < 1.0f,
             @"xOriginStartPercentage must be between 0 and 1, exclusively");
    NSAssert(percents.y > 0.0f && percents.y < 1.0f,
             @"yOriginStartPercentage must be between 0 and 1, exclusively");
    
    NSAssert(numberOfSwipes <= 4, @"No more than four parallel swipes are supported");
    
    NSString *name =
    [NSString stringWithFormat:@"Swipe %@ for duration %g", NSStringFromGREYDirection(direction),
     duration];
    self = [super initWithName:name
                   constraints:grey_allOf(grey_interactable(),
                                          grey_not(grey_systemAlertViewShown()),
                                          grey_kindOfClass([UIView class]),
                                          grey_respondsToSelector(@selector(accessibilityFrame)),
                                          nil)];
    if (self) {
        _direction = direction;
        _duration = duration;
        _numberOfSwipes = numberOfSwipes;
        _startPercents = percents;
    }
    return self;

}
    
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                   numberOfSwipes:(NSUInteger)numberOfSwipes {
    
    return [self initWithDirection:direction
                          duration:duration
                    numberOfSwipes:numberOfSwipes
                      percentPoint:CGPointMake(0.5, 0.5)];
}
    
    
- (instancetype)initWithDirection:(GREYDirection)direction
                         duration:(CFTimeInterval)duration
                   numberOfSwipes:(NSUInteger)numberOfSwipes
                    startPercents:(CGPoint)startPercents {
    
    return [self initWithDirection:direction
                          duration:duration
                    numberOfSwipes:numberOfSwipes
                      percentPoint:startPercents];
}
    
#pragma mark - GREYAction
    
- (BOOL)perform:(id)element error:(__strong NSError**)errorOrNil {
    if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
        return NO;
    }
    
    UIWindow *window = [element window];
    if (!window) {
        if ([element isKindOfClass:[UIWindow class]]) {
            window = (UIWindow *)element;
        } else {
            NSString *errorDescription =
            [NSString stringWithFormat:@"Cannot multi finger swipe on view [V], as it has no window and "
             @"it isn't a window itself."];
            NSDictionary *glossary = @{ @"V" : [element grey_description]};
            GREYError *error;
            error = GREYErrorMake(kGREYSyntheticEventInjectionErrorDomain,
                                  kGREYOrientationChangeFailedErrorCode,
                                  errorDescription);
            error.descriptionGlossary = glossary;
            if (errorOrNil) {
                *errorOrNil = error;
            } else {
                [GREYAssertions grey_raiseExceptionNamed:kGREYGenericFailureException
                                        exceptionDetails:@""
                                               withError:error];
            }
            
            return NO;
        }
    }
    
    NSMutableArray *multiTouchPaths = [[NSMutableArray alloc] init];
    
    CGRect accessibilityFrame = [element accessibilityFrame];
    
    for(NSUInteger i = 0; i < _numberOfSwipes; i++) {
        
        CGFloat xOffset, yOffset;
        switch (_direction) {
            case kGREYDirectionDown:
            case kGREYDirectionUp:
                xOffset = (CGFloat)i * 10;
                yOffset = 0.0;
                break;
            
            case kGREYDirectionLeft:
            case kGREYDirectionRight:
                xOffset = 0.0;
                yOffset = (CGFloat)i * 10;
                break;
        }
        
        
        CGPoint startPoint =
        CGPointMake(accessibilityFrame.origin.x + accessibilityFrame.size.width * _startPercents.x + xOffset,
                    accessibilityFrame.origin.y + accessibilityFrame.size.height * _startPercents.y + yOffset);
        
        NSArray *touchPath = [GREYPathGestureUtils touchPathForGestureWithStartPoint:startPoint
                                                                        andDirection:_direction
                                                                            inWindow:window];
        [multiTouchPaths addObject:touchPath];
    }
    
    [GREYSyntheticEvents touchAlongMultiplePaths:multiTouchPaths
                                relativeToWindow:window
                                     forDuration:_duration
                                      expendable:YES];
    
    return YES;
}

    
    
@end
