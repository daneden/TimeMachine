//
//  TimeMachineViewPreview.swift
//  TimeMachine
//
//  Created by Daniel Eden on 23/09/2025.
//

import SwiftUI
import TimeMachine

@available(iOS 26, macOS 26, visionOS 26, *)
private struct TimeMachineViewPreview: View {
	@Environment(\.timeMachine) var timeMachine

	var body: some View {
		NavigationStack {
			VStack(spacing: -40) {
				Spacer()
				Group {
					Text(timeMachine.date, style: .date)
						.font(.system(size: 32).leading(.tight))
						.fontWidth(.expanded)
						.fontWeight(.medium)

					Text(timeMachine.date, style: .time)
						.font(.system(size: 300).leading(.tight))
						.fontWidth(.compressed)
						.fontWeight(.ultraLight)
				}
				.frame(maxWidth: .infinity)
				.contentTransition(.numericText())
				.animation(.default, value: timeMachine.date)
				.foregroundStyle(.tint)
				Spacer()
			}
			.safeAreaBar(edge: .bottom) {
				TimeMachineView(
					sliderStep: 60,
					datePickerComponents: .hourAndMinute
				) {
					Text("Time Machine")
				} relativeTimestampLabel: { t, tz in
					relativeTimeStampBuilder(style: .time, timeMachine: t, timeZone: tz)
				}
				.padding()
				.clipped()
				#if os(visionOS)
					.glassBackgroundEffect(in: .rect(cornerRadius: 20, style: .continuous))
				#else
					.glassEffect(in: .rect(cornerRadius: 20, style: .continuous))
				#endif
					.scenePadding()
			}
		}
	}
}

#Preview {
	if #available(iOS 26, visionOS 26, watchOS 26, macOS 26, *) {
		TimeMachineViewPreview()
			.withTimeMachine(incrementUnit: .minute, incrementRange: -720 ... 720)
	}
}
