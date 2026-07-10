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

#import "XCTestCase+GREYTest.h"

#import <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <pthread.h>

#import "GREYFatalAsserts.h"
#import "GREYTestApplicationDistantObject+Private.h"
#import "GREYTestApplicationDistantObject.h"
#import "GREYError.h"
#import "GREYLogger.h"
#import "GREYSwizzler.h"
#import "GREYFailureScreenshotSaver.h"
#import "GREYTestCaseInvocation.h"

/**
 * Stack of XCTestCase objects being being executed. This enables the tracking of different nested
 * tests that have been invoked. If empty, then the run is outside the context of a running test.
 */
static NSMutableArray<XCTestCase *> *gExecutingTestCaseStack;
static NSMutableSet<NSString *> *gSwizzledClasses;
static pthread_mutex_t gSwizzledClassesMutex = PTHREAD_MUTEX_INITIALIZER;

static void *const kGREYSetUpRunKey = (void *)&kGREYSetUpRunKey;
static void *const kGREYTearDownRunKey = (void *)&kGREYTearDownRunKey;

/** Block which will be called when EarlGrey detects that the app-under-test has crashed. */
static void (^gHostApplicationCrashHandler)(void);

/** The port number of the last app-under-test which has crashed. */
static uint16_t gHostApplicationPortForLastCrash;

/** The failure count within a test case. */
static NSUInteger gFailureCount;

// Extern constants.
NSString *const kGREYXCTestCaseInstanceWillSetUp = @"GREYXCTestCaseInstanceWillSetUp";
NSString *const kGREYXCTestCaseInstanceDidSetUp = @"GREYXCTestCaseInstanceDidSetUp";
NSString *const kGREYXCTestCaseInstanceWillTearDown = @"GREYXCTestCaseInstanceWillTearDown";
NSString *const kGREYXCTestCaseInstanceDidTearDown = @"GREYXCTestCaseInstanceDidTearDown";
NSString *const kGREYXCTestCaseInstanceDidPass = @"GREYXCTestCaseInstanceDidPass";
NSString *const kGREYXCTestCaseInstanceDidFail = @"GREYXCTestCaseInstanceDidFail";
NSString *const kGREYXCTestCaseInstanceDidFinish = @"GREYXCTestCaseInstanceDidFinish";
NSString *const kGREYXCTestCaseNotificationKey = @"GREYXCTestCaseNotificationKey";

/**
 * Checks if there's an app-under-test crash which hasn't been handled yet. If that's the case,
 * @c handler will be invoked. @c handler can indicate that the crash has been handled by returning
 * @c YES. If @c NO is returned by @c handler, the next invocation to this method will again invoke
 * the passed in @c handler to handle the crash.
 *
 * @param handler The block that will be invoked when there is an unhandled app-under-test crash.
 */
static void CheckUnhandledHostApplicationCrashWithHandler(BOOL (^handler)(void));

@implementation XCTestCase (GREYTest)

+ (void)load {
  // Extra check added in case an app might be built on Xcode 12, but running on a lower Xcode.
  GREYSwizzler *swizzler = [[GREYSwizzler alloc] init];
  BOOL swizzleSuccess = [swizzler swizzleClass:self
                         replaceInstanceMethod:@selector(invokeTest)
                                    withMethod:@selector(grey_invokeTest)];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCTestCase::invokeTest");

  SEL recordFailureSelector = @selector(recordIssue:);
  SEL swizzledRecordFailureSelector = @selector(grey_recordIssue:);
  swizzleSuccess = [swizzler swizzleClass:self
                    replaceInstanceMethod:recordFailureSelector
                               withMethod:swizzledRecordFailureSelector];
  GREYFatalAssertWithMessage(swizzleSuccess, @"Cannot swizzle XCTestCase::%@",
                             NSStringFromSelector(recordFailureSelector));
  gExecutingTestCaseStack = [[NSMutableArray alloc] init];
  gSwizzledClasses = [[NSMutableSet alloc] init];
}

+ (void)grey_setHostApplicationCrashHandler:(nullable void (^)(void))hostApplicationCrashHandler {
  GREYFatalAssertWithMessage([NSThread isMainThread],
                             @"You must set the crash handler on main thread.");
  CheckUnhandledHostApplicationCrashWithHandler(^{
    GREYLog(
        @"WARNING: The crash handler is overridden right after the crash of app-under-test. This "
        @"may cause the crash being handled in an unexpected way.");
    return NO;
  });
  gHostApplicationCrashHandler = hostApplicationCrashHandler;
}

+ (XCTestCase *)grey_currentTestCase {
  return [gExecutingTestCaseStack lastObject];
}

- (void)grey_recordIssue:(XCTIssue *)issue {
  [self grey_setStatus:kGREYXCTestCaseStatusFailed];
  INVOKE_ORIGINAL_IMP1(void, @selector(grey_recordIssue:), issue);
}

