import SwiftUI

private enum ShoppingDueDateMode: String, CaseIterable, Identifiable {
    case specificDate = "specific_date"
    case alwaysToday = "always_today"
    case alwaysThisWeek = "always_this_week"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .specificDate:
            return "Specific Date"
        case .alwaysToday:
            return "Always Today"
        case .alwaysThisWeek:
            return "Always This Week"
        }
    }
}

private enum ShoppingRecurrenceType: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case annually

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

private enum ShoppingAnnualMode: String, CaseIterable, Identifiable {
    case everyMonth = "every_month"
    case everyOtherMonth = "every_other_month"
    case quarterly
    case every6Months = "every_6_months"
    case specificMonths = "specific_months"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyMonth:
            return "Every Month"
        case .everyOtherMonth:
            return "Every Other Month"
        case .quarterly:
            return "Quarterly"
        case .every6Months:
            return "Every 6 Months"
        case .specificMonths:
            return "Specific Months"
        }
    }
}

private struct MonthOption: Identifiable {
    let id: Int
    let label: String
}

private let weekdayOptions: [(value: Int, label: String)] = [
    (0, "Sun"),
    (1, "Mon"),
    (2, "Tue"),
    (3, "Wed"),
    (4, "Thu"),
    (5, "Fri"),
    (6, "Sat")
]

private let weekOfMonthOptions: [(value: Int, label: String)] = [
    (1, "First"),
    (2, "Second"),
    (3, "Third"),
    (4, "Fourth"),
    (5, "Fifth")
]

private let monthOptions: [MonthOption] = DateFormatter().monthSymbols.enumerated().map {
    MonthOption(id: $0.offset + 1, label: $0.element)
}

struct ExpenseListsView: View {
    @StateObject private var shoppingListService = ShoppingListService.shared
    @State private var selectedList: APIShoppingList?
    @State private var showEditor = false
    @State private var deleteTarget: APIShoppingList?
    @State private var isDeleting = false

