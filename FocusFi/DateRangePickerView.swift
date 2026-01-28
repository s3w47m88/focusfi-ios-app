import SwiftUI

enum QuickDateRange: String, CaseIterable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case next7Days = "Next 7 Days"
    case next10Days = "Next 10 Days"
    case next30Days = "Next 30 Days"
    case next60Days = "Next 60 Days"
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case thisMonth = "This Month"
    case nextMonth = "Next Month"
}

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var showPicker: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Select") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(QuickDateRange.allCases, id: \.self) { range in
                            Button(action: { applyQuickRange(range) }) {
                                Text(range.rawValue)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Start Date") {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }

                Section("End Date") {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showPicker = false
                    }
                }
            }
        }
        .frame(width: 400, height: 700)
    }

    private func applyQuickRange(_ range: QuickDateRange) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch range {
        case .today:
            startDate = today
            endDate = today

        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            startDate = today
            endDate = tomorrow

        case .next7Days:
            startDate = today
            endDate = calendar.date(byAdding: .day, value: 6, to: today)!

        case .next10Days:
            startDate = today
            endDate = calendar.date(byAdding: .day, value: 9, to: today)!

        case .next30Days:
            startDate = today
            endDate = calendar.date(byAdding: .day, value: 29, to: today)!

        case .next60Days:
            startDate = today
            endDate = calendar.date(byAdding: .day, value: 59, to: today)!

        case .thisWeek:
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = weekday - calendar.firstWeekday
            let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            startDate = startOfWeek
            endDate = endOfWeek

        case .nextWeek:
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = weekday - calendar.firstWeekday
            let startOfThisWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
            let startOfNextWeek = calendar.date(byAdding: .day, value: 7, to: startOfThisWeek)!
            let endOfNextWeek = calendar.date(byAdding: .day, value: 6, to: startOfNextWeek)!
            startDate = startOfNextWeek
            endDate = endOfNextWeek

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: today)
            let firstOfMonth = calendar.date(from: components)!
            let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)!
            startDate = firstOfMonth
            endDate = lastOfMonth

        case .nextMonth:
            let components = calendar.dateComponents([.year, .month], from: today)
            let firstOfThisMonth = calendar.date(from: components)!
            let firstOfNextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfThisMonth)!
            let lastOfNextMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfNextMonth)!
            startDate = firstOfNextMonth
            endDate = lastOfNextMonth
        }
    }
}

#Preview {
    DateRangePickerView(
        startDate: .constant(Date()),
        endDate: .constant(Date()),
        showPicker: .constant(true)
    )
}
