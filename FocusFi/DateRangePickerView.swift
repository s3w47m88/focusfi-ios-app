import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var showPicker: Bool

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    Button("This Month") {
                        setCurrentMonth()
                    }

                    Button("Last Month") {
                        setLastMonth()
                    }

                    Button("This Year") {
                        setCurrentYear()
                    }
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
        .frame(width: 400, height: 600)
    }

    private func setCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let firstOfMonth = calendar.date(from: components)!
        let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)!

        startDate = firstOfMonth
        endDate = lastOfMonth
    }

    private func setLastMonth() {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: DateComponents(month: -1), to: now)!
        let components = calendar.dateComponents([.year, .month], from: lastMonth)
        let firstOfMonth = calendar.date(from: components)!
        let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)!

        startDate = firstOfMonth
        endDate = lastOfMonth
    }

    private func setCurrentYear() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: now)
        let firstOfYear = calendar.date(from: components)!
        let lastOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: firstOfYear)!

        startDate = firstOfYear
        endDate = lastOfYear
    }
}

#Preview {
    DateRangePickerView(
        startDate: .constant(Date()),
        endDate: .constant(Date()),
        showPicker: .constant(true)
    )
}