    var body: some View {
        List {
            if let errorMessage = shoppingListService.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }

            if shoppingListService.lists.isEmpty && !shoppingListService.isLoading {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Lists Yet")
                            .font(.headline)
                        Text("Create a shopping list that syncs into Expenses like the web app.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }

            ForEach(shoppingListService.lists) { list in
                Button {
                    selectedList = list
                    showEditor = true
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(list.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(currency(total(for: list)))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                        }

                        HStack(spacing: 8) {
                            badge("\(list.items.count) items", color: .blue)
                            if let dueDate = list.dueDate {
                                badge("Due \(displayDate(dueDate))", color: .orange)
                            } else if let dueDateMode = list.dueDateMode {
                                badge(dueDateModeLabel(dueDateMode), color: .orange)
                            }
                            if list.isRecurring {
                                badge((list.recurrenceType ?? "recurring").capitalized, color: .purple)
                            }
                            if list.linkedExpenseId != nil {
                                badge("Synced", color: .green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTarget = list
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Lists")
        .overlay {
            if shoppingListService.isLoading {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedList = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await shoppingListService.fetchLists()
        }
        .refreshable {
            await shoppingListService.fetchLists()
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                ExpenseListEditorView(expenseList: selectedList)
            }
        }
        .confirmationDialog(
            "Delete this list and its linked expense?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let deleteTarget else { return }
                Task {
                    isDeleting = true
                    defer {
                        isDeleting = false
                        self.deleteTarget = nil
                    }
                    try? await shoppingListService.deleteList(deleteTarget)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if isDeleting {
                Text("Deleting...")
            }
        }
    }

    private func total(for list: APIShoppingList) -> Double {
        list.items.reduce(0) { $0 + $1.price }
    }

    private func dueDateModeLabel(_ value: String) -> String {
        switch value {
        case ShoppingDueDateMode.alwaysToday.rawValue:
            return "Today"
        case ShoppingDueDateMode.alwaysThisWeek.rawValue:
            return "This Week"
        default:
            return "Specific Date"
        }
    }

    private func currency(_ value: Double) -> String {
        String(format: "$%.2f", value)
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
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct ExpenseListEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shoppingListService = ShoppingListService.shared

    let expenseList: APIShoppingList?

    @State private var title: String
    @State private var dueDateMode: ShoppingDueDateMode
    @State private var dueDate: Date
    @State private var isRecurring: Bool
    @State private var recurrenceType: ShoppingRecurrenceType
    @State private var selectedWeekdays: Set<Int>
    @State private var weekOfMonth: Int
    @State private var weekday: Int
    @State private var annualMode: ShoppingAnnualMode
    @State private var selectedMonths: Set<Int>
    @State private var items: [ShoppingListDraftItem]
    @State private var saveError: String?

    init(expenseList: APIShoppingList?) {
        self.expenseList = expenseList

        let dueMode = ShoppingDueDateMode(rawValue: expenseList?.dueDateMode ?? "") ?? .specificDate
        let recurrence = ShoppingRecurrenceType(rawValue: expenseList?.recurrenceType ?? "") ?? .weekly
        let config = expenseList?.recurrenceConfig ?? [:]

        _title = State(initialValue: expenseList?.title ?? "")
        _dueDateMode = State(initialValue: dueMode)
        _dueDate = State(initialValue: expenseList?.dueDate ?? Date())
        _isRecurring = State(initialValue: expenseList?.isRecurring ?? false)
        _recurrenceType = State(initialValue: recurrence)
        _selectedWeekdays = State(initialValue: Set(config["weekdays"]?.intArrayValue ?? [Calendar.current.component(.weekday, from: Date()) - 1]))
        _weekOfMonth = State(initialValue: config["weekOfMonth"]?.intValue ?? 1)
        _weekday = State(initialValue: config["weekday"]?.intValue ?? Calendar.current.component(.weekday, from: Date()) - 1)
        _annualMode = State(initialValue: ShoppingAnnualMode(rawValue: config["annualMode"]?.stringValue ?? "") ?? .everyMonth)
        _selectedMonths = State(initialValue: Set(config["months"]?.intArrayValue ?? [Calendar.current.component(.month, from: Date())]))
        _items = State(initialValue: expenseList?.items.map {
            ShoppingListDraftItem(
                remoteId: $0.id,
                title: $0.title,
                vendor: $0.vendor ?? "",
                link: $0.link ?? "",
                price: String(format: "%.2f", $0.price),
                dueDateEnabled: $0.dueDate != nil,
                dueDate: $0.dueDate ?? Date(),
                isPaid: $0.isPaid,
                isSkipped: $0.isSkipped,
                paymentDateEnabled: $0.paymentDate != nil,
                paymentDate: $0.paymentDate ?? Date(),
                paymentAccount: $0.paymentAccount ?? ""
            )
        } ?? [])
    }

    var body: some View {
        Form {
            if let saveError {
                Section {
                    Text(saveError)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }

            Section("List Details") {
                TextField("Title", text: $title)

                Picker("Due Date Mode", selection: $dueDateMode) {
                    ForEach(ShoppingDueDateMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                if dueDateMode == .specificDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }

            Section("Recurrence") {
                Toggle("Recurring", isOn: $isRecurring)

                if isRecurring {
                    Picker("Recurrence Type", selection: $recurrenceType) {
                        ForEach(ShoppingRecurrenceType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }

                    if recurrenceType == .weekly {
                        weekdayChips(title: "Weekdays", selection: $selectedWeekdays)
                    }

                    if recurrenceType == .monthly || recurrenceType == .annually {
                        Picker("Week of Month", selection: $weekOfMonth) {
                            ForEach(weekOfMonthOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }

                        Picker("Weekday", selection: $weekday) {
                            ForEach(weekdayOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                    }

                    if recurrenceType == .annually {
                        Picker("Annual Mode", selection: $annualMode) {
                            ForEach(ShoppingAnnualMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }

                        if annualMode == .specificMonths {
                            monthChips(selection: $selectedMonths)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("Sub Items")
                    Spacer()
                    Button {
                        items.append(ShoppingListDraftItem())
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }

                if items.isEmpty {
                    Text("No sub-items yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach($items) { $item in
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Item Title", text: $item.title)

                        HStack {
                            TextField("Vendor", text: $item.vendor)
                            TextField("Price", text: $item.price)
                                .keyboardType(.decimalPad)
                                .frame(width: 110)
                        }

                        TextField("Link", text: $item.link)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Toggle("Due Date", isOn: $item.dueDateEnabled)
                        if item.dueDateEnabled {
                            DatePicker("Item Due", selection: $item.dueDate, displayedComponents: .date)
                        }

                        Toggle("Paid", isOn: $item.isPaid)
                        Toggle("Skipped", isOn: $item.isSkipped)
                        Toggle("Payment Date", isOn: $item.paymentDateEnabled)
                        if item.paymentDateEnabled {
                            DatePicker("Payment Date", selection: $item.paymentDate, displayedComponents: .date)
                            TextField("Payment Account", text: $item.paymentAccount)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                }
            }
        }
        .navigationTitle(expenseList == nil ? "New List" : "Edit List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(shoppingListService.isSaving ? "Saving..." : "Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || shoppingListService.isSaving)
            }
        }
    }

    @ViewBuilder
    private func weekdayChips(title: String, selection: Binding<Set<Int>>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 8)], spacing: 8) {
                ForEach(weekdayOptions, id: \.value) { option in
                    Button(option.label) {
                        toggle(option.value, in: selection)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection.wrappedValue.contains(option.value) ? .blue : .gray)
                }
            }
        }
    }

    @ViewBuilder
    private func monthChips(selection: Binding<Set<Int>>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Months")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(monthOptions) { option in
                    Button(option.label) {
                        toggle(option.id, in: selection)
                    }
                    .buttonStyle(.bordered)
                    .tint(selection.wrappedValue.contains(option.id) ? .blue : .gray)
                }
            }
        }
    }

    private func toggle(_ value: Int, in selection: Binding<Set<Int>>) {
        if selection.wrappedValue.contains(value) {
            selection.wrappedValue.remove(value)
        } else {
            selection.wrappedValue.insert(value)
        }
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let draft = ShoppingListDraft(
            title: trimmedTitle,
            dueDateMode: dueDateMode.rawValue,
            dueDate: dueDate,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType.rawValue,
            selectedWeekdays: selectedWeekdays.isEmpty ? [weekday] : selectedWeekdays,
            weekOfMonth: weekOfMonth,
            weekday: weekday,
            annualMode: annualMode.rawValue,
            selectedMonths: selectedMonths.isEmpty ? [Calendar.current.component(.month, from: Date())] : selectedMonths,
            items: items
        )

        do {
            _ = try await shoppingListService.saveList(draft: draft, existing: expenseList)
            dismiss()
        } catch let error as APIError {
            saveError = error.errorDescription
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private extension JSONValue {
    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intArrayValue: [Int]? {
        guard case .array(let values) = self else { return nil }
        return values.compactMap { $0.intValue }
    }
}
