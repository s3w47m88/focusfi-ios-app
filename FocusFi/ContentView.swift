import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var bankAccounts: [BankAccount]

    @State private var forecastedIncome: Double = 10000
    @State private var forecastedExpenses: Double = 8000
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showDatePicker = false
    @State private var showAddTransaction = false

    init() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let firstOfMonth = calendar.date(from: components)!
        let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth)!

        _startDate = State(initialValue: firstOfMonth)
        _endDate = State(initialValue: lastOfMonth)
    }

    var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
    }

    var currentIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var currentExpenses: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalBalance: Double {
        bankAccounts.reduce(0) { $0 + $1.balance }
    }

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Income Progress
                    FinanceProgressView(
                        title: "Income",
                        current: currentIncome,
                        forecast: forecastedIncome,
                        color: .green
                    )

                    // Expense Progress
                    FinanceProgressView(
                        title: "Expenses",
                        current: currentExpenses,
                        forecast: forecastedExpenses,
                        color: .red
                    )

                    // Transaction Lists
                    TransactionListView(transactions: filteredTransactions, modelContext: modelContext)

                    // Current Funds
                    CurrentFundsView(totalBalance: totalBalance)
                }
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("FocusFi")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showDatePicker.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(dateRangeText)
                                .font(.caption)
                        }
                    }
                    .popover(isPresented: $showDatePicker) {
                        DateRangePickerView(startDate: $startDate, endDate: $endDate, showPicker: $showDatePicker)
                            .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showAddTransaction = true }) {
                            Label("Add Transaction", systemImage: "plus.circle")
                        }

                        Divider()

                        Button(role: .destructive, action: clearAllData) {
                            Label("Clear All Data", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }

    private func clearAllData() {
        // Delete all transactions
        for transaction in transactions {
            modelContext.delete(transaction)
        }

        // Delete all bank accounts
        for account in bankAccounts {
            modelContext.delete(account)
        }

        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, BankAccount.self], inMemory: true)
}
