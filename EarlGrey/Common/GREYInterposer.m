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

#import "Common/GREYInterposer.h"

#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <mach/mach.h>
#include <pthread.h>

#import "Assertion/GREYAssertionDefines.h"

#if __LP64__
#define LC_SEGMENT_COMMAND LC_SEGMENT_64
typedef const struct mach_header_64 mach_header_t;
typedef const struct load_command load_command_t;
typedef const struct segment_command_64 segment_command_t;
typedef const struct section_64 section_t;
#else
#define LC_SEGMENT_COMMAND LC_SEGMENT
typedef const struct mach_header mach_header_t;
typedef const struct load_command load_command_t;
typedef const struct segment_command segment_command_t;
typedef const struct section section_t;
#endif

// From mach-o/dyld_priv.h
const struct dyld_all_image_infos* _dyld_get_all_image_infos();
void dyld_dynamic_interpose(const struct mach_header *header,
                            const dyld_interpose_tuple *array,
                            size_t count);

const static size_t kTupleArraySize = 8;
static size_t gTupleCount = 0;
static dyld_interpose_tuple gReplacementTupleArray[kTupleArraySize];
static pthread_rwlock_t gSafeRemoveImageLock = PTHREAD_RWLOCK_INITIALIZER;
static pthread_rwlock_t gSafePointerUpdateLock = PTHREAD_RWLOCK_INITIALIZER;

// Container for storing @c dyld_interpose_tuple inside NSMutableSet.
@interface GREYStaticInterposeTuple : NSObject

- (instancetype)init NS_UNAVAILABLE;
@property (nonatomic, readonly) void *replacee;
@property (nonatomic, readonly) void *replacement;
@property (nonatomic, readonly) uint32_t image;

@end

@implementation GREYStaticInterposeTuple

- (instancetype)initWithSymbol:(void *)replacee
                   replacement:(void *)replacement
                       inImage:(uint32_t)image {
  self = [super init];
  if (self) {
    _replacee = replacee;
    _replacement = replacement;
    _image = image;
  }
  return self;
}

@end

// Container for storing dynamic interposes registered with GREYInterposer.
@interface GREYDynamicInterposeTuple : NSObject

- (instancetype)init NS_UNAVAILABLE;
@property (nonatomic, readonly) void *replacee;
@property (nonatomic, readonly) void *replacement;
@property (nonatomic, readonly) void *originalPtr;

@end

@implementation GREYDynamicInterposeTuple

- (instancetype)initWithSymbol:(void *)replacee
                   replacement:(void *)replacement
               originalPointer:(void **)originalPtr {
  self = [super init];
  if (self) {
    _replacee = replacee;
    _replacement = replacement;
    _originalPtr = originalPtr;
  }
  return self;
}

@end

@implementation GREYInterposer {
  BOOL _committed;
  NSMutableArray *_dynamicInterposes;
}

+ (instancetype)sharedInstance {
  static GREYInterposer *sharedInstance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    sharedInstance = [[GREYInterposer alloc] initOnce];
  });
  return sharedInstance;
}

- (instancetype)initOnce {
  I_CHECK_MAIN_THREAD();

  self = [super init];
  if (self) {
    _committed = NO;
    _dynamicInterposes = [[NSMutableArray alloc] init];
   }
  return self;
}

- (void)interposeSymbol:(void *)replacee
        withReplacement:(void *)replacement
 storeOriginalInPointer:(void **)originalPtr {
  NSParameterAssert(replacee);
  NSParameterAssert(replacement);
  NSParameterAssert(replacee != replacement);
  NSAssert(!_committed, @"interposer was already locked in final state");

  [_dynamicInterposes addObject:[[GREYDynamicInterposeTuple alloc] initWithSymbol:replacee
                                                                      replacement:replacement
                                                                  originalPointer:originalPtr]];
}

- (void)acquireReadLock {
  GREY_UNUSED_VARIABLE int lock = pthread_rwlock_rdlock(&gSafePointerUpdateLock);
  NSCAssert(lock == 0, @"Failed to lock.");
}

- (void)releaseReadLock {
  GREY_UNUSED_VARIABLE int unlock = pthread_rwlock_unlock(&gSafePointerUpdateLock);
  NSCAssert(unlock == 0, @"Failed to unlock.");
}

