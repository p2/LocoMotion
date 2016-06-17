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


class MotionActivityCell: UITableViewCell {
	
	@IBOutlet weak var iconImageView: UIImageView!
	@IBOutlet weak var secondImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var pedometerLabel: UILabel!
	@IBOutlet weak var confidenceLabel: UILabel!
	
	
	var activity: CoreMotionActivity? {
		didSet {
			prepareCellForActivity(activity)
		}
	}
	
	var dateFormatter: NSDateFormatter?
	var timeFormatter: NSDateFormatter?
	var lengthFormatter: NSLengthFormatter?
	var pedometer: CMPedometer?
	
	
	// MARK:- Utility methods
	private func prepareCellForActivity(activity: CoreMotionActivity?) {
		guard let activity = activity else {
			return
		}
		var imgs = [String]()
		pedometerLabel.text = ""
		
		if activity.type.contains(.Automotive) {
			imgs.append("drive")
			requestPedometerData()
		}
		if activity.type.contains(.Cycling) {
			imgs.append("cycle")
			requestPedometerData()
		}
		if activity.type.contains(.Running) {
			imgs.append("run")
			requestPedometerData()
		}
		if activity.type.contains(.Walking) {
			imgs.append("walk")
			requestPedometerData()
		}
		if activity.type.contains(.Stationary) {
			imgs.append("sit")
			requestPedometerData()
		}
		
		iconImageView.image = UIImage(named: imgs.first ?? "unknown")
		if imgs.count > 1 {
			secondImageView.hidden = false
			secondImageView.image = UIImage(named: imgs[1])
			if imgs.count > 2 {
				print("Unable to show all types: \(imgs)")
			}
		}
		else {
			secondImageView.hidden = true
		}
		titleLabel.text = "\(dateFormatter!.stringFromDate(activity.startDate))  \(timeFormatter!.stringFromDate(activity.startDate)) - \(timeFormatter!.stringFromDate(activity.endDate))"
		confidenceLabel.text = "\(activity.confidence)"
	}
	
	private func requestPedometerData() {
		guard let start = activity?.startDate, let end = activity?.endDate else {
			return
		}
		pedometer?.queryPedometerDataFromDate(start, toDate: end) {
			(data, error) -> Void in
			if error != nil {
				print("There was an error requesting data from the pedometer: \(error)")
			} else {
				dispatch_async(dispatch_get_main_queue()) {
					self.pedometerLabel.text = self.constructPedometerString(data!)
				}
			}
		}
	}
	
	private func constructPedometerString(data: CMPedometerData) -> String {
		var pedometerString = ""
		if CMPedometer.isStepCountingAvailable() {
			pedometerString += "\(data.numberOfSteps) steps | "
		}
		if CMPedometer.isDistanceAvailable() {
			pedometerString += "\(lengthFormatter!.stringFromMeters(data.distance as! Double)) | "
		}
		if CMPedometer.isFloorCountingAvailable() {
			pedometerString += "\(data.floorsAscended ?? 0) floors"
		}
		return pedometerString
	}

}
