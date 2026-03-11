import SwiftUI
import SwiftData

private enum NextThirtyBucket: String, CaseIterable, Identifiable {
    case overdue = "Overdue"
    case today = "Today"
    case next7 = "Next 7"
    case day10 = "Day 10"
    case remainder = "Remainder"

    var id: String { rawValue }
}

struct TransactionListView: View {
    let transactions: [Transaction]
    let modelContext: ModelContext
    let isLoading: Bool

    @State private var isIncomeExpanded = false
    @State private var isExpenseExpanded = false

    @State private var selectedTransaction: Transaction?
    @State private var rowToCloseID: UUID?

    private var incomeTransactions: [Transaction] {
        transactions.filter { $0.type == .income }
    }

    private var expenseTransactions: [Transaction] {
        transactions.filter { $0.type == .expense }
    }

    private var totalIncome: Double {
        incomeTransactions.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        expenseTransactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 16) {
            sectionCard(
                title: "Income",
                total: totalIncome,
                color: .green,
                isExpanded: $isIncomeExpanded,
                transactions: incomeTransactions,
                isLoading: isLoading
            )

            sectionCard(
                title: "Expenses",
                total: totalExpenses,
                color: .red,
                isExpanded: $isExpenseExpanded,
                transactions: expenseTransactions,
                isLoading: isLoading
            )
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionEditorView(transaction: transaction)
        }
    }

    @ViewBuilder
    private func sectionCard(
        title: String,
        total: Double,
        color: Color,
        isExpanded: Binding<Bool>,
        transactions: [Transaction],
        isLoading: Bool
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.wrappedValue.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(title)
                        .font(.headline)

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }

                    Spacer()

                    Text("$\(total, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(spacing: 10) {
                    if isLoading {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading \(title.lowercased())...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } else {
                        ForEach(NextThirtyBucket.allCases) { bucket in
                            let items = bucketedTransactions(transactions, bucket: bucket)
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(bucket.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(items.count)")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.horizontal)

                                    ForEach(items) { transaction in
                                        TransactionRow(
                                            transaction: transaction,
                                            rowToCloseID: $rowToCloseID,
                                            onDelete: { delete(transaction) },
                                            onEdit: { openEditor(for: transaction) },
                                            onMarkPaid: {
                                                transaction.isPaid = true
                                                try? modelContext.save()
                                            },
                                            onPauseToggle: {
                                                transaction.isPaused.toggle()
                                                try? modelContext.save()
                                            },
                                            onReschedule: { openEditor(for: transaction) }
                                        )
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func bucketedTransactions(_ items: [Transaction], bucket: NextThirtyBucket) -> [Transaction] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday),
              let plus7 = calendar.date(byAdding: .day, value: 7, to: endOfToday),
              let plus10 = calendar.date(byAdding: .day, value: 10, to: endOfToday),
              let plus30 = calendar.date(byAdding: .day, value: 30, to: endOfToday) else {
            return []
        }

        let filtered: [Transaction] = items.filter { item in
            let d = sortableDate(for: item)
            switch bucket {
            case .overdue:
                return d < startOfToday
            case .today:
                return d >= startOfToday && d < endOfToday
            case .next7:
                return d >= endOfToday && d < plus7
            case .day10:
                return d >= plus7 && d < plus10
            case .remainder:
                return d >= plus10 && d <= plus30
            }
        }

        return filtered.sorted { sortableDate(for: $0) < sortableDate(for: $1) }
    }

    private func sortableDate(for transaction: Transaction) -> Date {
        transaction.dueDate ?? transaction.date
    }

    private func openEditor(for transaction: Transaction) {
        selectedTransaction = transaction
    }

    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @Binding var rowToCloseID: UUID?
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onMarkPaid: () -> Void
    let onPauseToggle: () -> Void
    let onReschedule: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var showActions = false
    @State private var isHorizontalSwipe = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button("Edit") {
                    resetSwipe()
                    onEdit()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 76, height: 40)
                .background(Color.blue.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(transaction.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if transaction.isPaid {
                            statusPill("Paid", color: .green)
                        }
                        if transaction.isPaused {
                            statusPill("Paused", color: .orange)
                        }

                        Spacer()

                        Text("$\(transaction.amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(transaction.type == .income ? Color.green : Color.red)
                    }

                    if !transaction.details.isEmpty {
                        Text(transaction.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        badge("Due \(displayDate(transaction.dueDate ?? transaction.date))", color: .blue)
                        if let suspensionDate = transaction.suspensionDate {
                            badge("Susp \(displayDate(suspensionDate))", color: .orange)
                        }
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
            .contentShape(Rectangle())
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let width = value.translation.width
                        let height = value.translation.height

                        if !isHorizontalSwipe {
                            isHorizontalSwipe = abs(width) > abs(height) && abs(width) > 20
                        }

                        guard isHorizontalSwipe else { return }

                        if width < 0 {
                            dragOffset = max(width, -88)
                        }
                    }
                    .onEnded { _ in
                        guard isHorizontalSwipe else {
                            dragOffset = 0
                            isHorizontalSwipe = false
                            return
                        }

                        withAnimation(.spring(response: 0.25)) {
                            if dragOffset < -44 {
                                dragOffset = -88
                                rowToCloseID = transaction.id
                            } else {
                                dragOffset = 0
                            }
                        }
                        isHorizontalSwipe = false
                    }
            )
            .onChange(of: rowToCloseID) { _, newID in
                if newID != transaction.id, dragOffset != 0 {
                    resetSwipe()
                }
            }
            .onTapGesture {
                showActions = true
            }
            .confirmationDialog("Transaction Options", isPresented: $showActions, titleVisibility: .visible) {
                Button("Edit") { onEdit() }
                Button("Mark as Paid") { onMarkPaid() }
                Button(transaction.isPaused ? "Resume" : "Pause") { onPauseToggle() }
                Button("Reschedule") { onReschedule() }
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func resetSwipe() {
        withAnimation(.spring(response: 0.25)) {
            dragOffset = 0
        }
    }

    private func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func badge(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func statusPill(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct TransactionEditorView: View {
    @Bindable var transaction: Transaction
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var amount: String
    @State private var type: TransactionType
    @State private var date: Date
    @State private var dueDateEnabled: Bool
    @State private var dueDate: Date
    @State private var suspensionEnabled: Bool
    @State private var suspensionDate: Date
    @State private var isPaid: Bool
    @State private var isPaused: Bool

    init(transaction: Transaction) {
        self.transaction = transaction
        _title = State(initialValue: transaction.title)
        _details = State(initialValue: transaction.details)
        _amount = State(initialValue: String(format: "%.2f", transaction.amount))
        _type = State(initialValue: transaction.type)
        _date = State(initialValue: transaction.date)
        let due = transaction.dueDate ?? transaction.date
        _dueDateEnabled = State(initialValue: transaction.dueDate != nil)
        _dueDate = State(initialValue: due)
        let suspension = transaction.suspensionDate ?? Date()
        _suspensionEnabled = State(initialValue: transaction.suspensionDate != nil)
        _suspensionDate = State(initialValue: suspension)
        _isPaid = State(initialValue: transaction.isPaid)
        _isPaused = State(initialValue: transaction.isPaused)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Transaction Type", selection: $type) {
                        Text("Income").tag(TransactionType.income)
                        Text("Expense").tag(TransactionType.expense)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $details)
                }

                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Dates") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Toggle("Due Date", isOn: $dueDateEnabled)
                    if dueDateEnabled {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }

                    Toggle("Suspension Date", isOn: $suspensionEnabled)
                    if suspensionEnabled {
                        DatePicker("Suspension Date", selection: $suspensionDate, displayedComponents: .date)
                    }
                }

                Section("Status") {
                    Toggle("Mark Paid", isOn: $isPaid)
                    Toggle("Paused", isOn: $isPaused)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && Double(amount) != nil
    }

    private func saveChanges() {
        guard let amountValue = Double(amount) else { return }

        transaction.title = title
        transaction.details = details
        transaction.amount = abs(amountValue)
        transaction.type = type
        transaction.date = date
        transaction.dueDate = dueDateEnabled ? dueDate : nil
        transaction.suspensionDate = suspensionEnabled ? suspensionDate : nil
        transaction.isPaid = isPaid
        transaction.isPaused = isPaused

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, configurations: config)
    let sample = Transaction(title: "Sample", details: "Test", amount: 120.0, date: .now, dueDate: .now, type: .expense)
    container.mainContext.insert(sample)

    return TransactionListView(transactions: [sample], modelContext: container.mainContext, isLoading: false)
}
