//
// Copyright 2018 Google Inc.
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
#import <Foundation/Foundation.h>

/** The dummy test class to test the class methods without forwarding alloc. */
@interface EDOTestClassDummy : NSObject

@property(readonly) int value;

- (instancetype)initWithValue:(int)value;

/**
 *  A method with the alloc prefix belonging to the alloc family.
 *  http://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families
 */
+ (instancetype)allocDummy;

/**
 *  A method with the leading underscore belonging to the alloc family.
 *
 *  This method begins with an underscore so that tests can verify behavior of methods in the alloc
 *  family that begin with leading underscores:
 *  "A selector is in a certain selector family if, ignoring any leading underscores, the first
 *  component of the selector either consists entirely of the name of the method family or it begins
 *  with that name followed by a character other than a lowercase letter."
 *  http://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families
 */
+ (instancetype)_allocDummy;

/**
 *  A method that has the alloc prefix but followed by a lower case that
 *  doesn't belong to the alloc family.
 *  http://clang.llvm.org/docs/AutomaticReferenceCounting.html#method-families
 */
+ (instancetype)allocateDummy;

+ (int)classMethodWithInt:(int)value;
+ (EDOTestClassDummy *)classMethodWithIdReturn:(int)value;

@end