- (void)grey_recordFailureWithDescription:(NSString *)description
                                   inFile:(NSString *)filePath
                                   atLine:(NSUInteger)lineNumber
                                 expected:(BOOL)expected {
  [self grey_setStatus:kGREYXCTestCaseStatusFailed];
  INVOKE_ORIGINAL_IMP4(void, @selector(grey_recordFailureWithDescription:inFile:atLine:expected:),
                       description, filePath, lineNumber, expected);
}

- (NSString *)grey_testMethodName {
  // XCTest.name is represented as "-[<testClassName> <testMethodName>]"
  NSCharacterSet *charsetToStrip =
      [NSMutableCharacterSet characterSetWithCharactersInString:@"-[]"];

  // Resulting string after stripping: <testClassName> <testMethodName>
  NSString *strippedName = [self.name stringByTrimmingCharactersInSet:charsetToStrip];
  // Split string by whitespace.
  NSArray<NSString *> *testClassAndTestMethods =
      [strippedName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  // Test method name will be 2nd item in the array.
  if (testClassAndTestMethods.count <= 1) {
    return nil;
  } else {
    return [testClassAndTestMethods objectAtIndex:1];
  }
}

- (NSString *)grey_testClassName {
  return NSStringFromClass([self class]);
}

- (GREYXCTestCaseStatus)grey_status {
  id status = objc_getAssociatedObject(self, @selector(grey_status));
  return (GREYXCTestCaseStatus)[status unsignedIntegerValue];
}

- (void)grey_markAsFailedAtLine:(NSUInteger)line
                         inFile:(NSString *)file
                    description:(NSString *)description {
  // If the test fails outside of the main thread in a nested runloop, it will not be interrupted
  // until it's back in the outer most runloop. _XCTFailureHandler will mark the test as failed
  // and interrupt the runloop.
  _XCTFailureHandler(self, NO, file.UTF8String, line, @"Immediately halt execution of testcase",
                     @"%@", description);
}

#pragma mark - Private

- (BOOL)grey_isSwizzled {
  NSString *className = NSStringFromClass([self class]);
  BOOL swizzled = NO;
  int lock = pthread_mutex_lock(&gSwizzledClassesMutex);
  GREYFatalAssertWithMessage(lock == 0, @"Failed to lock gSwizzledClassesMutex.");
  swizzled = [gSwizzledClasses containsObject:className];
  int unlock = pthread_mutex_unlock(&gSwizzledClassesMutex);
  GREYFatalAssertWithMessage(unlock == 0, @"Failed to unlock gSwizzledClassesMutex.");
  NSLog(@"[Jetski] grey_isSwizzled for class %@: %d", className, swizzled);
  return swizzled;
}

- (void)grey_markSwizzled {
  NSString *className = NSStringFromClass([self class]);
  int lock = pthread_mutex_lock(&gSwizzledClassesMutex);
  GREYFatalAssertWithMessage(lock == 0, @"Failed to lock gSwizzledClassesMutex.");
  [gSwizzledClasses addObject:className];
  int unlock = pthread_mutex_unlock(&gSwizzledClassesMutex);
  GREYFatalAssertWithMessage(unlock == 0, @"Failed to unlock gSwizzledClassesMutex.");
}

- (void)grey_invokeTest {
  self.continueAfterFailure = YES;
  @autoreleasepool {
    if (![self grey_isSwizzled]) {
      Class selfClass = [self class];

      // Swizzle setUp
      {
        SEL selector = @selector(setUp);
        Method method = class_getInstanceMethod(selfClass, selector);
        if (method) {
          IMP originalIMP = method_getImplementation(method);
          id block = ^(XCTestCase *testCase) {
            BOOL wasOutermost = NO;
            if (!objc_getAssociatedObject(testCase, kGREYSetUpRunKey)) {
              objc_setAssociatedObject(testCase, kGREYSetUpRunKey, @(YES), OBJC_ASSOCIATION_RETAIN);
              wasOutermost = YES;
              gFailureCount = testCase.testRun.failureCount;
              [testCase grey_sendNotification:kGREYXCTestCaseInstanceWillSetUp];
              CheckUnhandledHostApplicationCrashWithHandler(^{
                if (gHostApplicationCrashHandler) {
                  gHostApplicationCrashHandler();
                }
                return YES;
              });
            }

            if (originalIMP) {
              ((void (*)(id, SEL))originalIMP)(testCase, selector);
            }

            if (wasOutermost) {
              [testCase grey_sendNotification:kGREYXCTestCaseInstanceDidSetUp];
              objc_setAssociatedObject(testCase, kGREYSetUpRunKey, nil, OBJC_ASSOCIATION_RETAIN);
            }
          };
          IMP newIMP = imp_implementationWithBlock(block);
          class_replaceMethod(selfClass, selector, newIMP, method_getTypeEncoding(method));
        }
      }

      // Swizzle tearDown
      {
        SEL selector = @selector(tearDown);
        Method method = class_getInstanceMethod(selfClass, selector);
        if (method) {
          IMP originalIMP = method_getImplementation(method);
          id block = ^(XCTestCase *testCase) {
            BOOL wasOutermost = NO;
            if (!objc_getAssociatedObject(testCase, kGREYTearDownRunKey)) {
              objc_setAssociatedObject(testCase, kGREYTearDownRunKey, @(YES),
                                       OBJC_ASSOCIATION_RETAIN);
              wasOutermost = YES;
              [testCase saveXCUITestRelatedScreenshot];
              [testCase grey_sendNotification:kGREYXCTestCaseInstanceWillTearDown];
              CheckUnhandledHostApplicationCrashWithHandler(^{
                if (gHostApplicationCrashHandler) {
                  gHostApplicationCrashHandler();
                }
                return YES;
              });
            }

            if (originalIMP) {
              ((void (*)(id, SEL))originalIMP)(testCase, selector);
            }

            if (wasOutermost) {
              [testCase grey_sendNotification:kGREYXCTestCaseInstanceDidTearDown];
              objc_setAssociatedObject(testCase, kGREYTearDownRunKey, nil, OBJC_ASSOCIATION_RETAIN);
            }
          };
          IMP newIMP = imp_implementationWithBlock(block);
          class_replaceMethod(selfClass, selector, newIMP, method_getTypeEncoding(method));
        }
      }

      // Swizzle tearDownWithCompletionHandler:
      {
        SEL selector = @selector(tearDownWithCompletionHandler:);
        Method method = class_getInstanceMethod(selfClass, selector);
        if (method) {
          IMP originalIMP = method_getImplementation(method);
          id block = ^(XCTestCase *testCase, void (^completion)(NSError *)) {
            BOOL wasOutermost = NO;
            if (!objc_getAssociatedObject(testCase, kGREYTearDownRunKey)) {
              objc_setAssociatedObject(testCase, kGREYTearDownRunKey, @(YES),
                                       OBJC_ASSOCIATION_RETAIN);
              wasOutermost = YES;
              [testCase saveXCUITestRelatedScreenshot];
              [testCase grey_sendNotification:kGREYXCTestCaseInstanceWillTearDown];
              CheckUnhandledHostApplicationCrashWithHandler(^{
                if (gHostApplicationCrashHandler) {
                  gHostApplicationCrashHandler();
                }
                return YES;
              });
            }

            if (wasOutermost) {
              __weak __typeof__(testCase) weakTestCase = testCase;
              void (^interceptedCompletion)(NSError *) = ^(NSError *error) {
                __typeof__(testCase) strongTestCase = weakTestCase;
                if (strongTestCase) {
                  completion(error);
                  [strongTestCase grey_sendNotification:kGREYXCTestCaseInstanceDidTearDown];
                  objc_setAssociatedObject(strongTestCase, kGREYTearDownRunKey, nil,
                                           OBJC_ASSOCIATION_RETAIN);
                }
              };
              if (originalIMP) {
                ((void (*)(id, SEL, void (^)(NSError *)))originalIMP)(testCase, selector,
                                                                      interceptedCompletion);
              } else {
                interceptedCompletion(nil);
              }
            } else {
              if (originalIMP) {
                ((void (*)(id, SEL, void (^)(NSError *)))originalIMP)(testCase, selector,
                                                                      completion);
              } else {
                completion(nil);
              }
            }
          };
          IMP newIMP = imp_implementationWithBlock(block);
          class_replaceMethod(selfClass, selector, newIMP, method_getTypeEncoding(method));
        }
      }
      [self grey_markSwizzled];
    }

    // Change invocation type to GREYTestCaseInvocation to set grey_status to failed if the test
    // method throws an exception. This ensure grey_status is accurate in the test case teardown.
    Class originalInvocationClass = nil;
    if (@available(iOS 15.0, *)) {
      // Pointer authentication will be enforced and cause a crash here, and this will be handled
      // by recordIssue: on latest runtimes.
    } else {
      originalInvocationClass = object_setClass(self.invocation, [GREYTestCaseInvocation class]);
    }

    @try {
      [gExecutingTestCaseStack addObject:self];
      [self grey_setStatus:kGREYXCTestCaseStatusUnknown];
      INVOKE_ORIGINAL_IMP(void, @selector(grey_invokeTest));

      // The test may have been marked as failed if a failure was recorded with the
      // recordFailureWithDescription:... method. In this case, we can't consider the test has
      // passed.
      if ([self grey_status] != kGREYXCTestCaseStatusFailed) {
        [self grey_setStatus:kGREYXCTestCaseStatusPassed];
      }
    } @catch (NSException *exception) {
      [self grey_setStatus:kGREYXCTestCaseStatusFailed];
      @throw;  // NOLINT
    } @finally {
      switch ([self grey_status]) {
        case kGREYXCTestCaseStatusFailed:
          [self grey_sendNotification:kGREYXCTestCaseInstanceDidFail];
          break;
        case kGREYXCTestCaseStatusPassed:
          [self grey_sendNotification:kGREYXCTestCaseInstanceDidPass];
          break;
        case kGREYXCTestCaseStatusUnknown:
          self.continueAfterFailure = YES;
          [self grey_recordFailure:@__FILE__
                              line:__LINE__
                       description:@"Test has finished with unknown status."];
          break;
      }
      // Reset to the original class on iOS 14 and prior.
      if (originalInvocationClass != nil) {
        object_setClass(self.invocation, originalInvocationClass);
      }
      [self grey_sendNotification:kGREYXCTestCaseInstanceDidFinish];
      // We only reset the current test case after all possible notifications have been sent.
      [gExecutingTestCaseStack removeLastObject];
    }
  }
}



/**
 * Saves an XCUITest screenshot when there's an XCTest failure. Will not be hit if it's just an
 * EarlGrey failure. The image is saved at a separate location (since the exception is null) and
 * will not overwrite an EarlGrey screenshot.
 */
- (void)saveXCUITestRelatedScreenshot {
  // XCTestRun failureCount will not change if there is an EarlGrey failure but only if an XCUITest
  // failure happens. In this case, add a test-side screenshot.
  if (self.testRun.failureCount > gFailureCount) {
    XCUIApplication *application = [[XCUIApplication alloc] init];
    if (application.state == XCUIApplicationStateRunningForeground) {
      XCUIScreenshot *screenshot = [XCUIScreen mainScreen].screenshot;
      NSString *screenshotDir = [GREYFailureScreenshotSaver failureScreenshotPathForException:nil];
      NSDictionary<NSString *, UIImage *> *screenshotDict =
          @{kGREYTestScreenshotAtFailure : screenshot.image};
      GREYFailureScreenshots *screenshotPaths =
          [GREYFailureScreenshotSaver saveFailureScreenshotsInDictionary:screenshotDict
                                                             toDirectory:screenshotDir];
      GREYLog(@"Screenshot Saved: %@ : %@", kGREYTestScreenshotAtFailure,
              screenshotPaths[kGREYTestScreenshotAtFailure]);
    }
  }
}

/**
 * Posts a notification with the specified @c notificationName using the default
 * NSNotificationCenter and with the @c userInfo containing the current test case.
 *
 * @param notificationName Name of the notification to be posted.
 */
- (void)grey_sendNotification:(NSString *)notificationName {
  NSDictionary<NSString *, id> *userInfo = @{kGREYXCTestCaseNotificationKey : self};
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                      object:self
                                                    userInfo:userInfo];
}

