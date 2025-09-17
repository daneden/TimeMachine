import Testing
import Foundation
@testable import TimeMachine

@Suite("Time Machine Tests") @MainActor struct TimeMachineTests {
	@Test func testDefaultInitialization() async throws {
		let tm = TimeMachine()
		#expect(tm.offset == 0)
		#expect(tm.incrementUnit == .day)
		#expect(tm.range == -12...12)
	}
	
	@Test func testDateCalculation() async throws {
		let ref = Date(timeIntervalSince1970: 0)
		let tm = TimeMachine(referenceDate: ref, incrementUnit: .day)
		tm.offset = 1
		#expect(Calendar.current.isDate(tm.date, inSameDayAs: ref.addingTimeInterval(86400)))
	}
	
	@Test func testSettingDateUpdatesOffset() async throws {
		let ref = Date(timeIntervalSince1970: 0)
		let tm = TimeMachine(referenceDate: ref, incrementUnit: .day)
		tm.date = ref.addingTimeInterval(2 * 86400)
		#expect(tm.offset == 2)
	}
	
	@Test func testFormattedOffset() async throws {
		let tm = TimeMachine()
		tm.offset = 2
		#expect(tm.formattedOffset.hasPrefix("+"))
	}
	
	@Test func testResetAndIsActive() async throws {
		let tm = TimeMachine()
		tm.offset = 5
		#expect(tm.isActive)
		tm.reset()
		#expect(!tm.isActive)
		#expect(tm.offset == 0)
	}
}
