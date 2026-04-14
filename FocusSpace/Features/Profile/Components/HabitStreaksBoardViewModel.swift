//
//  HabitStreaksBoardViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/12/26.
//

import Foundation

@MainActor
protocol HabitStreaksBoardViewModelProtocol: ObservableObject {
    var displayedMonth: Date { get }
    var daysInMonth: Int { get }
    var monthYearString: String { get }
    var canGoForward: Bool { get }
    var sessionCountsByDay: [Int: Int] { get }
    func changeMonth(by value: Int)
    func opacityForCount(_ count: Int) -> Double
    func updateSessions(_ sessions: [Session])
}

/// ViewModel for the monthly habit streaks board.
@MainActor
final class HabitStreaksBoardViewModel: HabitStreaksBoardViewModelProtocol {
    @Published var displayedMonth: Date = Date()
    @Published private var sessions: [Session] = []

    private let calendar = Calendar.current

    func updateSessions(_ sessions: [Session]) {
        self.sessions = sessions
    }

    var daysInMonth: Int {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return 30
        }
        return range.count
    }

    var sessionCountsByDay: [Int: Int] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return [:]
        }

        let focusSessions = sessions.filter { session in
            session.type == .focus
                && session.startAt >= monthStart
                && session.startAt < monthEnd
        }

        var counts: [Int: Int] = [:]
        for session in focusSessions {
            let day = calendar.component(.day, from: session.startAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var canGoForward: Bool {
        let currentMonth = calendar.dateComponents([.year, .month], from: Date())
        let displayed = calendar.dateComponents([.year, .month], from: displayedMonth)
        if let current = calendar.date(from: currentMonth),
           let shown = calendar.date(from: displayed) {
            return shown < current
        }
        return false
    }

    func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else {
            return
        }

        let currentMonthComponents = calendar.dateComponents([.year, .month], from: Date())
        let newComponents = calendar.dateComponents([.year, .month], from: newMonth)

        guard let currentNormalized = calendar.date(from: currentMonthComponents),
              let newNormalized = calendar.date(from: newComponents) else {
            return
        }

        if newNormalized <= currentNormalized {
            displayedMonth = newMonth
        }
    }

    func opacityForCount(_ count: Int) -> Double {
        switch count {
        case 0: return 0.1
        case 1: return 0.25
        case 2: return 0.45
        case 3: return 0.65
        case 4: return 0.85
        default: return 1.0
        }
    }
}
