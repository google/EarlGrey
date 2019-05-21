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

#import "AppFramework/Core/GREYElementInteraction.h"
#import "AppFramework/Matcher/GREYMatchers.h"
#import "CommonLib/GREYAppleInternals.h"
#import "CommonLib/Matcher/GREYBaseMatcher+Private.h"
#import "CommonLib/Matcher/GREYBaseMatcher.h"
#import "CommonLib/Matcher/GREYLayoutConstraint.h"
#import "CommonLib/Matcher/GREYMatcher.h"
#import "CommonLib/Matcher/GREYStringDescription.h"
#import "Tests/Unit/AppFramework/GREYAppBaseTest.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

#pragma mark - Test Helpers

@interface CustomUIView : UIView
@property(nonatomic, assign) BOOL accessibilityElementIsFocused;
@end

@implementation CustomUIView : UIView
@end

#pragma mark -

@interface GREYMatchersTest : GREYAppBaseTest
@end

@implementation GREYMatchersTest

- (void)testGreyDescriptionProtocol {
  id<GREYDescription> description = [[GREYStringDescription alloc] init];
  XCTAssertTrue([description conformsToProtocol:@protocol(NSSecureCoding)],
                @"GREYDescription should follow the NSSecureCoding protocol.");
}

- (void)testGreyLayoutConstraintProtocol {
  GREYLayoutConstraint *constraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionLeft
                                    andMinimumSeparation:0];
  XCTAssertTrue([constraint conformsToProtocol:@protocol(NSSecureCoding)],
                @"GREYLayoutConstraint should follow the NSSecureCoding protocol.");
}

- (void)testVisibleMatcherWithUIView {
  UIView *view = [[UIView alloc] init];
  view.hidden = YES;
  view.alpha = 1;
  id<GREYMatcher> matcher = [GREYMatchers matcherForSufficientlyVisible];
  XCTAssertFalse([matcher matches:view], @"Should fail because view is hidden.");
}

- (void)testNotVisibleMatcherWithUIView {
  UIView *view = [[UIView alloc] init];
  view.hidden = YES;
  view.alpha = 0;
  id<GREYMatcher> matcher = [GREYMatchers matcherForNotVisible];
  XCTAssertTrue([matcher matches:view], @"Should pass because view is hidden.");
}

- (void)testVisibleMatcherWithUIElement {
  UIView *containerView = [[UIView alloc] init];
  containerView.hidden = YES;
  containerView.alpha = 1;
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:containerView];
  id<GREYMatcher> matcher = [GREYMatchers matcherForSufficientlyVisible];
  XCTAssertFalse([matcher matches:element], @"Should fail because containerview is hidden.");
}

- (void)testNotVisibleMatcherWithUIElement {
  UIView *containerView = [[UIView alloc] init];
  containerView.hidden = YES;
  containerView.alpha = 1;
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:containerView];
  id<GREYMatcher> matcher = [GREYMatchers matcherForNotVisible];
  XCTAssertTrue([matcher matches:element], @"Should pass because containerview is hidden.");
}

- (void)testWithAncestorMatcher {
  id<GREYMatcher> viewMatcher =
      [GREYMatchers matcherForAncestor:[GREYMatchers matcherForKindOfClass:[UIView class]]];
  id<GREYMatcher> windowMatcher =
      [GREYMatchers matcherForAncestor:[GREYMatchers matcherForKindOfClass:[UIWindow class]]];

  UIWindow *window = [[UIWindow alloc] init];
  UIView *viewA = [[UIView alloc] init];
  UIView *viewAA = [[UIView alloc] init];   // child of A.
  UIView *viewAB = [[UIView alloc] init];   // sibling of AA.
  UIView *viewAAA = [[UIView alloc] init];  // child of AA.

  [window addSubview:viewA];
  [viewA addSubview:viewAA];
  [viewA addSubview:viewAB];
  [viewAA addSubview:viewAAA];

  XCTAssertTrue([viewMatcher matches:viewA], @"viewA's ancestor is a window that is a UIView");
  XCTAssertTrue([viewMatcher matches:viewAA], @"viewAA's ancestor are UIViews");
  XCTAssertTrue([viewMatcher matches:viewAB], @"viewAB's ancestor are UIViews");
  XCTAssertTrue([viewMatcher matches:viewAAA], @"viewAAA's ancestor are UIViews");

  XCTAssertFalse([windowMatcher matches:window], @"window doesn't have an ancestor");
  XCTAssertTrue([windowMatcher matches:viewA], @"viewA is contained within a window");
  XCTAssertTrue([windowMatcher matches:viewAA], @"viewAA is contained within a window");
  XCTAssertTrue([windowMatcher matches:viewAB], @"viewAB is contained within a window");
  XCTAssertTrue([windowMatcher matches:viewAAA], @"viewAAA is contained within a window");
}

