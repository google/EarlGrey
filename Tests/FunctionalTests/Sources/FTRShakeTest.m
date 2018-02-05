//
//  FTRShakeTest.m
//  EarlGreyFunctionalTests
//
//  Created by Leo Natan (Wix) on 2/5/18.
//  Copyright © 2018 Google Inc. All rights reserved.
//

#import "FTRBaseIntegrationTest.h"

@interface FTRShakeTest : FTRBaseIntegrationTest

@end

@implementation FTRShakeTest

- (void)setUp {
	[super setUp];
	[self openTestViewNamed:@"Rotated Views"];
}

- (void)testDeviceShake {
	// Test rotating to landscape.
	[EarlGrey shakeDeviceWithErrorOrNil:nil];
	[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"lastTapped")]
	 assertWithMatcher:grey_text([NSString stringWithFormat:@"Device Was Shaken"])];
}

@end
