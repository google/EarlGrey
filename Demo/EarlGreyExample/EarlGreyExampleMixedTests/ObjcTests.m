#import <XCTest/XCTest.h>

@import EarlGrey;

@interface PrintOnlyHandler : NSObject<GREYFailureHandler>
@end

@implementation PrintOnlyHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
    NSLog(@"Test Failed With Reason : %@ and details : %@", [exception reason], details);
}
@end

@interface EarlGreyExampleTests : XCTestCase
@end

@implementation EarlGreyExampleTests
- (void)testWithCustomFailureHandler {
    // This test will fail and use our custom handler to handle the failure.
    // The custom handler is defined at the beginning of this file.
    PrintOnlyHandler *myHandler = [[PrintOnlyHandler alloc] init];
    [EarlGrey setFailureHandler:myHandler];
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TapMe")]
     performAction:(grey_tap())];
}

- (void)testLayout {
    // Define a layout constraint.
    GREYLayoutConstraint *onTheRight =
    [GREYLayoutConstraint layoutConstraintWithAttribute:kGREYLayoutAttributeLeft
                                              relatedBy:kGREYLayoutRelationGreaterThanOrEqual
                                   toReferenceAttribute:kGREYLayoutAttributeRight
                                             multiplier:1.0
                                               constant:0.0];

    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"SendForLayoutTest")]
     assertWithMatcher:grey_layout(@[onTheRight], grey_accessibilityID(@"ClickMe"))];
}

- (void)testWithCondition {
    GREYCondition *myCondition = [GREYCondition conditionWithName: @"Example condition" block: ^BOOL {
        int i = 1;
        while (i <= 100000) {
            i++;
        }
        return YES;
    }];
    // Wait for my condition to be satisfied or timeout after 5 seconds.
    BOOL success = [myCondition waitWithTimeout:5];
    if (!success) {
        // Just printing for the example.
        NSLog(@"Condition not met");
    } else {
        [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"ClickMe")]
         performAction:grey_tap()];
    }
}
@end