- (void)testWithAncestorMatcherWithAccessibilityElements {
  id<GREYMatcher> matcherWindow =
      [GREYMatchers matcherForAncestor:[GREYMatchers matcherForKindOfClass:[UIWindow class]]];

  UIWindow *window = [[UIWindow alloc] init];
  UIView *viewA = [[UIView alloc] init];

  id mockElementA = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementA stub] andReturn:viewA] accessibilityContainer];

  id mockElementB = [OCMockObject mockForClass:[UIAccessibilityElement class]];
  [[[mockElementB stub] andReturn:mockElementA] accessibilityContainer];

  [window addSubview:viewA];

  XCTAssertFalse([matcherWindow matches:window], @"window doesn't have an ancestor");
  XCTAssertTrue([matcherWindow matches:viewA], @"viewA is contained within a window");
  XCTAssertTrue([matcherWindow matches:mockElementA], @"mockElementA is contained within a window");
  XCTAssertTrue([matcherWindow matches:mockElementB], @"mockElementB is contained within a window");
}

- (void)testDescendantMatcherDoesNotMatchNilElements {
  NSString *matcherString = @"SomeUIElement";
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForDescendant:[GREYMatchers matcherForAccessibilityLabel:matcherString]];
  XCTAssertFalse([matcher matches:nil]);
}

- (void)testDescendantMatcher {
  id<GREYMatcher> matchesAncestorOfChildA =
      [GREYMatchers matcherForDescendant:[GREYMatchers matcherForAccessibilityLabel:@"ChildA"]];
  id<GREYMatcher> matchesAncestorOfChildB =
      [GREYMatchers matcherForDescendant:[GREYMatchers matcherForAccessibilityLabel:@"ChildB"]];
  id<GREYMatcher> matchesAncestorOfGrandchild =
      [GREYMatchers matcherForDescendant:[GREYMatchers matcherForAccessibilityLabel:@"Grandchild"]];
  id<GREYMatcher> shouldNotMatch =
      [GREYMatchers matcherForDescendant:[GREYMatchers matcherForAccessibilityLabel:@"NotPresent"]];

  UIWindow *window = [[UIWindow alloc] init];
  UIView *childA = [[UIView alloc] init];
  childA.isAccessibilityElement = YES;
  childA.accessibilityLabel = @"ChildA";
  UIView *childB = [[UIView alloc] init];
  childB.isAccessibilityElement = YES;
  childB.accessibilityLabel = @"ChildB";
  UIView *grandchild = [[UIView alloc] init];
  grandchild.isAccessibilityElement = YES;
  grandchild.accessibilityLabel = @"Grandchild";

  [window addSubview:childA];
  [window addSubview:childB];
  [childA addSubview:grandchild];

  XCTAssertTrue([matchesAncestorOfChildA matches:window], @"Child A is a child of Window");
  XCTAssertTrue([matchesAncestorOfChildB matches:window], @"Child B is a child of Window");
  XCTAssertTrue([matchesAncestorOfGrandchild matches:window],
                @"Grandchild is a grandchild of Window");
  XCTAssertTrue([matchesAncestorOfGrandchild matches:childA], @"Grandchild is a child of Child A");
  XCTAssertFalse([matchesAncestorOfChildA matches:childA], @"ChildA is not a child of itself");
  XCTAssertFalse([shouldNotMatch matches:window], @"No child of window matches this");
}

- (void)testgrey_respondsToSelector {
  id<GREYMatcher> matcher = [GREYMatchers matcherForRespondsToSelector:@selector(setNeedsLayout)];
  UIView *uiview = [[UIView alloc] init];
  XCTAssertTrue([matcher matches:uiview], @"UIView responds to setNeedsLayout");
  // We use NSSelectorFromString because otherwise compiler warns us that grey_doesNotExist doesn't
  // actually exist and we know that and thats what we are trying to test...but warnings are
  // pretty annoying!
  matcher = [GREYMatchers matcherForRespondsToSelector:NSSelectorFromString(@"grey_doesNotExist")];
  XCTAssertFalse([matcher matches:uiview], @"UIView should not respond to grey_doesNotExist");
}

