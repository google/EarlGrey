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

#import "GREYActionBlock.h"

#import "GREYThrowDefines.h"

@implementation GREYActionBlock {
  GREYPerformBlock _performBlock;
  /**
   * Identifier used for diagnostics.
   */
  NSString *_diagnosticsID;
  /**
   * Whether or not the action block should run on main thread right after matching the element.
   * See details in GREYAction.h.
   */
  BOOL _shouldRunOnMainThread;
}

+ (instancetype)actionWithName:(NSString *)name performBlock:(GREYPerformBlock)block {
  return [GREYActionBlock actionWithName:name constraints:nil performBlock:block];
}

+ (instancetype)actionWithName:(NSString *)name
                   constraints:(id<GREYMatcher>)constraints
                  performBlock:(GREYPerformBlock)block {
  return [[GREYActionBlock alloc] initWithName:name constraints:constraints performBlock:block];
}

- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints
                performBlock:(GREYPerformBlock)block {
  return [self initWithName:name constraints:constraints onMainThread:YES performBlock:block];
}

- (instancetype)initWithName:(NSString *)name
                 constraints:(id<GREYMatcher>)constraints
                onMainThread:(BOOL)shouldRunOnMainThread
                performBlock:(GREYPerformBlock)block {
  GREYThrowOnNilParameter(block);

  self = [super initWithName:name constraints:constraints];
  if (self) {
    _performBlock = [block copy];
    _shouldRunOnMainThread = shouldRunOnMainThread;
  }
  return self;
}

#pragma mark - Private

+ (instancetype)actionWithName:(NSString *)name
                 diagnosticsID:(NSString *)diagnosticsID
                   constraints:(__nullable id<GREYMatcher>)constraints
                  onMainThread:(BOOL)shouldRunOnMainThread
                  performBlock:(GREYPerformBlock)block {
  return [[GREYActionBlock alloc] initWithName:name
                                 diagnosticsID:diagnosticsID
                                   constraints:constraints
                                  onMainThread:shouldRunOnMainThread
                                  performBlock:block];
}

- (instancetype)initWithName:(NSString *)name
               diagnosticsID:(NSString *)diagnosticsID
                 constraints:(id<GREYMatcher>)constraints
                onMainThread:(BOOL)shouldRunOnMainThread
                performBlock:(GREYPerformBlock)block {
  self = [self initWithName:name
                constraints:constraints
               onMainThread:shouldRunOnMainThread
               performBlock:block];
  if (self) {
    _diagnosticsID = diagnosticsID;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:element error:errorOrNil]) {
    return NO;
  }
  // Perform actual action.
  return _performBlock(element, errorOrNil);
}

- (BOOL)shouldRunOnMainThread {
  return _shouldRunOnMainThread;
}

#pragma mark - GREYDiagnosable

- (NSString *)diagnosticsID {
  return _diagnosticsID;
}

@end
