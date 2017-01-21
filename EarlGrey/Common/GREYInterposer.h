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

#import <Foundation/Foundation.h>

/**
 *  dyld_interpose_tuple must store exactly 2 pointers to be interchangeable with tuples in dyld.
 *  The structure is defined here:
 *  http://opensource.apple.com//source/dyld/dyld-360.22/include/mach-o/dyld-interposing.h
 */
typedef struct {
  void *_replacement; // Symbol that will replace @c _replacee.
  void *_replacee;    // Symbol to replace.
} dyld_interpose_tuple;

/**
 *  GREYInterposer safely interposes symbols with dyld_dynamic_interpose and performs a number of
 *  sanity checks to ensure that there are no conflicts with other libraries which are interposing.
 *
 *  Overview of DYLD interpose:
 *
 *  DYLD has built-in functionality for overriding C functions called interposing. There are 2
 *  kinds of interposing: static and dynamic.
 *
 *  Static interpose is a pair of pointers stored in a special section of the Mach-O __DATA segment,
 *  named __interpose. If a library inserted with DYLD_INSERT_LIBRARIES has this section, DYLD will
 *  bind the symbols so that every library except for the library with this interpose section will
 *  have symbols bound to point to the replacement function. Beginning with iOS 9 and OS X 10.11,
 *  even libraries which were dynamically linked against a binary will be used for interposing.
 *
 *  Dynamic interpose is a private API in DYLD which will rebind symbols for a specific binary
 *  during runtime. It must be used with care to avoid interpose conflicts and race conditions.
 *
 *  What GREYInterposer does:
 *
 *  1. We parse all DYLD images to look for static interpose sections and use that information
 *     to perform the requested dynamic interposes correctly.
 *  2. We perform a number of sanity checks to ensure that there are no conflicts.
 *  3. If a symbol is statically interposed by EarlGrey, we perform a dynamic interpose for EarlGrey
 *     binary so that even calls from within EarlGrey to the interposed function are interposed.
 *  4. If a symbol is statically interposed by another library, such as Address Sanitizer, we
 *     dynamically interpose it in that library so that it will call through to EarlGrey.
 *  5. If a symbol is not statically interposed, we will dynamically interpose it in all binaries.
 *  6. A bug in 64-bit iOS 8.x simulator is fixed at runtime by patching assembly code in memory.
 *
 *  Guidelines for using GREYInterposer:
 *
 *  1. If EarlGrey is a dynamic library, it should be inserted using DYLD_INSERT_LIBRARIES.
 *  2. If EarlGrey is a static library, it should be linked with the main executable or test plugin.
 *  3. For a given symbol, a static interpose inside EarlGrey is recommended, but not required, if
 *     that symbol is not statically interposed by another library. It is forbidden if another
 *     library is statically interposing that symbol. If a conflict is detected, GREYInterposer
 *     should report the error and fail.
 *  4. Commit should only be called from the main thread during +load. Interpose will be performed
 *     after commit is called.
 *  5. Pointer to original function must not be initialized to the symbol being interposed at
 *     compile time, because then it would be rebound by DYLD when we perform dynamic interpose.
 *     It should be initialized at runtime before commit is called.
 *  6. Pointer to original function must be provided to GREYInterposer, so that if it is statically
 *     interposed by another library it can be set to the original symbol.
 *  7. While accessing the original pointer and before calling the original function, user must
 *     acquire the read lock from GREYInterposer. This lock must be released after function returns.
 */
@interface GREYInterposer : NSObject

+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

- (void)interposeSymbol:(void *)replacee
        withReplacement:(void *)replacement
 storeOriginalInPointer:(void **)originalPtr;

// User must call acquireReadLock before accessing the original pointer and calling the function it
// points to and call releaseReadLock after this function returns.
- (void)acquireReadLock;
- (void)releaseReadLock;

// User must call commit from the main thread after all interposes are set. It must be called
// from +load.
- (void)commit;

@end