- (void)testIsKindOfClass {
  id<GREYMatcher> matcher = [GREYMatchers matcherForKindOfClass:[UIView class]];
  UIWindow *window = [[UIWindow alloc] init];
  UIView *uiview = [[UIView alloc] init];
  NSObject *object = [[NSObject alloc] init];
  XCTAssertTrue([matcher matches:window], @"Window is a subclass of UIView");
  XCTAssertTrue([matcher matches:uiview], @"UIView is a subclass of UIView");
  XCTAssertFalse([matcher matches:object], @"NSObject is not a subclass of UIView");
}

- (void)testIsKindOfClassName {
  id<GREYMatcher> matcher = [GREYMatchers matcherForKindOfClass:[UIView class]];
  UIWindow *window = [[UIWindow alloc] init];
  UIView *uiview = [[UIView alloc] init];
  NSObject *object = [[NSObject alloc] init];
  XCTAssertTrue([matcher matches:window], @"Window is a subclass of UIView");
  XCTAssertTrue([matcher matches:uiview], @"UIView is a subclass of UIView");
  XCTAssertFalse([matcher matches:object], @"NSObject is not a subclass of UIView");
}

- (void)testProgressIsGreaterThanMatcher {
  UILabel *label = [[UILabel alloc] init];
  UIProgressView *progressView = [[UIProgressView alloc] init];
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForProgress:[GREYMatchers matcherForGreaterThan:@(0.8f)]];
  progressView.progress = 0.3f;
  XCTAssertFalse([matcher matches:progressView], @"Greater progress matcher should return false");
  progressView.progress = 0.9f;
  XCTAssertTrue([matcher matches:progressView], @"Greater progress matcher should return true");
  XCTAssertFalse([matcher matches:label], @"UILabel does not have progress");
}

- (void)testProgressIsLessThanMatcher {
  UIView *uiview = [[UIView alloc] init];
  UIProgressView *progressView = [[UIProgressView alloc] init];
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForProgress:[GREYMatchers matcherForLessThan:@(0.6f)]];
  progressView.progress = 0.9f;
  XCTAssertFalse([matcher matches:progressView], @"Less progress matcher should return false");
  progressView.progress = 0.2f;
  XCTAssertTrue([matcher matches:progressView], @"Less progress matcher should return true");
  XCTAssertFalse([matcher matches:uiview], @"UIView does not have progress");
}

- (void)testProgressIsEqualMatcher {
  UIButton *uibutton = [[UIButton alloc] init];
  UIProgressView *progressView = [[UIProgressView alloc] init];
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForProgress:[GREYMatchers matcherForEqualTo:@(0.6f)]];
  progressView.progress = 0.9f;
  XCTAssertFalse([matcher matches:progressView], @"Equal progress matcher should return false");
  progressView.progress = 0.6f;
  XCTAssertTrue([matcher matches:progressView], @"Equal progress matcher should return true");
  XCTAssertFalse([matcher matches:uibutton], @"UIButton does not have progress");
}

- (void)testButtonTitleMatcher {
  UIButton *button = [[UIButton alloc] init];
  button.titleLabel.text = @"Foo";
  id<GREYMatcher> matcher = [GREYMatchers matcherForButtonTitle:@"Bar"];
  XCTAssertFalse([matcher matches:button], @"Button title matcher should return false");
  button.titleLabel.text = @"Bar";
  XCTAssertTrue([matcher matches:button], @"Button title matcher should return true");
  UIView *view = [[UIView alloc] init];
  XCTAssertFalse([matcher matches:view], @"UIView does not have title");
}

- (void)testScrollViewContentOffsetMatcher {
  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.contentOffset = CGPointMake(10.0f, 20.0f);
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForScrollViewContentOffset:CGPointMake(20.0f, 10.0f)];
  XCTAssertFalse([matcher matches:scrollView], @"Matcher should return false");
  scrollView.contentOffset = CGPointMake(20.0f, 10.0f);
  XCTAssertTrue([matcher matches:scrollView], @"Matcher should return true");
}

- (void)testIsSystemAlertViewShown {
  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> matcher = [GREYMatchers matcherForSystemAlertViewShown];

  [[[self.mockSharedApplication expect] andReturnValue:@YES]
      performSelector:@selector(_isSpringBoardShowingAnAlert)];
  XCTAssertTrue([matcher matches:view], @"System alert should be showing.");
  [self.mockSharedApplication verify];
  [[[self.mockSharedApplication expect] andReturnValue:@NO]
      performSelector:@selector(_isSpringBoardShowingAnAlert)];
  XCTAssertFalse([matcher matches:view], @"System alert should not be showing.");
  [self.mockSharedApplication verify];
}

