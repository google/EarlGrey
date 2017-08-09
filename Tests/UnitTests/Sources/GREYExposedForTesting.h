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

//
// Exposes methods, classes and globals for Unit Testing.
//
#import <EarlGrey/GREYAnalytics.h>
#import <EarlGrey/GREYAppStateTracker.h>
#import <EarlGrey/GREYAppStateTrackerObject.h>
#import <EarlGrey/GREYElementHierarchy.h>
#import <EarlGrey/GREYManagedObjectContextIdlingResource.h>
#import <EarlGrey/GREYProvider.h>
#import <EarlGrey/GREYTimedIdlingResource.h>
#import <EarlGrey/GREYTraversal.h>
#import <EarlGrey/GREYTraversalDFS.h>
#import <EarlGrey/GREYUIThreadExecutor.h>
#import <EarlGrey/GREYVisibilityChecker.h>
#import <EarlGrey/UIView+GREYAdditions.h>

// Indicates the minimum scroll length required for any scroll to be detected, currently defined in
// GREYPathGestureUtils.m.
extern const NSInteger kGREYScrollDetectionLength;

@interface NSObject (GREYExposedForTesting)
- (BOOL)grey_isWebAccessibilityElement;
@end

@interface GREYAnalytics (GREYExposedForTesting)
- (void)grey_testCaseInstanceDidTearDown;
@end

@interface GREYAppStateTracker (GREYExposedForTesting)
- (GREYAppState)grey_lastKnownStateForObject:(id)object;
@end

@interface GREYManagedObjectContextIdlingResource (GREYExposedForTesting)
- (dispatch_queue_t)managedObjectContextDispatchQueue;
@end

@interface GREYUIThreadExecutor (GREYExposedForTesting)
@property(nonatomic, assign) BOOL forceBusyPolling;
- (BOOL)grey_areAllResourcesIdle;
- (void)grey_resetIdlingResources;
- (BOOL)grey_isTrackingIdlingResource:(id<GREYIdlingResource>)idlingResource;
@end

@interface CALayer (GREYExposedForTesting)
- (NSMutableSet *)grey_pausedAnimationKeys;
@end

@interface CAAnimation (GREYExposedForTesting)
- (void)grey_trackForDurationOfAnimation;
@end

@interface GREYVisibilityChecker (GREYExposedForTesting)
+ (GREYVisiblePixelData)grey_countPixelsInImage:(CGImageRef)afterImage
                    thatAreShiftedPixelsOfImage:(CGImageRef)beforeImage
                    storeVisiblePixelRectInRect:(CGRect *)outVisiblePixelRect
               andStoreComparisonResultInBuffer:(GREYVisibilityDiffBuffer *)outDiffBufferOrNULL;
@end

@interface GREYElementHierarchy (GREYExposedForTesting)
+ (NSString *)grey_printDescriptionForElement:(id)element
                                    atLevel:(NSUInteger)level;
+ (NSString *)grey_hierarchyString:(id)element
                      outputString:(NSMutableString *)outputString
           andAnnotationDictionary:(NSDictionary *)annotationDictionary;
@end

@interface GREYTraversal (GREYExposedForTesting)
- (instancetype)init;
- (NSArray *)exploreImmediateChildren:(id)element;
@end
