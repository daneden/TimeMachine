//
//  Environment+timeMachine.swift
//  TimeMachine
//
//  Created by Daniel Eden on 17/09/2025.
//

import SwiftUI

struct TimeMachineEnvironmentKey: EnvironmentKey {
	static let defaultValue: TimeMachine = .default
}

public extension EnvironmentValues {
	var timeMachine: TimeMachine {
		get { self[TimeMachineEnvironmentKey.self] }
		set { self[TimeMachineEnvironmentKey.self] = newValue }
	}
}
