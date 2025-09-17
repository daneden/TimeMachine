//
//  View+withTimeMachine.swift
//  TimeMachine
//
//  Created by Daniel Eden on 17/09/2025.
//

import SwiftUI

public enum TimeMachineUpdateFrequency {
	case everyMinute, everySecond
}

private struct TimeMachineViewModifier: ViewModifier {
	@State var timeMachine: TimeMachine
	var schedule: TimeMachineUpdateFrequency = .everyMinute
	
	init(timeMachine: TimeMachine, schedule: TimeMachineUpdateFrequency) {
		self.timeMachine = timeMachine
		self.schedule = schedule
	}
	
	init(
		incrementUnit: Calendar.Component = .day,
		incrementRange: ClosedRange<Double> = -182...182,
		updateFrequency: TimeMachineUpdateFrequency
	) {
		self.timeMachine = TimeMachine(incrementUnit: incrementUnit, incrementRange: incrementRange)
		self.schedule = updateFrequency
	}
	
	private var timelineSchedule: PeriodicTimelineSchedule {
		let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
		let date = Calendar.current.date(bySettingHour: components.hour ?? 0,
																		 minute: components.minute ?? 0,
																		 second: 0,
																		 of: Date())
		switch schedule {
		case .everyMinute:
			return PeriodicTimelineSchedule(from: date ?? .now, by: 60)
		case .everySecond:
			return PeriodicTimelineSchedule(from: date ?? .now, by: 1)
		}
	}
	
	func body(content: Content) -> some View {
		content
			.environment(\.timeMachine, timeMachine)
			.overlay {
				TimelineView(timelineSchedule) { t in
					Color.clear.task(id: t.date) {
						timeMachine.updateReferenceDate(to: t.date)
					}
				}
			}
	}
}

public extension View {
	func withTimeMachine(
		incrementUnit: Calendar.Component = .day,
		incrementRange: ClosedRange<Double> = -182...182,
		updateFrequency: TimeMachineUpdateFrequency = .everyMinute
	) -> some View {
		modifier(TimeMachineViewModifier(incrementUnit: incrementUnit,
																		 incrementRange: incrementRange,
																		 updateFrequency: updateFrequency))
	}
	
	func withTimeMachine(
		_ timeMachine: TimeMachine,
		updateFrequency: TimeMachineUpdateFrequency = .everyMinute
	) -> some View {
		modifier(TimeMachineViewModifier(timeMachine: timeMachine, schedule: updateFrequency))
	}
}
