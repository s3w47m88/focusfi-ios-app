import SwiftUI
import SwiftData

struct TransactionListView: View {
    let transactions: [Transaction]
    let modelContext: ModelContext

    @State private var isIncomeExpanded = false
    @State private var isExpenseExpanded = false
    @State private var incomeSortByDate = false
    @State private var expenseSortByDate = false

    private var incomeTransactions: [Transaction] {
        let filtered = transactions.filter { $0.type == .income }
        if incomeSortByDate {
            return filtered.sorted { $0.date > $1.date }
        } else {
            return filtered.sorted { $0.amount > $1.amount } // Largest to smallest
        }
    }

    private var expenseTransactions: [Transaction] {
        let filtered = transactions.filter { $0.type == .expense }
        if expenseSortByDate {
            return filtered.sorted { $0.date > $1.date }
        } else {
            return filtered.sorted { $0.amount < $1.amount } // Smallest to largest
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Income Section
            VStack(spacing: 0) {
                Button(action: { withAnimation(.spring(response: 0.3)) { isIncomeExpanded.toggle() } }) {
                    HStack {
                        Image(systemName: isIncomeExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Income")
                            .font(.headline)

                        Spacer()

                        Text("\(incomeTransactions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                }
                .buttonStyle(.plain)

                if isIncomeExpanded {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: { withAnimation { incomeSortByDate.toggle() } }) {
                                Label(
                                    incomeSortByDate ? "Sort by Amount" : "Sort by Date",
                                    systemImage: incomeSortByDate ? "dollarsign.circle" : "calendar"
                                )
                                .font(.caption)
                            }
                            .padding(.trailing)
                            .padding(.top, 8)
                        }

                        ForEach(incomeTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                        .onDelete { indexSet in
                            deleteIncomeTransactions(at: indexSet)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            // Expense Section
            VStack(spacing: 0) {
                Button(action: { withAnimation(.spring(response: 0.3)) { isExpenseExpanded.toggle() } }) {
                    HStack {
                        Image(systemName: isExpenseExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Expenses")
                            .font(.headline)

                        Spacer()

                        Text("\(expenseTransactions.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    }
                }
                .buttonStyle(.plain)

                if isExpenseExpanded {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: { withAnimation { expenseSortByDate.toggle() } }) {
                                Label(
                                    expenseSortByDate ? "Sort by Amount" : "Sort by Date",
                                    systemImage: expenseSortByDate ? "dollarsign.circle" : "calendar"
                                )
                                .font(.caption)
                            }
                            .padding(.trailing)
                            .padding(.top, 8)
                        }

                        ForEach(expenseTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                        .onDelete { indexSet in
                            deleteExpenseTransactions(at: indexSet)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func deleteIncomeTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = incomeTransactions[index]
            modelContext.delete(transaction)
        }
    }

    private func deleteExpenseTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = expenseTransactions[index]
            modelContext.delete(transaction)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(transaction.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(transaction.amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.type == .income ? Color.green : Color.red)

                    Text(transaction.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)

    return TransactionListView(transactions: [], modelContext: container.mainContext)
}
