//
//  DashboardViewModel.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/1/25.
//
//  Dashboard statistics and analytics logic
//

import Foundation

struct StatsData {
    var totalSessions: Int
    var totalMinutes: Int
    var longestStreak: Int
    var currentStreak: Int
    var dailyGoalProgress: Double  // 0.0 - 1.0
}

// Daily data for weekly chart
struct DayData: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
    let date: Date
}

@MainActor
/// View model for dashboard statistics and analytics
final class DashboardViewModel: ObservableObject {
    /// Gregorian calendar used for all year-based logic so that BE locales
    /// (e.g. Thai Buddhist) don't shift the displayed year or filter ranges.
    private static let gregorianCalendar = Calendar(identifier: .gregorian)

    @Published var selectedPeriod: TimePeriod = .week
    @Published var selectedYear: Int = DashboardViewModel.gregorianCalendar
        .component(.year, from: Date())
    /// Any date inside the currently selected week. Drives weekly pagination.
    @Published var selectedWeekAnchor: Date = Date()
    @Published var periodStats = StatsData(
        totalSessions: 0, totalMinutes: 0, longestStreak: 0, currentStreak: 0,
        dailyGoalProgress: 0.0
    )
    @Published var periodChartData: [DayData] = []

    @Published var todayStats = StatsData(
        totalSessions: 0, totalMinutes: 0, longestStreak: 0, currentStreak: 0, dailyGoalProgress: 0.0
    )
    @Published var weeklyStats = StatsData(
        totalSessions: 0, totalMinutes: 0, longestStreak: 0, currentStreak: 0, dailyGoalProgress: 0.0
    )
    @Published var weeklyData: [DayData] = []

    // Settings
    @Published var dailyGoalMinutes: Int = 120  // 2 hours daily goal

    // MARK: - Period Pagination

    private var currentYear: Int {
        Self.gregorianCalendar.component(.year, from: Date())
    }

