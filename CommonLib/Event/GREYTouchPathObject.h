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

#import <UIKit/UIKit.h>

/**
 *  A struct to encapsulate essential information about a touch path.
 */
typedef struct GREYTouchPathObject {
  /**
   *  NSValue wrapping CGPoint for the start point of a touch gesture.
   */
  CGPoint startPoint;

  /**
   *  NSValue wrapping CGPoint for the end point of a touch gesture.
   */
  CGPoint endPoint;

  /**
   *  CFTimeInterval denoting the duration of an action.
   */
  CFTimeInterval duration;

  /**
   *  A BOOL check to nullify the inertia in the touch path.
   */
  BOOL cancelInertia;
} GREYTouchPathObject;
