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

#import "CommonLib/Additions/NSObject+GREYCommon.h"
#import "third_party/objective_c/ocmock/v3/Source/OCMock/OCMock.h"

@interface NSObject_GREYCommonAdditionsTest : XCTestCase
@end

@implementation NSObject_GREYCommonAdditionsTest

- (void)testViewContainingSelfReturnsSuperViewForUIViews {
  UIView *aSubView = [[UIView alloc] init];
  UIView *aView = [[UIView alloc] init];
  [aView addSubview:aSubView];
  XCTAssertEqualObjects([aSubView grey_viewContainingSelf], aView);
}

- (void)testViewContainingSelfReturnsAccessibilityContainerForNonUIViews {
  UIView *containersContainer = [[UIView alloc] init];
  UIAccessibilityElement *container =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:containersContainer];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:container];

  // Set up heirarchy: containersContainer -> container -> element
  element.accessibilityContainer = container;
  container.accessibilityContainer = containersContainer;
  XCTAssertEqualObjects([element grey_viewContainingSelf], containersContainer);
}

- (void)testViewContainingSelfReturnsWebViewForWebAccessibilityObjectWrapper {
  id webAccessibilityWrapper = [[NSClassFromString(@"WebAccessibilityObjectWrapper") alloc] init];
  id element = [OCMockObject partialMockForObject:webAccessibilityWrapper];
  id viewContainer = [OCMockObject mockForClass:NSClassFromString(@"UIView")];
  UIAccessibilityElement *container =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewContainer];
  id webViewContainer = [OCMockObject mockForClass:NSClassFromString(@"UIWebView")];

  // Set up heirarchy: webViewContainer -> viewContainer -> container -> element
  [[[element stub] andReturn:container] grey_container];
  [[[viewContainer stub] andReturn:webViewContainer] grey_container];
  [[[webViewContainer stub] andReturn:nil] grey_container];

  XCTAssertEqualObjects([element grey_viewContainingSelf], webViewContainer);
}

- (void)testNilValuesNotShownInDescription {
  // This test makes sure that no nil attributes show up
  UILabel *label = [[UILabel alloc] init];
  label.isAccessibilityElement = YES;
  label.accessibilityIdentifier = nil;
  label.accessibilityLabel = nil;
  label.accessibilityTraits = UIAccessibilityTraitStaticText;
  label.text = nil;
  label.frame = CGRectZero;
  label.opaque = YES;
  label.hidden = YES;
  label.alpha = 0.0;
  NSString *expectedDescription = [NSString
      stringWithFormat:@"<UILabel:%p; isAccessible=Y; "
                       @"AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
                       @"AX.traits='UIAccessibilityTraitStaticText'; AX.focused='N'; "
                       @"frame={{0, 0}, {0, 0}}; opaque; hidden; alpha=0; UIE=N; text=''>",
                       label];
  XCTAssertEqualObjects(expectedDescription, [label grey_description]);
}

- (void)testNonNilValuesShownInDescription {
  // This test makes sure that all instantiated attributes show up correctly
  UILabel *labelWithNonNilFeatures = [[UILabel alloc] init];
  labelWithNonNilFeatures.accessibilityIdentifier = @"Identifier";
  labelWithNonNilFeatures.accessibilityLabel = @"LabelWithNonNilFeatures";
  labelWithNonNilFeatures.accessibilityFrame = CGRectMake(1, 2, 3, 4);
  labelWithNonNilFeatures.accessibilityTraits = UIAccessibilityTraitStaticText;
  labelWithNonNilFeatures.text = @"SampleText";
  labelWithNonNilFeatures.frame = CGRectMake(3, 3, 3, 3);
  labelWithNonNilFeatures.opaque = NO;
  labelWithNonNilFeatures.hidden = NO;
  labelWithNonNilFeatures.userInteractionEnabled = YES;
  labelWithNonNilFeatures.alpha = 0.50;
  labelWithNonNilFeatures.isAccessibilityElement = YES;
  NSString *expectedDescription = [NSString
      stringWithFormat:
          @"<UILabel:%p; isAccessible=Y; "
          @"AX.id='Identifier'; AX.label='LabelWithNonNilFeatures'; "
          @"AX.frame={{1, 2}, {3, 4}}; AX.activationPoint={2.5, 4}; "
          @"AX.traits='UIAccessibilityTraitStaticText'; AX.focused='N'; frame={{3, 3}, {3, 3}}; "
          @"alpha=0.5; text='SampleText'>",
          labelWithNonNilFeatures];
  XCTAssertEqualObjects(expectedDescription, [labelWithNonNilFeatures grey_description]);
}

- (void)testAccessibilityIdentifierIsShownForNonAccessibilityElements {
  UITextField *view = [[UITextField alloc] init];
  view.isAccessibilityElement = NO;
  view.accessibilityIdentifier = @"test.acc.id";
  view.accessibilityLabel = nil;
  view.frame = CGRectZero;
  view.opaque = YES;
  view.hidden = YES;
  view.userInteractionEnabled = YES;
  view.alpha = 0;
  view.enabled = NO;
  view.accessibilityTraits = UIAccessibilityTraitNotEnabled || UIAccessibilityTraitButton;
  NSString *expectedDescription =
      [NSString stringWithFormat:
                    @"<UITextField:%p; isAccessible=N; "
                    @"AX.id='test.acc.id'; AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
                    @"AX.traits='UIAccessibilityTraitButton'; AX.focused='N'; "
                    @"frame={{0, 0}, {0, 0}}; opaque; hidden; alpha=0; disabled; text=''>",
                    view];
  XCTAssertEqualObjects(expectedDescription, [view grey_description]);
}

- (void)testShortDescriptionWithNoAXIdAndLabel {
  UITextField *view = [[UITextField alloc] init];
  NSString *expectedDescription = @"UITextField";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAxId {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityIdentifier = @"viewAxId";
  NSString *expectedDescription = @"UITextField; AX.id='viewAxId'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAXLabel {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityLabel = @"viewAxLabel";
  NSString *expectedDescription = @"UITextField; AX.label='viewAxLabel'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testShortDescriptionWithAXIdAndLabel {
  UITextField *view = [[UITextField alloc] init];
  view.accessibilityIdentifier = @"viewAxId";
  view.accessibilityLabel = @"viewAxLabel";
  NSString *expectedDescription = @"UITextField; AX.id='viewAxId'; AX.label='viewAxLabel'";
  XCTAssertEqualObjects([view grey_shortDescription], expectedDescription);
}

- (void)testObjectDescriptionWithView {
  UIView *view = [[UIView alloc] init];
  view.accessibilityIdentifier = @"viewAxId";
  view.accessibilityLabel = @"viewAxLabel";
  NSString *viewObjectDescription =
      [[NSString alloc] initWithFormat:@"<%@: %p>", [view class], view];
  XCTAssertEqualObjects(viewObjectDescription, [view grey_objectDescription]);
}

@end
