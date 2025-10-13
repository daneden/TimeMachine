//
//  TimeMachineView.swift
//  TimeMachine
//
//  Created by Daniel Eden on 17/09/2025.
//

import SwiftUI

public enum AbsoluteTimeVisibility {
	case always, never, datePickerVisible
}

public struct DatePickerActivePreferenceKey: PreferenceKey {
	public static let defaultValue: Bool = false
	
	public static func reduce(value: inout Bool, nextValue: () -> Bool) {
		value = nextValue()
	}
}

public extension EnvironmentValues {
	@Entry var timeMachineViewHeaderFontWeight = Font.Weight.semibold
}

public struct TimeMachineView<L: View>: View {
	public typealias LabelBuilder = (TimeMachine, TimeZone?) -> Text
	@Environment(\.timeMachineViewHeaderFontWeight) var headerFontWeight
	@Environment(\.timeMachine) var timeMachine
	@Environment(\.timeZone) var timeZone
	
	public var sliderStep: Double = -1
	public var enableDatePicker: Bool = true
	public var showAbsoluteTime: AbsoluteTimeVisibility = .datePickerVisible
	public var datePickerComponents: DatePickerComponents = [.date, .hourAndMinute]
	
	@ViewBuilder public var label: L
	public var absoluteTimestampLabel: LabelBuilder
	public var relativeTimestampLabel: LabelBuilder
	public var minimumValueLabel: LabelBuilder
	public var maximumValueLabel: LabelBuilder
	public var datePickerLabel: LabelBuilder
	
	public var body: some View {
		@Bindable var timeMachine = self.timeMachine
		
		VStack {
			HStack {
				if enableDatePicker {
					Toggle(isOn: $timeMachine.interfaceState.datePickerVisible.animation()) {
						toggleButtonLabel
					}
					.accessibilityLabel(Text("Toggle date picker"))
					.toggleStyle(TimeMachineToggleStyle())
					.tint(.primary)
				} else {
					timeTravelLabel
				}
				
				Spacer()
				
				Button("Reset", systemImage: "arrow.counterclockwise") {
					withAnimation {
						timeMachine.reset()
					}
				}
				.disabled(!timeMachine.isActive)
			}
			.fontWeight(headerFontWeight)
			
#if os(watchOS)
			fallbackSlider
#else
			if #available(macOS 26, iOS 26, visionOS 26, *) {
				Slider(value: $timeMachine.offset, in: timeMachine.range, step: sliderStep, neutralValue: 0) {
					Text("Offset")
				} currentValueLabel: {
					Text(timeMachine.formattedOffset)
				} minimumValueLabel: {
					ValueLabel(text: minimumValueLabel(timeMachine, timeZone))
				} maximumValueLabel: {
					ValueLabel(text: maximumValueLabel(timeMachine, timeZone))
				}
			} else {
				fallbackSlider
			}
#endif
			
			if enableDatePicker && timeMachine.interfaceState.datePickerVisible {
				DatePicker(selection: $timeMachine.date, displayedComponents: datePickerComponents) {
					datePickerLabel(timeMachine, timeZone)
				}
			}
		}
	}
}

private extension TimeMachineView {
	@ViewBuilder
	private var toggleButtonLabel: some View {
		HStack {
			Image(systemName: "chevron.forward")
				.rotationEffect(timeMachine.interfaceState.datePickerVisible ? .degrees(90) : .zero)
				.imageScale(.small)
				.foregroundStyle(.secondary)
			
			timeTravelLabel
		}
	}
	
	@ViewBuilder
	private var timeTravelLabel: some View {
		Label {
			Group {
				switch showAbsoluteTime {
				case .always:
					absoluteTimestampLabel(timeMachine, timeZone)
				case .never:
					if timeMachine.isActive {
						relativeTimestampLabel(timeMachine, timeZone)
					} else {
						label
					}
				case .datePickerVisible:
					if timeMachine.interfaceState.datePickerVisible {
						absoluteTimestampLabel(timeMachine, timeZone)
					} else if timeMachine.isActive {
						relativeTimestampLabel(timeMachine, timeZone)
					} else {
						label
					}
				}
			}
				.transition(.blurReplace)
				.contentTransition(.numericText())
				.animation(.default, value: timeMachine.date)
				.animation(.default, value: timeMachine.isActive)
		} icon: {
			Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
		}
	}
	
	@ViewBuilder private var fallbackSlider: some View {
		@Bindable var timeMachine = timeMachine
		
		if sliderStep <= 0 {
			Slider(value: $timeMachine.offset, in: timeMachine.range) {
				Text("Offset")
			} minimumValueLabel: {
				ValueLabel(text: minimumValueLabel(timeMachine, timeZone))
			} maximumValueLabel: {
				ValueLabel(text: maximumValueLabel(timeMachine, timeZone))
			}
		} else {
			Slider(value: $timeMachine.offset, in: timeMachine.range, step: sliderStep) {
				Text("Offset")
			} minimumValueLabel: {
				ValueLabel(text: minimumValueLabel(timeMachine, timeZone))
			} maximumValueLabel: {
				ValueLabel(text: maximumValueLabel(timeMachine, timeZone))
			}
		}
	}
}

private extension TimeMachineView {
	struct ValueLabel: View {
		var text: Text
		
		var body: some View {
			text
				.textScale(.secondary)
		}
	}
}

public extension TimeMachineView {
	init(
		sliderStep: Double = -1,
		enableDatePicker: Bool = true,
		showAbsoluteTime: AbsoluteTimeVisibility = .datePickerVisible,
		datePickerComponents: DatePickerComponents = [.date, .hourAndMinute],
		@ViewBuilder label: () -> L,
		absoluteTimestampLabel: @escaping LabelBuilder = { t, tz in
			var formatStyle = Date.FormatStyle()
			formatStyle.timeZone = tz ?? .autoupdatingCurrent
			let formatter = formatStyle.day().month().year().hour().minute()
			return Text(t.date, format: formatter)
		},
		relativeTimestampLabel: @escaping LabelBuilder = { t, tz in
			relativeTimeStampBuilder(style: .date, timeMachine: t, timeZone: tz)
		},
		minimumValueLabel: @escaping LabelBuilder = { t, _ in
			Text(t.formatDuration(t.rangeLowerBoundSeconds))
		},
		maximumValueLabel: @escaping LabelBuilder = { t, _ in
			Text(t.formatDuration(t.rangeUpperBoundSeconds))
		},
		datePickerLabel: @escaping LabelBuilder = { _, _ in
			Text("Choose date/time")
		}
	) {
		self.sliderStep = sliderStep
		self.enableDatePicker = enableDatePicker
		self.showAbsoluteTime = showAbsoluteTime
		self.datePickerComponents = datePickerComponents
		self.label = label()
		self.absoluteTimestampLabel = absoluteTimestampLabel
		self.relativeTimestampLabel = relativeTimestampLabel
		self.minimumValueLabel = minimumValueLabel
		self.maximumValueLabel = maximumValueLabel
		self.datePickerLabel = datePickerLabel
	}
}

internal struct TimeMachineToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		Button {
			configuration.isOn.toggle()
		} label: {
			configuration.label
		}
		.contentShape(.rect)
		.buttonStyle(.plain)
	}
}

@MainActor public func relativeTimeStampBuilder(style: Text.DateStyle, timeMachine: TimeMachine, timeZone: TimeZone?) -> Text {
	Text("\(timeMachine.date, style: style) (\(timeMachine.formattedOffset))")
}

#Preview {
	TimeMachineView {
		Text("Time Travel")
	}
}