- (void)testIsFirstResponder {
  UIView *view = [[UIView alloc] init];
  id mockUIView = [OCMockObject partialMockForObject:view];
  [[[mockUIView expect] andReturnValue:@YES] isFirstResponder];
  id<GREYMatcher> matcher = [GREYMatchers matcherForFirstResponder];
  XCTAssertTrue([matcher matches:mockUIView], @"Should pass because view is first responder.");
  [mockUIView verify];
  [[[mockUIView expect] andReturnValue:@NO] isFirstResponder];
  XCTAssertFalse([matcher matches:mockUIView], @"Should fail because view is not first responder.");
  [mockUIView verify];
}

- (void)testMatchingLabelPass {
  UIView *viewWithLabel = [[UIView alloc] init];
  viewWithLabel.isAccessibilityElement = YES;
  viewWithLabel.accessibilityLabel = @"view 1";
  id<GREYMatcher> labelMatcher = [GREYMatchers matcherForAccessibilityLabel:@"view 1"];
  XCTAssertTrue([labelMatcher matches:viewWithLabel], @"Matching a11y labels should return true.");
}

- (void)testMatchingLabelFail {
  UIView *viewWithLabel = [[UIView alloc] init];
  viewWithLabel.accessibilityLabel = @"view 1";
  id<GREYMatcher> labelMatcher = [GREYMatchers matcherForAccessibilityLabel:@"view 2"];
  XCTAssertFalse([labelMatcher matches:viewWithLabel], @"Non-matching labels should return false.");
}

- (void)testMatchingidPass {
  UIView *viewWithLabel = [[UIView alloc] init];
  viewWithLabel.accessibilityIdentifier = @"view 1";
  id<GREYMatcher> idMatcher = [GREYMatchers matcherForAccessibilityID:@"view 1"];
  XCTAssertTrue([idMatcher matches:viewWithLabel],
                @"Matching a11y id<GREYMatcher>s should return true.");
}

- (void)testMatchingidFail {
  UIView *viewWithLabel = [[UIView alloc] init];
  viewWithLabel.accessibilityIdentifier = @"view 1";
  id<GREYMatcher> idMatcher = [GREYMatchers matcherForAccessibilityID:@"view 2"];
  XCTAssertFalse([idMatcher matches:viewWithLabel],
                 @"Non-matching id<GREYMatcher>s should return false.");
}

- (void)testMatchingTraitsPass {
  UIButton *testButton = [[UIButton alloc] init];
  testButton.isAccessibilityElement = YES;
  // Accessibility traits must be set manually if a view is programatically created.
  testButton.accessibilityTraits = UIAccessibilityTraitButton;
  id<GREYMatcher> traitMatcher =
      [GREYMatchers matcherForAccessibilityTraits:UIAccessibilityTraitButton];
  XCTAssertTrue([traitMatcher matches:testButton], @"Matching traits should return true");
}

- (void)testMatchingTraitsFail {
  UIButton *testButton = [[UIButton alloc] init];
  testButton.accessibilityTraits = UIAccessibilityTraitButton;
  id<GREYMatcher> traitMatcher =
      [GREYMatchers matcherForAccessibilityTraits:UIAccessibilityTraitPlaysSound];
  XCTAssertFalse([traitMatcher matches:testButton], @"Non-matching traits should return false");
}

- (void)testMatchingHintPass {
  UIView *viewWithHint = [[UIView alloc] init];
  viewWithHint.isAccessibilityElement = YES;
  viewWithHint.accessibilityHint = @"An UIView with hint";
  id<GREYMatcher> hintMatcher = [GREYMatchers matcherForAccessibilityHint:@"An UIView with hint"];
  XCTAssertTrue([hintMatcher matches:viewWithHint], @"Matching a11y hint should return true");
}

- (void)testMatchingHintFail {
  UIView *viewWithHint = [[UIView alloc] init];
  viewWithHint.accessibilityHint = @"An UIView with hint";
  id<GREYMatcher> hintMatcher = [GREYMatchers matcherForAccessibilityHint:@"Different hint"];
  XCTAssertFalse([hintMatcher matches:viewWithHint], @"Matching a11y hint should return false");
}

- (void)testFocused {
  CustomUIView *customUIView = [[CustomUIView alloc] init];
  [customUIView setAccessibilityElementIsFocused:YES];
  id<GREYMatcher> focusMatcher = [GREYMatchers matcherForAccessibilityElementIsFocused];
  XCTAssertTrue([focusMatcher matches:customUIView], @"View should be focused");
}

