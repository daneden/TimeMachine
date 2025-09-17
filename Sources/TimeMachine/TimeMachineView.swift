//
//  SwiftUIView.swift
//  TimeMachine
//
//  Created by Daniel Eden on 17/09/2025.
//

import SwiftUI

public extension TimeMachineView {
	enum AbsoluteTimeVisibility {
		case always, never, datePickerVisible
	}
}

public struct TimeMachineView: View {
	@Environment(\.timeMachine) var timeMachine
	@Environment(\.timeZone) var timeZone
	
	let sliderStep: Double
	let enableDatePicker: Bool
	let showAbsoluteTime: AbsoluteTimeVisibility
	let datePickerComponents: DatePickerComponents
	@ViewBuilder let label: Text
	@ViewBuilder let datePickerLabel: Text
	
	init(
		sliderStep: Double = 1,
		enableDatePicker: Bool = true,
		datePickerComponents: DatePickerComponents = [.date, .hourAndMinute],
		showAbsoluteTime: AbsoluteTimeVisibility = .datePickerVisible,
		@ViewBuilder label: @escaping () -> Text = {
			Text("Time Travel")
		},
		@ViewBuilder datePickerLabel: @escaping () -> Text = {
			Text("Date")
		}) {
		self.sliderStep = sliderStep
		self.enableDatePicker = enableDatePicker
		self.datePickerComponents = datePickerComponents
		self.label = label()
		self.datePickerLabel = datePickerLabel()
		self.showAbsoluteTime = showAbsoluteTime
	}
	
	@State private var showDatePicker = false
	
	@ViewBuilder
	private var toggleButtonLabel: some View {
		HStack {
			Image(systemName: "chevron.forward")
				.rotationEffect(showDatePicker ? .degrees(90) : .zero)
				.imageScale(.small)
			
			timeTravelLabel
		}
	}
	
	@ViewBuilder
	private var timeTravelLabel: some View {
		Label {
			let labelValue: Text = {
				var formatStyle = Date.FormatStyle()
				formatStyle.timeZone = timeZone
				let formatter = formatStyle.day().month().year().hour().minute()
				
				switch showAbsoluteTime {
				case .always:
					return Text(timeMachine.date, format: formatter)
				case .never:
					if timeMachine.isActive {
						return Text(timeMachine.formattedOffset)
					}
				case .datePickerVisible:
					if showDatePicker {
						return Text(timeMachine.date, format: formatter)
					} else if timeMachine.isActive {
						return Text(timeMachine.formattedOffset)
					}
				}
				
				return label
			}()
			
			labelValue
				.contentTransition(.numericText())
				.animation(.default, value: timeMachine.date)
				.animation(.default, value: timeMachine.isActive)
		} icon: {
			Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
		}
	}
	
	@ViewBuilder private var fallbackSlider: some View {
		@Bindable var timeMachine = timeMachine
		Slider(value: $timeMachine.offset, in: timeMachine.range, step: sliderStep) {
			Text("Offset")
		} minimumValueLabel: {
			SliderValueLabel(timeMachine.formatDuration(timeMachine.rangeLowerBoundSeconds))
		} maximumValueLabel: {
			SliderValueLabel(timeMachine.formatDuration(timeMachine.rangeUpperBoundSeconds))
		}
	}
	
	public var body: some View {
		@Bindable var timeMachine = self.timeMachine
		
		VStack {
			HStack {
				if enableDatePicker {
					Toggle(isOn: $showDatePicker.animation()) {
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
			
			#if os(watchOS)
			fallbackSlider
			#else
			if #available(macOS 26, iOS 26, visionOS 26, *) {
				Slider(value: $timeMachine.offset, in: timeMachine.range, step: sliderStep, neutralValue: 0) {
					Text("Offset")
				} currentValueLabel: {
					Text(timeMachine.formattedOffset)
				} minimumValueLabel: {
					SliderValueLabel(timeMachine.formatDuration(timeMachine.rangeLowerBoundSeconds))
				} maximumValueLabel: {
					SliderValueLabel(timeMachine.formatDuration(timeMachine.rangeUpperBoundSeconds))
				}
			} else {
				fallbackSlider
			}
			#endif
			
			if enableDatePicker && showDatePicker {
				DatePicker(selection: $timeMachine.date, displayedComponents: datePickerComponents) {
					datePickerLabel
				}
			}
		}
	}
}

internal struct SliderValueLabel: View {
	var content: AttributedString
	
	init(_ content: String) {
		self.content = AttributedString(content)
	}
	
	var body: some View {
		Text(content)
			.textScale(.secondary)
	}
}

internal struct TimeMachineToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		Button {
			configuration.isOn.toggle()
		} label: {
			configuration.label
		}
	}
}

#if os(iOS)
@available(iOS 26, *)
private struct TimeMachineViewPreview: View {
	@Environment(\.timeMachine) var timeMachine
	
	var body: some View {
		NavigationStack {
			VStack {
				Spacer()
				Text(timeMachine.date, style: .time)
					.font(.system(size: 300))
					.fontWidth(.compressed)
					.fontWeight(.ultraLight)
					.frame(maxWidth: .infinity)
					.contentTransition(.numericText())
					.animation(.default, value: timeMachine.date)
					.foregroundStyle(.tint)
				Spacer()
			}
			.safeAreaBar(edge: .bottom) {
				TimeMachineView(sliderStep: 1, datePickerComponents: .hourAndMinute) {
					Text("Choose time")
				}
					.padding()
					.glassEffect(in: .rect(cornerRadius: 20, style: .continuous))
					.scenePadding()
			}
		}
		.preferredColorScheme(.dark)
	}
}

#Preview {
	if #available(iOS 26, visionOS 26, watchOS 26, macOS 26, *) {
		TimeMachineViewPreview()
			.withTimeMachine(incrementUnit: .hour, incrementRange: -12...12)
	}
}
#endif
