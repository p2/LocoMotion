//
// Copyright 2014 Scott Logic
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import CoreMotion

class HistoricalViewController: UITableViewController {

	let motionActivityManager = CMMotionActivityManager()
	let motionHandlerQueue = NSOperationQueue()
	let dateFormatter = NSDateFormatter()
	let timeFormatter = NSDateFormatter()
	let lengthFormatter = NSLengthFormatter()
	let pedometer = CMPedometer()
	
	var activityCollection: ActivityCollection? {
		didSet {
			dispatch_async(dispatch_get_main_queue()) {
				self.tableView.reloadData()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		dateFormatter.dateStyle = .ShortStyle
		dateFormatter.timeStyle = .NoStyle
		timeFormatter.dateStyle = .NoStyle
		timeFormatter.timeStyle = .ShortStyle
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if nil == activityCollection {
			fetchMotionActivityData()
		}
	}
	
	
	// MARK:- Motion Activity Methods
	
	var fetchMode = 1
	
	func fetchMotionActivityData(callback: (Void -> Void)? = nil) {
		if CMMotionActivityManager.isActivityAvailable() {
			let oneWeekInterval = 1 * 24 * 3600 as NSTimeInterval
			motionActivityManager.queryActivityStartingFromDate(NSDate(timeIntervalSinceNow: -oneWeekInterval), toDate: NSDate(), toQueue: motionHandlerQueue) {
				(activities, error) in
				if error != nil {
					print("There was an error retrieving the motion results: \(error)")
				}
				self.activityCollection = ActivityCollection(activities: activities!, mode: self.fetchMode)
				if let callback = callback {
					dispatch_async(dispatch_get_main_queue()) {
						callback()
					}
				}
			}
		}
		else if let callback = callback {
			callback()
		}
	}
	
	@IBAction func showRaw() {
		toolbarItems?.forEach() { $0.enabled = false }
		fetchMode = 0
		fetchMotionActivityData() {
			self.toolbarItems?.forEach() { $0.enabled = true }
		}
	}
	
	@IBAction func showFiltered() {
		toolbarItems?.forEach() { $0.enabled = false }
		fetchMode = 1
		fetchMotionActivityData() {
			self.toolbarItems?.forEach() { $0.enabled = true }
		}
	}
	
	@IBAction func showInterpreted() {
		toolbarItems?.forEach() { $0.enabled = false }
		fetchMode = 2
		fetchMotionActivityData() {
			self.toolbarItems?.forEach() { $0.enabled = true }
		}
	}
	
	
	// MARK:- UITableViewController methods
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return activityCollection?.activities.count ?? 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! MotionActivityCell
		cell.dateFormatter = dateFormatter
		cell.timeFormatter = timeFormatter
		cell.lengthFormatter = lengthFormatter
		cell.pedometer = pedometer
	if let activities = activityCollection?.activities {
		cell.activity = activities[activities.count - indexPath.row - 1]
	}
		return cell
	}
	
}

