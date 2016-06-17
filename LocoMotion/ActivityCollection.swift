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

import Foundation
import CoreMotion


/**
Bitmask for core motion activity types, mapping directly to what's available in CMMotionActivity.
*/
public struct CoreMotionActivityType: OptionSetType {
	public let rawValue: Int
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// None of the activity types was set to true.
	static let Unknown    = CoreMotionActivityType(rawValue: 1 << 0)
	
	/// The activitie's "stationary" flag was on.
	static let Stationary = CoreMotionActivityType(rawValue: 1 << 1)
	
	/// The activitie's "automotive" flag was on.
	static let Automotive = CoreMotionActivityType(rawValue: 1 << 2)
	
	/// The activitie's "walking" flag was on.
	static let Walking    = CoreMotionActivityType(rawValue: 1 << 3)
	
	/// The activitie's "running" flag was on.
	static let Running    = CoreMotionActivityType(rawValue: 1 << 4)
	
	/// The activitie's "cyclinc" flag was on.
	static let Cycling    = CoreMotionActivityType(rawValue: 1 << 5)
}


/**
Representing a CMMotionActivity
*/
public class CoreMotionActivity {
	
	var type: CoreMotionActivityType
	
	var startDate: NSDate
	
	var endDate: NSDate
	
	var confidence: Int
	
	public init(activity: CMMotionActivity) {
		var typ: CoreMotionActivityType = .Unknown
		if activity.stationary {
			typ.insert(.Stationary)
			typ.remove(.Unknown)
		}
		if activity.automotive {
			typ.insert(.Automotive)
			typ.remove(.Unknown)
		}
		if activity.walking {
			typ.insert(.Walking)
			typ.remove(.Unknown)
		}
		if activity.running {
			typ.insert(.Running)
			typ.remove(.Unknown)
		}
		if activity.cycling {
			typ.insert(.Cycling)
			typ.remove(.Unknown)
		}
		type = typ
		startDate = activity.startDate
		endDate = activity.startDate
		confidence = activity.confidence.rawValue
	}
	
	public var isWalkingRunningCycling: Bool {
		return type.contains(.Walking) || type.contains(.Running) || type.contains(.Cycling)
	}
}


class ActivityCollection {
	var activities = [CoreMotionActivity]()
	
	var mode = 0

	init(activities: [CMMotionActivity], mode: Int = 0) {
		self.mode = mode
		addCMMotionActivities(activities)
		
		if mode > 1 {
			var prev: CoreMotionActivity?
			for i in 0..<self.activities.count {
				let activity = self.activities[i]
				let duration = activity.endDate.timeIntervalSinceDate(activity.startDate)
				
				// automotive < 5 minutes: stationary
				if activity.type.contains(.Automotive) && duration < 300.0 {
					activity.type.remove(.Automotive)
					activity.type.unionInPlace(.Stationary)
				}
				
				// cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
				else if activity.type.contains(.Cycling) && duration < 120.0 {
					activity.type.remove(.Cycling)
					if let prev = prev where prev.type.contains(.Running) {
						activity.type.unionInPlace(.Running)
					}
					else if self.activities.count > i+1 && self.activities[i+1].type.contains(.Running) {
						activity.type.unionInPlace(.Running)
					}
					else if let prev = prev where prev.type.contains(.Walking) {
						activity.type.unionInPlace(.Walking)
					}
					else if self.activities.count > i+1 && self.activities[i+1].type.contains(.Walking) {
						activity.type.unionInPlace(.Walking)
					}
					else {
						activity.type.unionInPlace(.Stationary)
					}
				}
				
				/*/ stationary < 1 minute, running or walking before and after: standing
				else if activity.type.contains(.Stationary) && duration < 60.0 {
					if let prev = prev where prev.isWalkingRunningCycling {
					}
					else if self.activities.count > i+1 && self.activities[i+1].isWalkingRunningCycling {
					}
				}	//	*/
				
				prev = activity
			}
			
			// concatenate again
			var concatenated = [CoreMotionActivity]()
			for activity in self.activities {
				addMotionActivity(activity, to: &concatenated)
			}
			self.activities = concatenated
		}
	}
	
	func addCMMotionActivity(motionActivity: CMMotionActivity, inout to: [CoreMotionActivity]) {
		let activity = CoreMotionActivity(activity: motionActivity)
		addMotionActivity(activity, to: &to)
	}
	
	func addMotionActivity(activity: CoreMotionActivity, inout to: [CoreMotionActivity]) {
		if 0 == mode || !activity.type.isSubsetOf(.Unknown) {
			if mode > 0, let prev = to.last where prev.type.isSubsetOf(activity.type) && activity.type.isSubsetOf(prev.type) {
				prev.confidence = max(prev.confidence, activity.confidence)
			}
			else if mode > 0, let prev = to.last where prev.type.contains(.Automotive) && activity.type.contains(.Automotive) {
				prev.type.unionInPlace(activity.type)
				prev.confidence = max(prev.confidence, activity.confidence)
			}
			else {
				to.last?.endDate = activity.startDate
				to.append(activity)
			}
		}
	}
	
	func addCMMotionActivities(motionActivities: [CMMotionActivity]) {
		for activity in motionActivities {
			addCMMotionActivity(activity, to: &activities)
		}
	}
}