- (void)commit {
  I_CHECK_MAIN_THREAD();
  NSAssert(!_committed, @"interposer was already locked in final state");
  _committed = YES;

  // On 64-bit iOS 8.x simulator we have to fix a bug in dyld_sim.
#if TARGET_IPHONE_SIMULATOR && __LP64__
  [GREYInterposer grey_patchDYLDSim];
#endif

  NSMutableSet *_staticTuples = [[NSMutableSet alloc] init];
  NSMutableSet *_staticSymbols = [[NSMutableSet alloc] init];
  NSMutableSet *_staticReplacements = [[NSMutableSet alloc] init];
  NSMutableSet *_dynamicSymbols = [[NSMutableSet alloc] init];
  NSMutableSet *_dynamicReplacements = [[NSMutableSet alloc] init];

  // Get the slide of EarlGrey image by checking a file-scope variable.
  Dl_info info;
  if (dladdr(&gTupleCount, &info) == 0) {
    NSAssert(NO, @"dladdr returned with error");
  }
  intptr_t earlgreySlide = (intptr_t)info.dli_fbase;
  NSAssert(earlgreySlide != 0, @"could not find EarlGrey image slide");

  // Thread safety with _dyld_image_count: While it is unlikely that DYLD will remove an image while
  // we are accessing DYLD images on the main thread during +load, we can use a readers-writer lock
  // to ensure that DYLD will delay removing the image until work is complete. We acquire a write
  // lock before registering the remove image function and then any future attempts to remove an
  // image will be delayed until we release the write lock and a read lock can be acquired.
  GREY_UNUSED_VARIABLE int lock = pthread_rwlock_wrlock(&gSafeRemoveImageLock);
  NSCAssert(lock == 0, @"Failed to lock.");
  _dyld_register_func_for_remove_image(grey_interposer_check_lock);

  // Phase 1: Gather all required data from DYLD images.
  // For all images.
  for (uint32_t image = 0; image < _dyld_image_count(); image++) {
    mach_header_t *header = (mach_header_t *)_dyld_get_image_header(image);

    // Collect static interposing tuples from all MH_DYLIB images. Only MH_DYLIB images can be
    // used for static interposing. They must have been inserted with DYLD_INSERT_LIBRARIES or
    // loaded automatically as a dynamic dependency.
    // Edge case: If another image, loaded before EarlGrey, used dlopen to load a DYLIB with
    // static interposing tuples, DYLD will ignore them but the code below will assume they are
    // valid.
    if (header->filetype == MH_DYLIB) {
      load_command_t *command = (load_command_t *)(header + 1);
      // For all load commands in this image.
      for (uint32_t commandIndex = 0; commandIndex < header->ncmds; commandIndex++) {
        if (command->cmd == LC_SEGMENT_COMMAND) {
          segment_command_t *segment = (segment_command_t *)command;
          section_t *firstSection = (section_t *)(segment + 1);
          section_t *lastSection = firstSection + segment->nsects - 1;
          uintptr_t slide = (uintptr_t)_dyld_get_image_vmaddr_slide(image);
          // For all sections in this segment command.
          for (section_t *sect = firstSection; sect <= lastSection; sect++) {
            if ((sect->flags & SECTION_TYPE) == S_INTERPOSING ||
                (!strcmp(sect->sectname, "__interpose") && !strcmp(segment->segname, SEG_DATA))) {
              dyld_interpose_tuple *array = (dyld_interpose_tuple *)(sect->addr + slide);
              size_t count = sect->size / sizeof(dyld_interpose_tuple);
              // For all interposing tuples in this section.
              for (size_t i = 0; i < count; i++) {
                // Only add this tuple if symbol and replacement are different, because interpose
                // section size can be larger than is required to fit all tuples, in which case
                // the remaining tuples are just populated with 2 NULL pointers. In some cases
                // these pointers are not NULL, but identical, and then the tuple has no effect.
                if (array[i]._replacee != array[i]._replacement) {
                  [_staticSymbols addObject:[NSValue valueWithPointer:array[i]._replacee]];
                  [_staticReplacements addObject:[NSValue valueWithPointer:array[i]._replacement]];
                  GREYStaticInterposeTuple *tuple =
                      [[GREYStaticInterposeTuple alloc] initWithSymbol:array[i]._replacee
                                                           replacement:array[i]._replacement
                                                               inImage:image];
                  [_staticTuples addObject:tuple];
                }
              }
            }
          }
        }
        command = (load_command_t *)((uint8_t *)command + command->cmdsize);
      }
    }
  }

  // Phase 2: Do dynamic interpose for symbols which only need to be interposed in a single image
  // and add all symbols which must be interposed for all images to an array to be interposed later.
  for (GREYDynamicInterposeTuple *dynamicTuple in _dynamicInterposes) {
    void *replacee = dynamicTuple.replacee;
    void *replacement = dynamicTuple.replacement;
    void **originalPtr = dynamicTuple.originalPtr;

    NSAssert(![_dynamicSymbols containsObject:[NSValue valueWithPointer:replacee]],
             @"symbols should be unique");
    NSAssert(![_dynamicReplacements containsObject:[NSValue valueWithPointer:replacement]],
             @"replacements should be unique");

    [_dynamicSymbols addObject:[NSValue valueWithPointer:replacee]];
    [_dynamicReplacements addObject:[NSValue valueWithPointer:replacement]];

    GREYStaticInterposeTuple *staticTuple = nil;
    for (GREYStaticInterposeTuple *tuple in _staticTuples) {
      if (tuple.replacement == replacee || tuple.replacee == replacee) {
        NSAssert(!staticTuple, @"multiple matching tuples found");
        staticTuple = tuple;
      }
    }

    if (!staticTuple) {
      // Case 1: Symbol is not interposed yet. Dynamically interpose it in all images.
      NSAssert(*originalPtr == replacee, @"originalPtr should be set to replacee");
      NSAssert(gTupleCount + 1 <= kTupleArraySize, @"increase array size constant");

      gReplacementTupleArray[gTupleCount] = (dyld_interpose_tuple){ replacement, replacee };
      gTupleCount++;
    } else if (replacee == staticTuple.replacee) {
      // Case 2: Symbol is interposed only by EarlGrey. Dynamically interpose it inside EarlGrey.
      NSAssert(replacement == staticTuple.replacement, @"replacements should be identical");
      NSAssert(earlgreySlide == _dyld_get_image_vmaddr_slide(staticTuple.image),
               @"slide should match EarlGrey slide");
      NSAssert(*originalPtr == replacee, @"originalPtr should be set to replacee");

      dyld_interpose_tuple dyldTuple = {replacement, replacee};
      dyld_dynamic_interpose(_dyld_get_image_header(staticTuple.image), &dyldTuple, 1);
    } else if (replacee == staticTuple.replacement) {
      // Case 3: Symbol is interposed by another library; dynamically interpose it in that library.
      NSAssert(![_dynamicSymbols containsObject:[NSValue valueWithPointer:staticTuple.replacee]],
               @"original symbol conflict");
      NSAssert(earlgreySlide != _dyld_get_image_vmaddr_slide(staticTuple.image),
               @"slide shouldn't match EarlGrey slide");
      NSAssert(*originalPtr == replacee, @"originalPtr should be set to replacee");

      [_dynamicSymbols addObject:[NSValue valueWithPointer:staticTuple.replacee]];
      dyld_interpose_tuple dyldTuple = {replacement, staticTuple.replacee};
      // In this case we must change originalPtr to the non-interposed symbol. We must use the lock
      // to ensure that if our replacement function is called after dyld_dynamic_interpose but
      // before we update the pointer, it will block until we can update the pointer and release the
      // lock.
      grey_interposer_acquire_write_lock();
      dyld_dynamic_interpose(_dyld_get_image_header(staticTuple.image), &dyldTuple, 1);
      *originalPtr = staticTuple.replacee;
      grey_interposer_release_write_lock();
    } else {
      NSAssert(NO, @"one of the previous conditions should have been true");
    }
  }

  _dynamicInterposes = nil;
  // After setting staticTuples to nil we no longer rely on our data matching DYLD data.
  _staticTuples = nil;
  // At this point it is safe for DYLD to remove an image.
  GREY_UNUSED_VARIABLE int unlock = pthread_rwlock_unlock(&gSafeRemoveImageLock);
  NSCAssert(unlock == 0, @"Failed to unlock.");

  // Sanity check: assert no static replacement is in static symbols.
  for (GREY_UNUSED_VARIABLE NSNumber *replacement in _staticReplacements) {
    NSAssert(![_staticSymbols containsObject:replacement], @"static interpose conflict");
  }
  // Sanity check: assert no dynamic replacement is in static or dynamic symbols.
  for (GREY_UNUSED_VARIABLE NSNumber *replacement in _dynamicReplacements) {
    NSAssert(![_staticSymbols containsObject:replacement], @"replacement found in staticSymbols");
    NSAssert(![_dynamicSymbols containsObject:replacement], @"replacement found in dynamicSymbols");
  }

  // Phase 3: Perform dynamic interpose for symbols which must be interposed in all images.
  if (gTupleCount > 0) {
    // When we register this function, DYLD will automatically call it with all images which have
    // previously been added. It will also be called by DYLD whenever a new image is added later on.
    _dyld_register_func_for_add_image(grey_interposer_add_image);
  }
}

