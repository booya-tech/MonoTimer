//
//  WeeklyChart.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/3/25.
//
//  Simple bar chart for weekly session data
//

import SwiftUI

/// Simple bar chart showing weekly or yearly focus session minutes
struct WeeklyChart: View {
    let data: [DayData]
    let title: String
    let maxHeight: CGFloat = 60
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var onGoBack: (() -> Void)? = nil
    var onGoForward: (() -> Void)? = nil

    private var maxMinutes: Int {
        data.map(\.minutes).max() ?? 1
    }

    private var hasPagination: Bool {
        onGoBack != nil || onGoForward != nil
    }

    var body: some View {
        VStack(spacing: 8) {
            if hasPagination {
                paginationHeader
            } else {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { dayData in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(dayData.minutes > 0 ? AppColors.primaryText : AppColors.secondaryBackground)
                            .frame(
                                width: 24,
                                height: max(4, CGFloat(dayData.minutes) / CGFloat(maxMinutes) * maxHeight)
                            )
                            .animation(.easeIn(duration: 0.2), value: dayData.minutes)

                        Text(dayData.day)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.secondaryBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.secondaryText.opacity(0.2), lineWidth: 1)
                }
        )
    }

    private var paginationHeader: some View {
        HStack {
            Button {
                onGoBack?()
            } label: {
                Image(systemName: AppConstants.Icon.chevronLeft)
                    .font(AppTypography.caption)
                    .foregroundColor(canGoBack ? AppColors.primaryText : AppColors.secondaryText.opacity(0.3))
            }
            .disabled(!canGoBack)

            Spacer()

            Text(title)
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primaryText)

            Spacer()

            Button {
                onGoForward?()
            } label: {
                Image(systemName: AppConstants.Icon.chevronRight)
                    .font(AppTypography.caption)
                    .foregroundColor(canGoForward ? AppColors.primaryText : AppColors.secondaryText.opacity(0.3))
            }
            .disabled(!canGoForward)
        }
    }
}

#Preview("Weekly — No Pagination") {
    WeeklyChart(
        data: [
            DayData(day: "Mon", minutes: 45, date: Date()),
            DayData(day: "Tue", minutes: 60, date: Date()),
            DayData(day: "Wed", minutes: 30, date: Date()),
            DayData(day: "Thu", minutes: 75, date: Date()),
            DayData(day: "Fri", minutes: 10, date: Date()),
            DayData(day: "Sat", minutes: 80, date: Date()),
            DayData(day: "Sun", minutes: 60, date: Date()),
        ],
        title: "Week"
    )
    .padding()
}

#if DEBUG
#Preview("Yearly — With Pagination") {
    struct YearlyPaginationPreview: View {
        private let currentYear = Calendar.current.component(.year, from: Date())
        private let mockData = AppConstants.MockData.yearlyChartData

        @State private var selectedYear = Calendar.current.component(.year, from: Date())

        var body: some View {
            WeeklyChart(
                data: mockData[selectedYear] ?? [],
                title: String(selectedYear),
                canGoBack: selectedYear > currentYear - AppConstants.Chart.maxYearsBack,
                canGoForward: selectedYear < currentYear,
                onGoBack: { selectedYear -= 1 },
                onGoForward: { selectedYear += 1 }
            )
            .padding()
        }
    }

    return YearlyPaginationPreview()
}
#endif
