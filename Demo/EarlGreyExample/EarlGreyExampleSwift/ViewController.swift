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

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  var tableItems = (1...50).map { $0 }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Create the send message view to contain one of the two send buttons
    let sendMessageView = SendMessageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    sendMessageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sendMessageView)

    // Create buttons
    let clickMe = createButton("ClickMe")
    view.addSubview(clickMe)
    let send = createButton("Send")
    // Change label to identify this button more easily for the layout test
    send.accessibilityLabel = "SendForLayoutTest"
    view.addSubview(send)
    let send2 = createButton("Send")
    sendMessageView.addSubview(send2)

    // Create a UITableView to send some elements out of the screen
    let table = createTable()
    view.addSubview(table)

    // Create constraints
    let views = ["clickMe": clickMe, "send": send, "send2": send2, "table": table,
        "sendMessageView": sendMessageView]
    var allConstraints = [NSLayoutConstraint]()
    let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|-40-[clickMe]-40-[send2]-40-[table]|", options: [], metrics: nil, views: views)
    allConstraints += verticalConstraints
    let buttonsHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
        "|-10-[clickMe(100)]-20-[send(100)]", options:.AlignAllTop,
        metrics: nil, views: views)
    allConstraints += buttonsHorizontalConstraints
    let sendMessageViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
        "|-10-[send2(100)]", options:.AlignAllTop,
        metrics: nil, views: views)
    allConstraints += sendMessageViewConstraints
    let tableConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
        "|-10-[table(320)]", options:.AlignAllTop,
        metrics: nil, views: views)
    allConstraints += tableConstraints
    NSLayoutConstraint.activateConstraints(allConstraints)
  }

  func createButton(title: String) -> UIButton {
    let button = UIButton(type: .System)
    button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    button.backgroundColor = UIColor.greenColor()
    button.setTitle(title, forState: .Normal)
    button.addTarget(self, action: #selector(ViewController.buttonAction(_:)),
        forControlEvents: .TouchUpInside)
    button.accessibilityIdentifier = title
    button.accessibilityLabel = title
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  func buttonAction(sender: UIButton!) {
    if let id = sender.accessibilityIdentifier {
      print("Button \(id) clicked")
    }
  }

  func createTable() -> UITableView {
    let tableView = UITableView()
    tableView.frame = CGRect(x: 0, y: 0, width: 320, height: 200)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.estimatedRowHeight = 85.0
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.accessibilityIdentifier = "table"
    return tableView
  }

  func numberOfSectionsInTableView(tableView:UITableView) -> Int {
    return 1
  }

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableItems.count
  }

  func tableView(tableView: UITableView,
      cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell:UITableViewCell =
        tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
    // For cell 1 to 7, add a date
    var cellID : String
    if (indexPath.row >= 1 && indexPath.row <= 7) {
      cellID = getDateForIndex(indexPath.row)
    } else {
      cellID = "Cell\(tableItems[indexPath.row])"
    }
    cell.textLabel?.text = cellID
    cell.accessibilityIdentifier = cellID
    return cell
  }

  func getDateForIndex(index: Int) -> String {
    var date = NSDate()
    let dateDeltaComponents = NSDateComponents()
    dateDeltaComponents.day = index
    date = NSCalendar.currentCalendar().dateByAddingComponents(
        dateDeltaComponents, toDate: date, options: NSCalendarOptions(rawValue: 0))!
    let formatter = NSDateFormatter()
    formatter.dateStyle = .LongStyle
    return formatter.stringFromDate(date)
  }
}

@objc class SendMessageView: UIView {
  // empty sub class of UIView to exercise inRoot
}