- (void)testNotFocused {
  CustomUIView *customUIView = [[CustomUIView alloc] init];
  [customUIView setAccessibilityElementIsFocused:NO];
  id<GREYMatcher> focusMatcher = [GREYMatchers matcherForAccessibilityElementIsFocused];
  XCTAssertFalse([focusMatcher matches:customUIView], @"View should not be focused");
}

- (void)testTextMatcherPass {
  UILabel *testLabel = [[UILabel alloc] init];
  [testLabel setText:@"display text"];
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:@"display text"];
  XCTAssertTrue([textMatcher matches:testLabel], @"Matching text should return true");
}

- (void)testTextMatcherFail {
  UILabel *testLabel = [[UILabel alloc] init];
  [testLabel setText:@"display text"];
  id<GREYDescription> failureDesc = [[GREYStringDescription alloc] init];
  id<GREYMatcher> textMatcher = [GREYMatchers matcherForText:@"incorrect display text"];
  XCTAssertFalse([textMatcher matches:testLabel describingMismatchTo:failureDesc],
                 @"Non-matching text should return false");
  NSRange failureMessageRange =
      [[failureDesc description] rangeOfString:@"hasText('incorrect display text')"];
  XCTAssertNotEqual(failureMessageRange.location, NSNotFound);
}

- (void)testBadObjectTypeFail {
  NSString *badObject = @"I am not a view";
  id<GREYMatcher> labelMatcher = [GREYMatchers matcherForAccessibilityLabel:@"I am not a view"];
  XCTAssertFalse([labelMatcher matches:badObject], @"Non-view objects should not match.");
}

- (void)testMultipleMatches {
  UIButton *testButton = [[UIButton alloc] init];
  testButton.isAccessibilityElement = YES;
  testButton.accessibilityLabel = @"button 1";
  testButton.accessibilityTraits = UIAccessibilityTraitButton;
  id<GREYMatcher> traitMatcher =
      [GREYMatchers matcherForAccessibilityTraits:UIAccessibilityTraitButton];
  XCTAssertTrue([traitMatcher matches:testButton], @"Matching traits should return true");
  id<GREYMatcher> labelMatcher = [GREYMatchers matcherForAccessibilityLabel:@"button 1"];
  XCTAssertTrue([labelMatcher matches:testButton],
                @"Matching a11y id<GREYMatcher>s should return true.");
}

- (void)testWithSliderValue {
  UISlider *testSlider = [[UISlider alloc] init];
  testSlider.maximumValue = 100;
  testSlider.minimumValue = 0;
  testSlider.value = 3;
  id<GREYMatcher> matcherForCloseTo =
      [GREYMatchers matcherForCloseTo:3.0f delta:kGREYAcceptableFloatDifference];
  id<GREYMatcher> matcher = [GREYMatchers matcherForSliderValueMatcher:matcherForCloseTo];
  XCTAssertTrue([matcher matches:testSlider], @"Matching traits should return true");
  testSlider.value = 4;
  XCTAssertFalse([matcher matches:testSlider], @"Non-matching traits should return false");
}

- (void)testConformsToProtocol {
  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> matcher =
      [GREYMatchers matcherForConformsToProtocol:@protocol(UIAppearanceContainer)];
  XCTAssertTrue([matcher matches:view], @"Every uiview should be an appearance container");
  XCTAssertFalse([matcher matches:[[NSObject alloc] init]],
                 @"NSObject shouldn't be an appearance container");
}

- (void)testgrey_accessibilityElement {
  UIView *accessibleView = [[UIView alloc] init];
  accessibleView.isAccessibilityElement = YES;
  id<GREYMatcher> matcher = [GREYMatchers matcherForAccessibilityElement];
  XCTAssertTrue([matcher matches:accessibleView], @"View must be accessible");
  XCTAssertFalse([matcher matches:[[NSObject alloc] init]],
                 @"Random NSObject shouldn't be accessible");
}

- (void)testIsEnabled_trueForSimpleViews {
  // Every UIView is not a disabled UIControl!.
  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertTrue([matcher matches:view], @"Simple View should be tappable");
}

- (void)testIsEnabled_trueForEnabledControls {
  UIControl *control = [[UIControl alloc] init];
  control.enabled = YES;
  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertTrue([matcher matches:control], @"Enabled Controls should be tappable");
}

- (void)testIsEnabled_isTrueForDisabledControls {
  UIControl *control = [[UIControl alloc] init];
  control.enabled = NO;
  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertFalse([matcher matches:control], @"Disabled Controls should not be tappable");
}

- (void)testIsEnabled_isTrueForTappableChildOfTappableParents {
  UIView *parent = [[UIView alloc] init];
  UIControl *child = [[UIControl alloc] init];
  [parent addSubview:child];

  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertTrue([matcher matches:child], @"Tappable child of tappable parent should be tappable");
}

