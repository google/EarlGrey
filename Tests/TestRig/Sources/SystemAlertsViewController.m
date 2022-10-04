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

#import <AVFoundation/AVFoundation.h>
#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <EventKit/EventKit.h>
#import <StoreKit/StoreKit.h>
#import <UserNotifications/UserNotifications.h>

#import "SystemAlertsViewController.h"

@interface SystemAlertsViewController () <CLLocationManagerDelegate,
                                          UINavigationControllerDelegate,
                                          UIImagePickerControllerDelegate>

/**
 * UIButton which on being pressed brings up a Locations Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *locationAlertButton;
/**
 * UIButton which on being pressed brings up a Contacts Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *contactsAlertButton;
/**
 * UIButton which on being pressed brings up a reminders and camera Alert in succession.
 */
@property(weak, nonatomic) IBOutlet UIButton *remindersCameraAlertButton;
/**
 * UIButton which on being pressed brings up a Notifications Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *notificationsAlertButton;
/**
 * UIButton which on being pressed brings up a Calendar Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *calendarAlertButton;
/**
 * UIButton which on being pressed brings up a Motion Activity Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *motionActivityAlertButton;
/**
 * UIButton which on being pressed brings up a Background Location Alert.
 */
@property(weak, nonatomic) IBOutlet UIButton *backgroundLocationAlertButton;
/**
 * UIButton which on being pressed brings up an alert for entering iTunes credentials.
 */
@property(weak, nonatomic) IBOutlet UIButton *iTunesRestorePurchasesButton;
/**
 * UIButton which is displayed only when a button triggering a System Alert is displayed. On
 * being pressed, also dismisses the @c alertValuelabel.
 */
@property(weak, nonatomic) IBOutlet UIButton *alertHandledButton;

/**
 * UILabel which is displayed only when a button triggering a System Alert is displayed along
 * with the expected result i.e. Granted / Denied as its title.
 */
@property(weak, nonatomic) IBOutlet UILabel *alertValueLabel;

/**
 * Location Manager for the test app, which on asking for re-authorization triggers the
 * Locations Alert.
 */
