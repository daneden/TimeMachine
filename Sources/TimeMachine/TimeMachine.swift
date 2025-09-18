//
//  TimeMachineView.swift
//  TimeMachine
//
//  Created by Daniel Eden on 17/09/2025.
//

import Observation
import Foundation
import OSLog

@MainActor @Observable
final public class TimeMachine {
	nonisolated init() { }
	
	public init(referenceDate: Date = .now,
							incrementUnit: Calendar.Component = .day,
							incrementRange: ClosedRange<Double> = -12...12) {
		self.referenceDate = referenceDate
		self.incrementUnit = incrementUnit
		self.range = incrementRange
	}
	
	// MARK: Reference values and constants
	public private(set) var referenceDate: Date = .now
	public private(set) var incrementUnit: Calendar.Component = .day
	public private(set) var range: ClosedRange<Double> = -12...12
	
	// MARK: Variables
	public var offset: Double = 0
	
	public var date: Date {
		get {
			Calendar.current.date(byAdding: incrementUnit, value: Int(offset.rounded(.toNearestOrAwayFromZero)), to: referenceDate) ?? referenceDate
		}
		
		set {
			offset = convertTime(from: referenceDate.distance(to: newValue), to: incrementUnit)
		}
	}
	
	public var interfaceState = InterfaceState()
	
	public func updateReferenceDate(to newDate: Date = .now) {
		referenceDate = newDate
	}
	
	public func reset() { offset = 0 }
	
	// MARK: Computed variables
	@ObservationIgnored
	public var formattedOffset: String {
		formatDuration(offsetInSeconds)
	}
	
	@ObservationIgnored
	public var formattedRoundedOffset: String {
		formatDuration(roundedOffset)
	}
	
	public var isActive: Bool { offset != 0 }
}

internal extension TimeMachine {
	nonisolated static let `default`: TimeMachine = {
		Logger(subsystem: "me.daneden.framework", category: "TimeMachine")
			.warning("""
				The `TimeMachine.default` singleton was unexpectedly accessed.
				
				This usually happens when `TimeMachineView` is rendered or the `\\.timeMachine` environment variable is accessed without calling `.withTimeMachine()` on an ancestor view.
				""")
		return TimeMachine()
	}()
}

private extension TimeMachine {
	func convertTime(from seconds: TimeInterval, to dateComponent: Calendar.Component) -> Double {
		switch dateComponent {
		case .second:
			return seconds
		case .minute:
			return seconds / 60
		case .hour:
			return seconds / 3600
		case .day:
			return seconds / 86400
		case .weekOfYear:
			return seconds / (86400 * 7)
		case .month:
			return seconds / (86400 * 30)
		case .year:
			return seconds / (86400 * 365.25)
		default:
			return 0
		}
	}
	
	var offsetInSeconds: TimeInterval {
		offsetInSeconds(offset)
	}
	
	func offsetInSeconds(_ offset: Double) -> TimeInterval {
		switch incrementUnit {
		case .second:
			return offset
		case .minute:
			return offset * 60
		case .hour:
			return offset * 3600
		case .day:
			return offset * 86400
		case .weekOfYear:
			return offset * 86400 * 7
		case .month:
			return offset * 86400 * 30
		case .year:
			return offset * 86400 * 365.25
		default:
			return 0
		}
	}
}

public extension TimeMachine {
	var roundedOffset: Double {
		offsetInSeconds(convertTime(from: offsetInSeconds, to: incrementUnit).rounded(.toNearestOrAwayFromZero))
	}
	
	var rangeLowerBoundSeconds: TimeInterval {
		offsetInSeconds(range.lowerBound)
	}
	
	var rangeUpperBoundSeconds: TimeInterval {
		offsetInSeconds(range.upperBound)
	}
	
	func formatDuration(_ duration: TimeInterval) -> String {
		return (duration >= 0 ? "+" : "") + Duration.seconds(duration).formatted(.units(
			allowed: [.weeks, .days, .hours, .minutes],
			width: .narrow,
			maximumUnitCount: 3,
			fractionalPart: .hide(rounded: .toNearestOrAwayFromZero)
		))
	}
}

public extension TimeMachine {
	struct InterfaceState {
		public var datePickerVisible = false
	}
}