#pragma mark - Package Internal

- (void)grey_setStatus:(GREYXCTestCaseStatus)status {
  objc_setAssociatedObject(self, @selector(grey_status), @(status),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 * Calls the XCTest record methods for recording a failure in the execution of a test.
 *
 * @param filePath    Name of the file which contains the failure.
 * @param line        Line number in the @c filePath where the failure occurred.
 * @param description Full description of the failure. Utilized as compactDescription in iOS 14+.
 */
- (void)grey_recordFailure:(NSString *)filePath
                      line:(NSUInteger)line
               description:(NSString *)description {
  XCTSourceCodeLocation *location =
      [[XCTSourceCodeLocation alloc] initWithFilePath:filePath lineNumber:(NSInteger)line];
  XCTSourceCodeContext *context = [[XCTSourceCodeContext alloc] initWithLocation:location];
  XCTIssue *issue = [[XCTIssue alloc] initWithType:XCTIssueTypeUncaughtException
                                compactDescription:description
                               detailedDescription:nil
                                 sourceCodeContext:context
                                   associatedError:nil
                                       attachments:@[]];
  [self recordIssue:issue];
}

@end

static void CheckUnhandledHostApplicationCrashWithHandler(BOOL (^handler)(void)) {
  GREYFatalAssertWithMessage([NSThread isMainThread],
                             @"Application crash should be checked on main thread.");
  GREYTestApplicationDistantObject *testDistantObject =
      GREYTestApplicationDistantObject.sharedInstance;
  if (testDistantObject.hostApplicationStopped) {
    // testDistantObject.hostPort won't be 0 if testDistantObject.hostApplicationStopped is true.
    uint16_t currentHostPort = testDistantObject.hostPort;
    if (currentHostPort != gHostApplicationPortForLastCrash) {
      if (handler()) {
        gHostApplicationPortForLastCrash = currentHostPort;
      }
    }
  }
}
