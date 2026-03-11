import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

enum AppearanceMode: String, CaseIterable {
    case auto = "Auto"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var bankAccounts: [BankAccount]

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showDatePicker = false
    @State private var showAddTransaction = false
    @State private var showLists = false
    @State private var isRefreshing = false
    @State private var syncErrorMessage: String?
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.auto.rawValue
    @StateObject private var transactionService = TransactionService.shared
    @StateObject private var accountService = AccountService.shared

    var currentAppearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .auto
    }

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysLater = calendar.date(byAdding: .day, value: 29, to: today)!

        _startDate = State(initialValue: today)
        _endDate = State(initialValue: thirtyDaysLater)
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
        bankAccounts
            .filter { $0.includeInTotal }
            .reduce(0) { $0 + $1.currentBalance }
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
                    if let syncErrorMessage {
                        syncErrorBanner(syncErrorMessage)
                    }

                    // Transaction Lists
                    TransactionListView(
                        transactions: filteredTransactions,
                        modelContext: modelContext,
                        isLoading: transactionService.isLoading
                    )

                    // Accounts
                    CurrentFundsView(
                        totalBalance: totalBalance,
                        isLoading: accountService.isLoading
                    )
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showLists = true }) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showAddTransaction = true }) {
                            Label("Add Transaction", systemImage: "plus.circle")
                        }

                        Divider()

                        Button(role: .destructive, action: clearAllData) {
                            Label("Clear All Data", systemImage: "trash")
                        }

                        Button(role: .destructive, action: signOut) {
                            Label("Sign Out", systemImage: "arrow.backward.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 0.5).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(isRefreshing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Button(action: { appearanceMode = mode.rawValue }) {
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        Image(systemName: currentAppearance.icon)
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showLists) {
                NavigationStack {
                    ExpenseListsView()
                }
            }
            .preferredColorScheme(currentAppearance.colorScheme)
            .onReceive(NotificationCenter.default.publisher(for: .focusFiDataShouldRefresh)) { _ in
                refreshData()
            }
            .task {
                await syncFromAPI()
            }
        }
    }

    @ViewBuilder
    private func syncErrorBanner(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sync Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            HStack(spacing: 12) {
                Button("Retry") {
                    refreshData()
                }
                .buttonStyle(.borderedProminent)

                #if DEBUG
                Button("Copy Diagnostics") {
                    copyDiagnosticsToClipboard()
                }
                .buttonStyle(.bordered)
                #endif
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private func signOut() {
        Task {
            try? await AuthService.shared.signOut()
            await MainActor.run {
                clearAllData()
            }
        }
    }

    private func refreshData() {
        Task {
            await syncFromAPI()
        }
    }

    private func syncFromAPI() async {
        await MainActor.run {
            isRefreshing = true
            syncErrorMessage = nil
        }

        let configurationIssues = APIConfig.configurationIssues()
        if !configurationIssues.isEmpty {
            await MainActor.run {
                syncErrorMessage = configurationIssues.joined(separator: " | ")
                isRefreshing = false
            }
            return
        }

        do {
            _ = try await AuthService.shared.getAccessToken()
        } catch {
            await MainActor.run {
                syncErrorMessage = "Authentication session unavailable. Please sign in again."
                isRefreshing = false
            }
            return
        }

        do {
            try await APIClient.shared.preflightConnectivityCheck()
        } catch let error as APIError {
            await MainActor.run {
                syncErrorMessage = "API preflight failed: \(error.errorDescription ?? "Unknown error")"
                isRefreshing = false
            }
            return
        } catch {
            await MainActor.run {
                syncErrorMessage = "API preflight failed: \(error.localizedDescription)"
                isRefreshing = false
            }
            return
        }

        await transactionService.fetchExpensesAndIncome()
        await accountService.fetchAccounts()

        await MainActor.run {
            persistTransactions(expenses: transactionService.expenses, income: transactionService.income)
            persistAccounts(accountService.accounts)
            syncErrorMessage = transactionService.errorMessage ?? accountService.errorMessage
            isRefreshing = false
        }
    }

    #if DEBUG
    private func copyDiagnosticsToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = diagnosticsText()
        #endif
    }
    #endif

    private func diagnosticsText() -> String {
        let formatter = ISO8601DateFormatter()
        let transactionSyncAt = transactionService.lastSyncAt.map { formatter.string(from: $0) } ?? "n/a"
        let accountSyncAt = accountService.lastSyncAt.map { formatter.string(from: $0) } ?? "n/a"
        let txError = transactionService.lastSyncError?.message ?? "none"
        let acctError = accountService.lastSyncError?.message ?? "none"

        return """
        FocusFi Sync Diagnostics
        apiBaseURL: \(APIConfig.apiBaseURL)
        transactionStatus: \(transactionService.lastSyncStatus.rawValue)
        transactionLastSyncAt: \(transactionSyncAt)
        transactionError: \(txError)
        accountStatus: \(accountService.lastSyncStatus.rawValue)
        accountLastSyncAt: \(accountSyncAt)
        accountError: \(acctError)
        """
    }

    private func persistTransactions(expenses: [APIExpense], income: [APIIncome]) {
        print("[ContentView] persistTransactions called with \(expenses.count) expenses, \(income.count) income")
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        for expense in expenses {
            let t = Transaction.fromExpense(expense)
            print("[ContentView] Inserting expense: \(t.title) - $\(t.amount)")
            modelContext.insert(t)
        }
        for incomeItem in income {
            let t = Transaction.fromIncome(incomeItem)
            print("[ContentView] Inserting income: \(t.title) - $\(t.amount)")
            modelContext.insert(t)
        }
        do {
            try modelContext.save()
            print("[ContentView] Saved \(expenses.count + income.count) transactions to SwiftData")
        } catch {
            print("[ContentView] Failed to save: \(error)")
        }
    }

    private func persistAccounts(_ apiAccounts: [APIAccount]) {
        let apiIds = Set(apiAccounts.map { $0.accountId })

        for account in bankAccounts where !(account.remoteId.map { apiIds.contains($0) } ?? false) {
            modelContext.delete(account)
        }

        for apiAccount in apiAccounts {
            let isCredit = apiAccount.type.lowercased().contains("credit")
            let available = apiAccount.balances.available ?? 0
            let current = apiAccount.balances.current ?? available
            let bankName = AccountService.inferBankName(from: apiAccount.name, fallback: apiAccount.type.capitalized)

            if let existing = bankAccounts.first(where: { $0.remoteId == apiAccount.accountId }) {
                existing.bankName = bankName
                existing.accountName = apiAccount.name
                existing.availableBalance = available
                existing.currentBalance = current
                existing.isCredit = isCredit
                existing.institutionId = apiAccount.itemId
            } else {
                modelContext.insert(
                    BankAccount(
                        bankName: bankName,
                        accountName: apiAccount.name,
                        availableBalance: available,
                        currentBalance: current,
                        includeInTotal: !isCredit,
                        isCredit: isCredit,
                        institutionId: apiAccount.itemId,
                        remoteId: apiAccount.accountId
                    )
                )
            }
        }
        try? modelContext.save()
    }

}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, BankAccount.self], inMemory: true)
}
