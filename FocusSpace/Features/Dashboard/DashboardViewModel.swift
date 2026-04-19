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

    // MARK: - Year Pagination

    private var currentYear: Int {
        Self.gregorianCalendar.component(.year, from: Date())
    }

    var canGoBack: Bool {
        selectedYear > currentYear - AppConstants.Chart.maxYearsBack
    }

    var canGoForward: Bool {
        selectedYear < currentYear
    }

    var yearChartTitle: String {
        String(selectedYear)
    }

    private var cachedSessions: [Session] = []

    func updateStats(with sessions: [Session]) {
        cachedSessions = sessions
        todayStats = computeTodayStats(from: sessions)
        weeklyStats = computeWeekStats(from: sessions)
        weeklyData = computeWeeklyData(from: sessions)

        updatePeriodStats(with: sessions)
    }

    func updatePeriodStats(with sessions: [Session]) {
        cachedSessions = sessions
        switch selectedPeriod {
        case .week:
            periodStats = weeklyStats
            periodChartData = weeklyData
        case .year:
            periodStats = computeYearStats(from: sessions, year: selectedYear)
            periodChartData = computeYearData(from: sessions, year: selectedYear)
        }
    }

    func goToPreviousYear() {
        guard canGoBack else { return }
        selectedYear -= 1
        updatePeriodStats(with: cachedSessions)
    }

    func goToNextYear() {
        guard canGoForward else { return }
        selectedYear += 1
        updatePeriodStats(with: cachedSessions)
    }

    func resetSelectedYear() {
        selectedYear = currentYear
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

    private func computeWeekStats(from sessions: [Session]) -> StatsData {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        let weekSessions = sessions.filter { session in
            session.startAt >= weekAgo && session.startAt <= today
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

    private func computeWeeklyData(from sessions: [Session]) -> [DayData] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).compactMap { dayOffSet in
            guard let date = calendar.date(byAdding: .day, value: -dayOffSet, to: today) else { return nil }

            let daySessions = sessions.filter { session in
                calendar.isDate(session.startAt, inSameDayAs: date)
            }

            let focusSessions = daySessions.filter { $0.type == .focus }
            let totalMinutes = focusSessions.reduce(0) { $0 + $1.durationMinutes }

            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E" // Mon, Tue, Wed, etc.

            return DayData(day: dayFormatter.string(from: date), minutes: totalMinutes, date: date)
        }.reversed()
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