#pragma mark - Private

static void grey_interposer_acquire_write_lock() {
  GREY_UNUSED_VARIABLE int lock = pthread_rwlock_wrlock(&gSafePointerUpdateLock);
  NSCAssert(lock == 0, @"Failed to lock.");
}

static void grey_interposer_release_write_lock() {
  GREY_UNUSED_VARIABLE int unlock = pthread_rwlock_unlock(&gSafePointerUpdateLock);
  NSCAssert(unlock == 0, @"Failed to unlock.");
}

static void grey_interposer_add_image(const struct mach_header *header, intptr_t vmaddr_slide) {
  dyld_dynamic_interpose(header, gReplacementTupleArray, gTupleCount);
}

static void grey_interposer_check_lock(const struct mach_header *header, intptr_t vmaddr_slide) {
  // Method commit has acquired the write lock before registering this function, and it will release
  // it once changes which rely on DYLD image data are complete. It will never be acquired again.
  // Once we can acquire the read lock here we can release it immeditely and safely continue.
  GREY_UNUSED_VARIABLE int lock = pthread_rwlock_rdlock(&gSafeRemoveImageLock);
  NSCAssert(lock == 0, @"Failed to lock.");

  GREY_UNUSED_VARIABLE int unlock = pthread_rwlock_unlock(&gSafeRemoveImageLock);
  NSCAssert(unlock == 0, @"Failed to unlock.");
}