- (void)testIsEnabled_isFalseForTappableChildOfUntappableParents {
  UIControl *parent = [[UIControl alloc] init];
  parent.enabled = NO;
  UIControl *child = [[UIControl alloc] init];
  [parent addSubview:child];

  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertFalse([matcher matches:child],
                 @"Tappable child of untappable parent should not be tappable");
}

- (void)testIsEnabled_isFalseForUntappableChildOfTappableParents {
  UIView *parent = [[UIView alloc] init];
  UIControl *child = [[UIControl alloc] init];
  child.enabled = NO;
  [parent addSubview:child];

  id<GREYMatcher> matcher = [GREYMatchers matcherForEnabledElement];
  XCTAssertFalse([matcher matches:child],
                 @"Untappable child of tappable parent should not be tappable");
}

- (void)testIsSelected_isTrueForSelectedControl {
  UIControl *control = [[UIControl alloc] init];
  control.selected = YES;
  id<GREYMatcher> matcher = [GREYMatchers matcherForSelectedElement];
  XCTAssertTrue([matcher matches:control], @"Selected controls should be matched");
}

- (void)testIsSelected_isFalseForUnselectedControl {
  UIControl *control = [[UIControl alloc] init];
  control.selected = NO;
  id<GREYMatcher> matcher = [GREYMatchers matcherForSelectedElement];
  id<GREYDescription> description = [[GREYStringDescription alloc] init];
  XCTAssertFalse([matcher matches:control describingMismatchTo:description],
                 @"Unselected controls should not be matched");
  XCTAssertTrue([[description description] isEqualToString:@"selected"]);
}

- (void)testIsUserInteractionEnabled_isTrueForEnabledView {
  UIView *view = [[UIView alloc] init];
  view.userInteractionEnabled = YES;
  id<GREYMatcher> matcher = [GREYMatchers matcherForUserInteractionEnabled];
  XCTAssertTrue([matcher matches:view], @"Views with user interaction enabled should be matched");
}

- (void)testIsUserInteractionEnabled_isFalseForDisabledView {
  UIView *view = [[UIView alloc] init];
  view.userInteractionEnabled = NO;
  id<GREYMatcher> matcher = [GREYMatchers matcherForUserInteractionEnabled];
  XCTAssertFalse([matcher matches:view],
                 @"Views with user interaction disabled should not be matched");
}

