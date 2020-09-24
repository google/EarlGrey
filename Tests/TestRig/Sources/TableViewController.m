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

#import "TableViewController.h"

static NSString *gTableViewIdentifier = @"TableViewCellReuseIdentifier";

@implementation TableViewController {
  NSMutableArray<NSNumber *> *_rowIndicesRemoved;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _rowIndicesRemoved = [[NSMutableArray alloc] init];

  self.mainTableView.accessibilityIdentifier = @"main_table_view";
  self.mainTableView.dataSource = self;
  self.mainTableView.delegate = self;

  self.mainTableView.dragInteractionEnabled = YES;
  self.mainTableView.dragDelegate = self;
  self.mainTableView.dropDelegate = self;

  self.insetsValue.delegate = self;
}

- (IBAction)insetsToggled:(UISwitch *)sender {
  if ([sender isOn]) {
    [self.mainTableView setContentInset:UIEdgeInsetsFromString(self.insetsValue.text)];
  } else {
    [self.mainTableView setContentInset:UIEdgeInsetsZero];
  }
}

#pragma mark - UITableView Drag/Drop Delegate

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView
    moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
           toIndexPath:(NSIndexPath *)destinationIndexPath {
  UITableViewCell *sourceCell = [tableView cellForRowAtIndexPath:sourceIndexPath];
  NSString *sourceText = sourceCell.textLabel.text;

  UITableViewCell *destCell = [tableView cellForRowAtIndexPath:destinationIndexPath];
  NSString *destText = destCell.textLabel.text;

  [sourceCell.textLabel setText:[NSString stringWithFormat:@"Moved To Row: %@", destText]];
  [destCell.textLabel setText:[NSString stringWithFormat:@"Moved From Row: %@", sourceText]];
}

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView
        itemsForBeginningDragSession:(id<UIDragSession>)session
                         atIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSItemProvider *provider = [[NSItemProvider alloc] initWithObject:cell.textLabel.text];
  return @[ [[UIDragItem alloc] initWithItemProvider:provider] ];
}

- (void)tableView:(UITableView *)tableView
    performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
  NSString *text = (NSString *)[coordinator.items firstObject];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:coordinator.destinationIndexPath];
  cell.textLabel.text = text;
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [_rowIndicesRemoved addObject:@(indexPath.row)];
    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 100 - (NSInteger)_rowIndicesRemoved.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gTableViewIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:gTableViewIdentifier];
  }

  NSInteger row = indexPath.row;
  for (NSNumber *number in _rowIndicesRemoved) {
    if ([number integerValue] <= row) {
      row++;
    }
  }

  cell.textLabel.text = [NSString stringWithFormat:@"Row %ld", (long)row];
  return cell;
}

#pragma mark - UIContextMenuInteractionDelegate

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
    contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                        point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
  return [UIContextMenuConfiguration
      configurationWithIdentifier:@"UITableViewCell Context Menu Config"
                  previewProvider:nil
                   actionProvider:^UIMenu *_Nullable(
                       NSArray<UIMenuElement *> *_Nonnull suggestedActions) {
                     UIAction *action =
                         [UIAction actionWithTitle:@"Some"
                                             image:nil
                                        identifier:nil
                                           handler:^(__kindof UIAction *_Nonnull action){
                                               // Empty Handler.
                                           }];
                     return [UIMenu menuWithTitle:@"MENU" children:@[ action ]];
                   }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

@end
