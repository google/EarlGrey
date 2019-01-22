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

import Foundation
import UIKit

@objc
public protocol TextFieldNotification {
  /// Returns true if the notification observer for the editing event is triggered.
  var wasNotificationReceived: Bool { get }
}

@objc
public protocol TextFieldEditingEvents: GREYAction {
  /// Returns true if the specified editing events has been triggered.
  var wasEventReceived: Bool { get }
}


/// Test Host protocol that exposes GREYHostApplicationDistantObject methods to the test.
@objc
public protocol FTRSwiftTestsHost {

  /// Returns a matcher for the first element matched.
  func makeFirstElementMatcher() -> GREYMatcher

  /// Returns an action that checks if the element being acted on is hidden or not.
  func makeCheckHiddenAction() -> GREYAction

  /// Returns a TextFieldEventsRecorder object that sets up observers for text field
  /// notifications.
  func makeTextFieldNotificationRecorder(
    for notification: NSNotification.Name
    ) -> TextFieldNotification

  /// Resets the navigation stack by popping view controllers till the root view controller.
  func resetNavigationStack()

  /// Returns a TextFieldEventsRecorder object that sets up observers for text field editing
  /// events.

  #if swift(>=4.2)
  func makeTextFieldEditingEventRecorder(
    for controlEvent: UIControl.Event
    ) -> TextFieldEditingEvents
  #else
  func makeTextFieldEditingEventRecorder(
  for controlEvent: UIControlEvents
  ) -> TextFieldEditingEvents
  #endif

}