// DYLD bug only exists in 64-bit iOS 8.x simulator.
#if TARGET_IPHONE_SIMULATOR && __LP64__
/*
 * Bug:  dyld_sim in 64-bit iOS simulator, versions 8.0 through 8.4, uses the wrong type for
 *       acquiring and releasing sAllImagesLock, accidentally using 32 additional bits of memory
 *       which belong to another static variable, sDynamicInterposing. If dynamic interposing is
 *       used, sAllImagesLock can never be acquired or released again.
 *
 *       https://opensource.apple.com/source/dyld/dyld-353.2.1/src/dyld.cpp
 *       https://opensource.apple.com/source/dyld/dyld-353.2.1/src/dyldAPIs.cpp
 *
 *       1) In src/dyld.cpp, static variable sAllImagesLock is defined to be type OSSpinLock:
 *
 *          static OSSpinLock sAllImagesLock = 0;
 *
 *       2) In OSAtomic.h, OSSpinLock is defined to be a 32-bit integer:
 *
 *          typedef int32_t OSSpinLock;
 *
 *       3) In src/dyld.cpp, sAllImagesLock is cast to a pointer, which is a 64-bit type in a 64-bit
 *          binary. OSAtomicCompareAndSwapPtrBarrier is used to acquire it and release it, which
 *          uses 64-bits of memory at its address in a 64-bit binary, accidentally including value
 *          stored in the next static variable in memory, which happens to be sDymamicInterposing.
 *
 *          #if TARGET_IPHONE_SIMULATOR
 *          // <rdar://problem/16154256> can't use OSSpinLockLock in simulator until thread_switch
 *          // is provided by host dyld
 *          while (!OSAtomicCompareAndSwapPtrBarrier((void*)0, (void*)1, (void**)&sAllImagesLock)) {
 *            // spin
 *          }
 *          #else
 *
 *       4) In src/dyldAPIs.cpp, static variable sDynamicInterposing is set to true once
 *          dyld_dynamic_interpose is called.
 *
 *          sDynamicInterposing = true;
 *
 *       5) When sDynamicInterposing is true, OSAtomicCompareAndSwapPtrBarrier will read the value
 *          in sAllImagesLock as 4294967296 or 4294967297 while trying to compare it against 0 or 1.
 *          dyld_sim will block indefinitely.
 *
 *
 * Fix:  Patch assembly code to not use static variable sDynamicInterposing. This static variable
 *       is only used in 2 places in src/dyldAPIs.cpp.
 *
 *       1) Function dlsym checks if it is set to true and performs additional work to look up 
 *          the caller and return the correct symbol address (possibly interposed) for the code that
 *          called dlsym. This can be replaced with code that will make the check always succeed.
 *
 *       2) Function dyld_dynamic_interpose sets it to true. This code needs to be removed.
 *
 *       Note that this bug cannot be fixed without side effects unless we patch the assembly code.
 *
 *       Setting sDynamicInterposing to false after every dyld_dynamic_interpose call would make
 *       sure that sAllImagesLock keeps working, but dlsym behavior would be broken, and addresses
 *       returned would not be correct.
 *
 *       It is not possible to interpose dlsym and set sDynamicInterposing to true until dlsym
 *       returns without breaking dlsym behavior. This is because dlsym looks up the caller's return
 *       address to give it the correct symbol, and with interpose this return address would no
 *       longer be the return address of the original caller.
 *
 *       TODO(sskhandp): Remove this patch once EarlGrey stops supporting iOS 8.x simulator.
 */
