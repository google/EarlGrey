//
// Copyright 2022 Google LLC.
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

// DYLD_INTERPOSE referenced from
// https://opensource.apple.com/source/dyld/dyld-210.2.3/include/mach-o/dyld-interposing.h.
#define DYLD_INTERPOSE(_replacement, _replacee)                               \
  __attribute__((used)) static struct {                                       \
    const void *replacement;                                                  \
    const void *replacee;                                                     \
  } gInterpose_##_replacee __attribute__((section("__DATA,__interpose"))) = { \
      (const void *)(unsigned long)&_replacement,                             \
      (const void *)(unsigned long)&_replacee};