@property(strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation SystemAlertsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.alertValueLabel setHidden:YES];
  [self.alertHandledButton setHidden:YES];
  [self.alertHandledButton addTarget:self
                              action:@selector(alertHandledButtonPressed)
                    forControlEvents:UIControlEventTouchUpInside];
  [self.locationAlertButton addTarget:self
                               action:@selector(locationAlertButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
  [self.contactsAlertButton addTarget:self
                               action:@selector(contactsAlertButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
  [self.remindersCameraAlertButton addTarget:self
                                      action:@selector(cameraRemindersAlertsButtonPressed)
                            forControlEvents:UIControlEventTouchUpInside];
  [self.notificationsAlertButton addTarget:self
                                    action:@selector(notificationsAlertButtonPressed)
                          forControlEvents:UIControlEventTouchUpInside];
  [self.calendarAlertButton addTarget:self
                               action:@selector(calendarAlertButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
  [self.motionActivityAlertButton addTarget:self
                                     action:@selector(motionActivityAlertButtonPressed)
                           forControlEvents:UIControlEventTouchUpInside];
  [self.backgroundLocationAlertButton addTarget:self
                                         action:@selector(backgroundLocationAlertButtonPressed)
                               forControlEvents:UIControlEventTouchUpInside];
  [self.iTunesRestorePurchasesButton addTarget:self
                                        action:@selector(iTunesRestorePurchasesButtonPressed)
                              forControlEvents:UIControlEventTouchUpInside];
}

/**
 * Brings up a location alert by asking for authorization for updating the location of the test
 * app and unhides the alert handler button.
 */
- (void)locationAlertButtonPressed {
  [self.alertHandledButton setHidden:NO];

  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;

  SEL authorizationSelector = @selector(requestWhenInUseAuthorization);
  if ([self.locationManager respondsToSelector:authorizationSelector]) {
    [self.locationManager requestWhenInUseAuthorization];
  } else {
    if ([CLLocationManager locationServicesEnabled]) {
      [self.locationManager startUpdatingLocation];
    }
  }
}

/**
 * Brings up a contacts alert and unhides the alert handler button and the alert label with the
 * title as Granted.
 */
- (void)contactsAlertButtonPressed {
  CNContactStore *contactStore = [[CNContactStore alloc] init];
  [contactStore requestAccessForEntityType:CNEntityTypeContacts
                         completionHandler:^(BOOL granted, NSError *_Nullable error) {
                           [self updateAlertLabelForValue:granted];
                         }];
  [self.alertHandledButton setHidden:NO];
}

/**
 * Brings up the Reminders and Camera Alert, unhides the alert handler button and the alert label
 * with the title as Granted. Also brings up an app alert that can be dismissed by the app's
 * default UIInterruption Handler or by looking at alert views in the app.
 */
- (void)cameraRemindersAlertsButtonPressed {
  [[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeReminder
                                              completion:^(BOOL granted, NSError *error) {
                                                [self updateAlertLabelForValue:granted];
                                              }];
  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                           completionHandler:^(BOOL granted) {
                             [self updateAlertLabelForValue:granted];
                           }];
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"Sample!"
                                          message:@"FooBar"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
  [self.alertHandledButton setHidden:NO];
}

/**
 * Brings up a notifications (APNS) alert and unhides the alert handler button.
 */
- (void)notificationsAlertButtonPressed {
  [self.alertHandledButton setHidden:NO];

  UIApplication *shared = UIApplication.sharedApplication;
  UNAuthorizationOptions options =
      (UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert);
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center requestAuthorizationWithOptions:options
                        completionHandler:^(BOOL granted, NSError *_Nullable error){
                        }];
  [shared registerForRemoteNotifications];
}

/**
 * Brings up a calendar alert, similar to the Reminders alert and unhides the alert handler button.
 */
- (void)calendarAlertButtonPressed {
  [self.alertHandledButton setHidden:NO];
  [[[EKEventStore alloc] init] requestAccessToEntityType:EKEntityTypeEvent
                                              completion:^(BOOL granted, NSError *error){
                                              }];
}

/**
 * Brings up a motion activity alert and unhides the alert handler button.
 */
- (void)motionActivityAlertButtonPressed {
  [self.alertHandledButton setHidden:NO];
  CMMotionActivityManager *manager = [[CMMotionActivityManager alloc] init];
  NSOperationQueue *motionActivityQueue = [[NSOperationQueue alloc] init];

  [manager startActivityUpdatesToQueue:motionActivityQueue
                           withHandler:^(CMMotionActivity *activity){
                           }];
}

/**
 * Brings up a background location alert and unhides the alert handler button.
 */
- (void)backgroundLocationAlertButtonPressed {
  [self.alertHandledButton setHidden:NO];
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;

  [self.locationManager requestAlwaysAuthorization];
}

/**
 * Tries to restore any completed App Store transactions (there are none since the app isn't
 * registered). This causes the iTunes user credentials System Alert to pop up for interaction.
 */
- (void)iTunesRestorePurchasesButtonPressed {
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

/**
 * Hides the alert value label and the alert handled button.
 */
- (void)alertHandledButtonPressed {
  [self.alertValueLabel setHidden:YES];
  [self.alertHandledButton setHidden:YES];
}

/**
 * Updates the alert label with the provided text.
 *
 * @param granted @c BOOL determining if the alert is to be accepted or denied.
 */
- (void)updateAlertLabelForValue:(BOOL)granted {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (granted) {
      self.alertValueLabel.text = @"Granted";
    } else {
      self.alertValueLabel.text = @"Denied";
    }
    [self.alertValueLabel setHidden:NO];
  });
}

@end
