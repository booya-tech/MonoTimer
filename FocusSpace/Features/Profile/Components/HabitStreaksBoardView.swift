//
//  HabitStreaksBoardView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/12/26.
//

import SwiftUI

/// Monthly GitHub-style streaks board showing daily focus session activity.
struct HabitStreaksBoardView<VM: HabitStreaksBoardViewModelProtocol>: View {
    @ObservedObject var vm: VM

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppString.habitStreaksTitle)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)

            VStack(spacing: 12) {
                monthHeader
                streaksGrid
                opacityLegend
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
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.changeMonth(by: -1)
                }
            } label: {
                Image(systemName: AppConstants.Icon.chevronLeft)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
            }

            Spacer()

            Text(vm.monthYearString)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.primaryText)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.changeMonth(by: 1)
                }
            } label: {
                Image(systemName: AppConstants.Icon.chevronRight)
                    .font(AppTypography.body)
                    .foregroundColor(vm.canGoForward ? AppColors.secondaryText : AppColors.secondaryText.opacity(0.3))
            }
            .disabled(!vm.canGoForward)
        }
    }

    // MARK: - Streaks Grid

    private var streaksGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1...vm.daysInMonth, id: \.self) { day in
                let count = vm.sessionCountsByDay[day] ?? 0
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.primaryText.opacity(vm.opacityForCount(count)))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    // MARK: - Legend

    private var opacityLegend: some View {
        HStack(spacing: 4) {
            Spacer()

            Text("Less")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)

            ForEach([0.1, 0.25, 0.45, 0.65, 0.85, 1.0], id: \.self) { opacity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.primaryText.opacity(opacity))
                    .frame(width: 12, height: 12)
            }

            Text("More")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)

            Spacer()
        }
    }
}

#Preview {
    let vm = HabitStreaksBoardViewModel()

    HabitStreaksBoardView(vm: vm)
        .padding()
        .preferredColorScheme(.dark)
}
