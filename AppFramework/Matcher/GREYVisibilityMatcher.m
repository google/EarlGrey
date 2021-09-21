#import "GREYVisibilityMatcher.h"

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "GREYFatalAsserts.h"
#import "GREYDiagnosable.h"
#import "GREYDescription.h"
#import "GREYElementMatcherBlock+Private.h"
#import "GREYElementMatcherBlock.h"
#import "CGGeometry+GREYUI.h"
#import "GREYVisibilityChecker.h"

// The minimum percentage of an element's accessibility frame that must be visible before EarlGrey
// considers the element to be sufficiently visible.
static const double kElementSufficientlyVisiblePercentage = 0.75;

@implementation GREYVisibilityMatcher

- (instancetype)initForMinimumVisiblePercent:(CGFloat)percent {
  GREYFatalAssertWithMessage(percent >= 0.0f && percent <= 1.0f,
                             @"Percent %f must be in the range [0,1]", percent);
  NSString *prefix = @"minimumVisiblePercent";
  __block CGFloat visiblePercent;
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    visiblePercent = [GREYVisibilityChecker percentVisibleAreaOfElement:element];
    return visiblePercent >= percent;
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *descriptionString = [NSString
        stringWithFormat:@"%@(Expected: %f, Actual: %f)", prefix, percent, visiblePercent];
    [description appendText:descriptionString];
  };
  return [self initWithName:GREYCorePrefixedDiagnosticsID(prefix)
               matchesBlock:matches
           descriptionBlock:describe];
}

- (instancetype)initForSufficientlyVisible {
  NSString *prefix = @"sufficientlyVisible";
  __block CGFloat visiblePercent = 0;
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    visiblePercent = [GREYVisibilityChecker percentVisibleAreaOfElement:element];
    return (visiblePercent >= kElementSufficientlyVisiblePercentage);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *descriptionString =
        [NSString stringWithFormat:@"%@(Expected: %f, Actual: %f)", prefix,
                                   kElementSufficientlyVisiblePercentage, visiblePercent];
    [description appendText:descriptionString];
  };
  return [self initWithName:GREYCorePrefixedDiagnosticsID(prefix)
               matchesBlock:matches
           descriptionBlock:describe];
}

- (instancetype)initForInteractable {
  NSString *prefix = @"interactable";
  __block CGPoint interactionPoint;
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    interactionPoint = [GREYVisibilityChecker visibleInteractionPointForElement:element];
    return !CGPointIsNull(interactionPoint);
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    NSString *interactionPointDescription =
        [NSString stringWithFormat:@"%@ Point:%@", prefix, NSStringFromCGPoint(interactionPoint)];
    [description appendText:interactionPointDescription];
  };
  return [self initWithName:GREYCorePrefixedDiagnosticsID(prefix)
               matchesBlock:matches
           descriptionBlock:describe];
}

- (instancetype)initForNotVisible {
  NSString *prefix = @"notVisible";
  GREYMatchesBlock matches = ^BOOL(UIView *element) {
    return [GREYVisibilityChecker isNotVisible:element];
  };
  GREYDescribeToBlock describe = ^void(id<GREYDescription> description) {
    [description appendText:prefix];
  };
  return [self initWithName:GREYCorePrefixedDiagnosticsID(prefix)
               matchesBlock:matches
           descriptionBlock:describe];
}

@end