    /// Start of the calendar week containing today (locale-aware first weekday).
    private var currentWeekStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            ?? calendar.startOfDay(for: Date())
    }

    /// Start of the calendar week containing `selectedWeekAnchor`.
    private var selectedWeekStart: Date {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: selectedWeekAnchor)?.start
            ?? calendar.startOfDay(for: selectedWeekAnchor)
    }

    /// Earliest week the user is allowed to paginate back to.
    private var earliestAllowedWeekStart: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -AppConstants.Chart.maxYearsBack, to: currentWeekStart)
            ?? currentWeekStart
    }

    var canGoBack: Bool {
        switch selectedPeriod {
        case .week:
            return selectedWeekStart > earliestAllowedWeekStart
        case .year:
            return selectedYear > currentYear - AppConstants.Chart.maxYearsBack
        }
    }

    var canGoForward: Bool {
        switch selectedPeriod {
        case .week:
            return selectedWeekStart < currentWeekStart
        case .year:
            return selectedYear < currentYear
        }
    }

    /// Title shown above the chart, dependent on the current period.
    var periodChartTitle: String {
        switch selectedPeriod {
        case .week:
            return weekChartTitle
        case .year:
            return yearChartTitle
        }
    }

    /// e.g. "Apr 13 – Apr 19".
    var weekChartTitle: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDateInclusive = calendar.date(byAdding: .day, value: 6, to: selectedWeekStart)
            ?? selectedWeekStart
        return "\(formatter.string(from: selectedWeekStart)) – \(formatter.string(from: endDateInclusive))"
    }

    var yearChartTitle: String {
        String(selectedYear)
    }

    private var cachedSessions: [Session] = []

    func updateStats(with sessions: [Session]) {
        cachedSessions = sessions
        todayStats = computeTodayStats(from: sessions)
        weeklyStats = computeWeekStats(from: sessions, anchor: Date())
        weeklyData = computeWeeklyData(from: sessions, anchor: Date())

        updatePeriodStats(with: sessions)
    }

    func updatePeriodStats(with sessions: [Session]) {
        cachedSessions = sessions
        switch selectedPeriod {
        case .week:
            periodStats = computeWeekStats(from: sessions, anchor: selectedWeekAnchor)
            periodChartData = computeWeeklyData(from: sessions, anchor: selectedWeekAnchor)
        case .year:
            periodStats = computeYearStats(from: sessions, year: selectedYear)
            periodChartData = computeYearData(from: sessions, year: selectedYear)
        }
    }

    func goToPrevious() {
        guard canGoBack else { return }
        switch selectedPeriod {
        case .week:
            let calendar = Calendar.current
            selectedWeekAnchor = calendar.date(byAdding: .day, value: -7, to: selectedWeekAnchor)
                ?? selectedWeekAnchor
        case .year:
            selectedYear -= 1
        }
        updatePeriodStats(with: cachedSessions)
    }

    func goToNext() {
        guard canGoForward else { return }
        switch selectedPeriod {
        case .week:
            let calendar = Calendar.current
            selectedWeekAnchor = calendar.date(byAdding: .day, value: 7, to: selectedWeekAnchor)
                ?? selectedWeekAnchor
        case .year:
            selectedYear += 1
        }
        updatePeriodStats(with: cachedSessions)
    }

    /// Resets pagination state for both periods back to the current week / year.
    func resetPeriodNavigation() {
        selectedYear = currentYear
        selectedWeekAnchor = Date()
    }

    // Update stats based on completed sessions
    private func computeTodayStats(from sessions: [Session]) -> StatsData {
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = sessions.filter { session in
            Calendar.current.isDate(session.startAt, inSameDayAs: today)
        }

        let focusSessions = todaySessions.filter { $0.type == .focus }
        let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }
        let progress = min(Double(totalMinutes) / Double(dailyGoalMinutes), 1.0)

        let currentStreak = computeCurrentStreak(from: sessions)
        let longestStreak = computeLongestStreak(from: sessions)

        return StatsData(
            totalSessions: focusSessions.count,
            totalMinutes: totalMinutes,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            dailyGoalProgress: progress
        )
    }

    private func computeWeekStats(from sessions: [Session], anchor: Date) -> StatsData {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start
            ?? calendar.startOfDay(for: anchor)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? anchor

        let weekSessions = sessions.filter { session in
            session.startAt >= weekStart && session.startAt < weekEnd
        }

        let focusSessions = weekSessions.filter { $0.type == .focus }
        let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }

        let currentStreak = computeCurrentStreak(from: sessions)
        let longestStreak = computeLongestStreak(from: sessions)

        return StatsData(
            totalSessions: focusSessions.count,
            totalMinutes: totalMinutes,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            dailyGoalProgress: 0.0
        )
    }

    private func computeWeeklyData(from sessions: [Session], anchor: Date) -> [DayData] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start
            ?? calendar.startOfDay(for: anchor)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E" // Mon, Tue, Wed, etc.

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }

            let focusSessions = sessions.filter { session in
                session.type == .focus && calendar.isDate(session.startAt, inSameDayAs: date)
            }
            let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }

            return DayData(day: dayFormatter.string(from: date), minutes: totalMinutes, date: date)
        }
    }

    private func computeYearStats(from sessions: [Session], year: Int) -> StatsData {
        let calendar = Self.gregorianCalendar
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1

        guard let yearStart = calendar.date(from: startComponents),
              let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)
        else {
            return StatsData(totalSessions: 0, totalMinutes: 0, longestStreak: 0, currentStreak: 0, dailyGoalProgress: 0.0)
        }

        let yearSessions = sessions.filter { $0.startAt >= yearStart && $0.startAt < yearEnd }
        let focusSessions = yearSessions.filter { $0.type == .focus }
        let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }

        return StatsData(
            totalSessions: focusSessions.count,
            totalMinutes: totalMinutes,
            longestStreak: computeLongestStreak(from: sessions),
            currentStreak: computeCurrentStreak(from: sessions),
            dailyGoalProgress: 0.0
        )
    }

    private func computeYearData(from sessions: [Session], year: Int) -> [DayData] {
        let calendar = Self.gregorianCalendar
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        return (1...12).compactMap { month in
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1

            guard let monthStart = calendar.date(from: components),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)
            else { return nil }

            let focusSessions = sessions.filter {
                $0.type == .focus && $0.startAt >= monthStart && $0.startAt < monthEnd
            }
            let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }

            return DayData(
                day: monthFormatter.string(from: monthStart),
                minutes: totalMinutes,
                date: monthStart
            )
        }
    }

    private func computeCurrentStreak(from sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var currentDate = today
        var streak = 0

        for _ in 0..<30 {  // Max 30 days lookback
            let daySessions = sessions.filter { session in
                calendar.isDate(session.startAt, inSameDayAs: currentDate) && session.type == .focus
            }

            if daySessions.isEmpty {
                break  // Streak broken
            }

            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate)
            else { break }
            currentDate = previousDate
        }

        return streak
    }

    private func computeLongestStreak(from sessions: [Session]) -> Int {
        let calendar = Calendar.current
        let allDates = Set(
            sessions.compactMap { session -> Date? in
                guard session.type == .focus else { return nil }

                return calendar.startOfDay(for: session.startAt)
            }
        ).sorted()

        guard !allDates.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<allDates.count {
            let previousDate = allDates[i - 1]
            let currentDate = allDates[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
                calendar.isDate(currentDate, inSameDayAs: nextDay)
            {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }
}