- (void)testLayoutMatcherWithSingleConstraint {
  // Prepare a window and add reference view to it.
  UIWindow *window = [[UIWindow alloc] init];
  UIView *reference = [[UIView alloc] init];
  [reference setAccessibilityFrame:CGRectMake(0, 0, 50, 50)];
  [window addSubview:reference];

  // Prepare mocks for test.
  [[[self.mockSharedApplication stub] andReturn:@[ window ]] windows];

  // Prepare constraints.
  GREYLayoutConstraint *leftConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionLeft
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *rightConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionRight
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *topConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionUp
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *bottomConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionDown
                                    andMinimumSeparation:0];

  id referenceMatcher =
      [GREYMatchers matcherForAncestor:[GREYMatchers matcherForKindOfClass:[UIWindow class]]];

  // Set a view on left of reference and verify matcher works.
  UIView *view = [[UIView alloc] init];
  [view setAccessibilityFrame:CGRectMake(-50, 0, 50, 50)];
  XCTAssertTrue([[GREYMatchers matcherForConstraints:@[ leftConstraint ]
                          toReferenceElementMatching:referenceMatcher] matches:view],
                @"Element is not on left.");
  XCTAssertFalse([[GREYMatchers matcherForConstraints:@[ rightConstraint ]
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must not be right.");

  // Set view on right of reference and verify matcher works.
  [view setAccessibilityFrame:CGRectMake(50, 0, 50, 50)];
  XCTAssertTrue([[GREYMatchers matcherForConstraints:@[ rightConstraint ]
                          toReferenceElementMatching:referenceMatcher] matches:view],
                @"Element is not on right.");
  XCTAssertFalse([[GREYMatchers matcherForConstraints:@[ leftConstraint ]
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must not be on left.");

  // Set view on top of reference and verify matcher works.
  [view setAccessibilityFrame:CGRectMake(0, -50, 50, 50)];
  XCTAssertTrue([[GREYMatchers matcherForConstraints:@[ topConstraint ]
                          toReferenceElementMatching:referenceMatcher] matches:view],
                @"Element is not on top.");
  XCTAssertFalse([[GREYMatchers matcherForConstraints:@[ bottomConstraint ]
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must not be at the bottom.");

  // Set view on bottom of reference and verify matcher works.
  [view setAccessibilityFrame:CGRectMake(0, 50, 50, 50)];
  XCTAssertTrue([[GREYMatchers matcherForConstraints:@[ bottomConstraint ]
                          toReferenceElementMatching:referenceMatcher] matches:view],
                @"Element is not at the bottom.");
  XCTAssertFalse([[GREYMatchers matcherForConstraints:@[ topConstraint ]
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must not be on top.");
}

- (void)testLayoutMatcherWithMultipleConstraints {
  // Prepare a window and add reference view to it.
  UIWindow *window = [[UIWindow alloc] init];
  UIView *reference = [[UIView alloc] init];
  [reference setAccessibilityFrame:CGRectMake(0, 0, 50, 50)];
  [window addSubview:reference];

  // Prepare mocks for test.
  [[[self.mockSharedApplication stub] andReturn:@[ window ]] windows];

  // Prepare constraints.
  GREYLayoutConstraint *leftConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionLeft
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *rightConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionRight
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *topConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionUp
                                    andMinimumSeparation:0];
  GREYLayoutConstraint *bottomConstraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionDown
                                    andMinimumSeparation:0];

  // Set a view on top-left and verify the constraints work with it.
  UIView *view = [[UIView alloc] init];
  [view setAccessibilityFrame:CGRectMake(-50, -50, 50, 50)];

  // Check that matches for all constraints.
  id referenceMatcher =
      [GREYMatchers matcherForAncestor:[GREYMatchers matcherForKindOfClass:[UIWindow class]]];

  NSArray *topLeftConstraints = @[ leftConstraint, topConstraint ];
  XCTAssertTrue([[GREYMatchers matcherForConstraints:topLeftConstraints
                          toReferenceElementMatching:referenceMatcher] matches:view],
                @"Element is not on top-left.");

  NSArray *bottomRightConstraints = @[ rightConstraint, bottomConstraint ];
  XCTAssertFalse([[GREYMatchers matcherForConstraints:bottomRightConstraints
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must is not be on bottom-right.");

  NSArray *bottomLeftConstraints = @[ leftConstraint, bottomConstraint ];
  XCTAssertFalse([[GREYMatchers matcherForConstraints:bottomLeftConstraints
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must is not be on bottom-left.");

  NSArray *topRightConstraints = @[ rightConstraint, topConstraint ];
  XCTAssertFalse([[GREYMatchers matcherForConstraints:topRightConstraints
                           toReferenceElementMatching:referenceMatcher] matches:view],
                 @"Element must is not be on top-right.");
}

- (void)testSwitchInOFFStateMatcher {
  UISwitch *uiswitch = [[UISwitch alloc] init];
  [uiswitch setOn:NO];
  XCTAssertTrue([[GREYMatchers matcherForSwitchWithOnState:NO] matches:uiswitch]);
  XCTAssertFalse([[GREYMatchers matcherForSwitchWithOnState:YES] matches:uiswitch]);
}

- (void)testSwitchInONStateMatcher {
  UISwitch *uiswitch = [[UISwitch alloc] init];
  [uiswitch setOn:YES];
  XCTAssertFalse([[GREYMatchers matcherForSwitchWithOnState:NO] matches:uiswitch]);
  XCTAssertTrue([[GREYMatchers matcherForSwitchWithOnState:YES] matches:uiswitch]);
}

- (void)testTextFieldValueMatcher {
  UITextField *textField = [[UITextField alloc] init];
  textField.text = @"Foo";
  id<GREYMatcher> matcher = [GREYMatchers matcherForTextFieldValue:@"Bar"];
  XCTAssertFalse([matcher matches:textField], @"TextField Test matcher should return false");
  textField.text = @"Bar";
  XCTAssertTrue([matcher matches:textField], @"TextField Test matcher should return true");
  UIView *view = [[UIView alloc] init];
  XCTAssertFalse([matcher matches:view], @"UIView does not have title");
}

- (void)testMatchersIdentifier {
  GREYBaseMatcher *matcher =
      (GREYBaseMatcher *)[GREYMatchers matcherForKindOfClass:[NSObject class]];
  XCTAssertEqualObjects([matcher name], @"kindOfClass");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForKeyWindow];
  XCTAssertEqualObjects([matcher name], @"keyWindow");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForCloseTo:1.0 delta:1.0];
  XCTAssertEqualObjects([matcher name], @"closeTo");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAnything];
  XCTAssertEqualObjects([matcher name], @"anything");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForEqualTo:[[NSObject alloc] init]];
  XCTAssertEqualObjects([matcher name], @"equalTo");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForLessThan:[[NSObject alloc] init]];
  XCTAssertEqualObjects([matcher name], @"lessThan");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForGreaterThan:[[NSObject alloc] init]];
  XCTAssertEqualObjects([matcher name], @"greaterThan");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityLabel:@""];
  XCTAssertEqualObjects([matcher name], @"accessibilityLabel");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityID:@""];
  XCTAssertEqualObjects([matcher name], @"accessibilityID");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityValue:@""];
  XCTAssertEqualObjects([matcher name], @"accessibilityValue");
  matcher =
      (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityTraits:UIAccessibilityTraitNone];
  XCTAssertEqualObjects([matcher name], @"accessibilityTraits");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityHint:@""];
  XCTAssertEqualObjects([matcher name], @"accessibilityHint");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityElementIsFocused];
  XCTAssertEqualObjects([matcher name], @"accessibilityFocused");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForText:@""];
  XCTAssertEqualObjects([matcher name], @"hasText");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForFirstResponder];
  XCTAssertEqualObjects([matcher name], @"firstResponder");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForSystemAlertViewShown];
  XCTAssertEqualObjects([matcher name], @"isSystemAlertViewShown");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForMinimumVisiblePercent:0.1];
  XCTAssertEqualObjects([matcher name], @"matcherForMinimumVisiblePercent");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForSufficientlyVisible];
  XCTAssertEqualObjects([matcher name], @"matcherForSufficientlyVisible");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForInteractable];
  XCTAssertEqualObjects([matcher name], @"interactable");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForNotVisible];
  XCTAssertEqualObjects([matcher name], @"notVisible");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAccessibilityElement];
  XCTAssertEqualObjects([matcher name], @"isAccessibilityElement");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForProgress:[GREYMatchers matcherForNil]];
  XCTAssertEqualObjects([matcher name], @"progressValueThatMatches");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForRespondsToSelector:@selector(text)];
  XCTAssertEqualObjects([matcher name], @"respondsToSelector");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForConformsToProtocol:@protocol(UITextInput)];
  XCTAssertEqualObjects([matcher name], @"conformsToProtocol");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForAncestor:[GREYMatchers matcherForNil]];
  XCTAssertEqualObjects([matcher name], @"ancestorThatMatches");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForDescendant:[GREYMatchers matcherForNil]];
  XCTAssertEqualObjects([matcher name], @"descendantThatMatches");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForButtonTitle:@""];
  XCTAssertEqualObjects([matcher name], @"buttonTitle");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForScrollViewContentOffset:CGPointZero];
  XCTAssertEqualObjects([matcher name], @"contentOffset");
  matcher =
      (GREYBaseMatcher *)[GREYMatchers matcherForSliderValueMatcher:[GREYMatchers matcherForNil]];
  XCTAssertEqualObjects([matcher name], @"sliderValueMatches");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForStepperValue:2.0f];
  XCTAssertEqualObjects([matcher name], @"stepperValue");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForPickerColumn:1 setToValue:@"1"];
  XCTAssertEqualObjects([matcher name], @"pickerColumnAtIndex");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForDatePickerValue:[NSDate date]];
  XCTAssertEqualObjects([matcher name], @"datePickerWithValue");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForEnabledElement];
  XCTAssertEqualObjects([matcher name], @"enabled");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForSelectedElement];
  XCTAssertEqualObjects([matcher name], @"selected");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForUserInteractionEnabled];
  XCTAssertEqualObjects([matcher name], @"userInteractionEnabled");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForConstraints:@[]
                                        toReferenceElementMatching:[GREYMatchers matcherForNil]];
  XCTAssertEqualObjects([matcher name], @"layoutWithConstraints");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForNil];
  XCTAssertEqualObjects([matcher name], @"isNil");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForNotNil];
  XCTAssertEqualObjects([matcher name], @"isNotNil");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForSwitchWithOnState:NO];
  XCTAssertEqualObjects([matcher name], @"switchInState");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForScrolledToContentEdge:kGREYContentEdgeTop];
  XCTAssertEqualObjects([matcher name], @"scrolledToContentEdge");
  matcher = (GREYBaseMatcher *)[GREYMatchers matcherForTextFieldValue:@""];
  XCTAssertEqualObjects([matcher name], @"textFieldValue");
}

@end