+ (void)grey_patchDYLDSim {
  I_CHECK_MAIN_THREAD();

  // Version check must happen at run-time.
  if (iOS8_0_OR_ABOVE() && !iOS9_OR_ABOVE()) {
    // Find virtual memory slide of dyld_sim. It should be the first image loaded by dyld.
    const struct dyld_all_image_infos* allImageInfos = _dyld_get_all_image_infos();
    const struct dyld_image_info *likelyDyldSim = &allImageInfos->infoArray[0];
    uintptr_t slide = (uintptr_t)likelyDyldSim->imageLoadAddress;
    BOOL isDyldSim = strstr(likelyDyldSim->imageFilePath, "/usr/lib/dyld_sim") != NULL;
    NSAssert(isDyldSim, @"cannot find dyld_sim image info");

    /*
     *  Patch #1 : Modify dlsym to not read the contents of static variable sDynamicInterposing
     *             from memory to register dl. Just set this register to 1.
     *
     *  File     : https://opensource.apple.com/source/dyld/dyld-353.2.1/src/dyldAPIs.cpp
     *  Binary   : <simulator path>/usr/lib/dyld_sim
     *  Function : dlsym
     *
     *  Offset   : (8.0 - 8.1 simulator)
     *             0x90e8
     *             (8.2 - 8.4 simulator)
     *             0x90f8
     *
     *  Original : (8.0 - 8.1 simulator)
     *             8A 15 1E FE 01 00  mov dl, byte [ds:__ZL19sDynamicInterposing]
     *             84 D2              test dl, dl
     *             (8.2 - 8.4 simulator)
     *             8A 15 0E FE 01 00  mov dl, byte [ds:__ZL19sDynamicInterposing]
     *             84 D2              test dl, dl
     *
     *  Patch    : 90                 nop
     *             90                 nop
     *             90                 nop
     *             90                 nop
     *             B2 01              mov dl, 0x1
     *             84 D2              test dl, dl
     */
    const uintptr_t patch1 = iOS8_2_OR_ABOVE() ? (slide + 0x90f8) : (slide + 0x90e8);
    const uint64_t original1 = iOS8_2_OR_ABOVE() ? 0xd2840001fe0e158a : 0xd2840001fe1e158a;

    /*
     *  Patch #2 : Modify dyld_dynamic_interpose to not store 1 in static variable
     *             sDynamicInterposing. Replace with code that has no effect. This patch was chosen
     *             so that only a single 64-bit section needed to be replaced to prevent race
     *             conditions and make this replacement atomic and thread safe.
     *
     *             First byte 0x01 of the next 64-bit section belongs to the instruction from this
     *             64-bit section, and "test eax, 0x1000000" was chosen because it ends in 0x01 and
     *             does not change the value of any register or memory location. CPU flags are
     *             affected, but because the function epilogue begins right after this instruction
     *             it should be an effective no-op if it was ever executed. However, it should never
     *             get executed, because the preceding instruction is jmp, which will jump over it.
     *
     *  File     : https://opensource.apple.com/source/dyld/dyld-353.2.1/src/dyldAPIs.cpp
     *  Binary   : <simulator path>/usr/lib/dyld_sim
     *  Function : dyld_dynamic_interpose
     *
     *  Offset   : (8.0 - 8.1 simulator)
     *             0x93e8
     *             (8.2 - 8.4 simulator)
     *             0x93f8
     *
     *  Original : (8.0 - 8.1 simulator)
     *             00 00                                    ; last 2 bytes of previous instruction
     *             C6 05 1B FB 01 00  mov byte [ds:__ZL19sDynamicInterposing], 0x1
     *                                                      ; first 6 out of 7 bytes
     *             (8.2 - 8.4 simulator)
     *             00 00                                    ; last 2 bytes of previous instruction
     *             C6 05 0B FB 01 00  mov byte [ds:__ZL19sDynamicInterposing], 0x1
     *                                                      ; first 6 out of 7 bytes
     *
     *  Patch    : 00 00                                    ; last 2 bytes of previous instruction
     *             EB 05              jmp <5 bytes forward> ; 2 bytes
     *             A9 00 00 00        test eax, 0x1000000   ; first 4 out of 5 bytes
     */
    const uintptr_t patch2 = iOS8_2_OR_ABOVE() ? (slide + 0x93f8) : (slide + 0x93e8);
    const uint64_t original2 = iOS8_2_OR_ABOVE() ? 0x1fb0b05c60000 : 0x1fb1b05c60000;

    NSAssert((patch1 & 7) == 0, @"not aligned on 8-byte boundary");
    NSAssert((patch2 & 7) == 0, @"not aligned on 8-byte boundary");
    NSAssert(*(uint64_t *)patch1 == original1 && *(uint64_t *)patch2 == original2,
             @"assembly code for dyld_sim patches doesn't match");

    // We must get write permission for protected memory region from the kernel.
    vm_prot_t rwx = VM_PROT_ALL;
    mach_error_t error1 = vm_protect(mach_task_self(), patch1, sizeof(uint64_t), false, rwx);
    NSAssert(error1 == KERN_SUCCESS, @"failed to make memory for dyld_sim patches writable");
    mach_error_t error2 = vm_protect(mach_task_self(), patch2, sizeof(uint64_t), false, rwx);
    NSAssert(error2 == KERN_SUCCESS, @"failed to make memory for dyld_sim patches writable");

    // Thread safe: Since these 64-bit pointers are aligned on 8-byte boundary, the compiler should
    // generate movabsq instruction to store the value, which is atomic. Patched assembly code was
    // chosen so that even if another thread was executing instructions at or near these pointers,
    // there should be no possible situation where the instruction sequence is invalid or the state
    // of program execution is inconsistent.
    *(uint64_t *)patch1 = 0xd28401b290909090;
    *(uint64_t *)patch2 = 0xa905eb0000;

    // Set memory permission back to read and execute only.
    vm_prot_t rx = VM_PROT_READ | VM_PROT_EXECUTE;
    mach_error_t error3 = vm_protect(mach_task_self(), patch1, sizeof(uint64_t), false, rx);
    NSAssert(error3 == KERN_SUCCESS, @"failed to make memory for dyld_sim patches writable");
    mach_error_t error4 = vm_protect(mach_task_self(), patch2, sizeof(uint64_t), false, rx);
    NSAssert(error4 == KERN_SUCCESS, @"failed to make memory for dyld_sim patches writable");
  }
}
#endif

@end
