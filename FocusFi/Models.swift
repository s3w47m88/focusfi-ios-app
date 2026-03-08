import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var remoteId: String? // ID from API for sync
    var title: String
    var details: String
    var amount: Double
    var date: Date
    var dueDate: Date?
    var suspensionDate: Date?
    var type: TransactionType
    var isPaid: Bool
    var isPaused: Bool
    var isSynced: Bool // Track if synced with API

    init(
        title: String,
        details: String,
        amount: Double,
        date: Date,
        dueDate: Date? = nil,
        suspensionDate: Date? = nil,
        type: TransactionType,
        isPaid: Bool = false,
        isPaused: Bool = false,
        remoteId: String? = nil
    ) {
        self.id = UUID()
        self.remoteId = remoteId
        self.title = title
        self.details = details
        self.amount = amount
        self.date = date
        self.dueDate = dueDate
        self.suspensionDate = suspensionDate
        self.type = type
        self.isPaid = isPaid
        self.isPaused = isPaused
        self.isSynced = remoteId != nil
    }

    /// Create from API response
    static func fromAPI(_ apiTransaction: APITransaction) -> Transaction {
        let type: TransactionType = apiTransaction.type == "income" ? .income : .expense
        let date = parseDate(apiTransaction.date) ?? Date()
        let title = apiTransaction.title.isEmpty ? apiTransaction.name : apiTransaction.title
        let details = apiTransaction.details.isEmpty ? (apiTransaction.merchantName ?? "") : apiTransaction.details

        return Transaction(
            title: title,
            details: details,
            amount: abs(apiTransaction.amount),
            date: date,
            dueDate: date,
            type: type,
            remoteId: apiTransaction.id
        )
    }

    static func fromExpense(_ expense: APIExpense) -> Transaction {
        let dateString = expense.paymentDate ?? expense.dueDate ?? ""
        let date = parseDate(dateString) ?? Date()
        let dueDate = parseDate(expense.dueDate ?? "")
        let suspensionDate = parseDate(expense.paymentDate ?? "")
        let title = expense.name ?? "Expense"
        let details = expense.vendor ?? expense.notes ?? expense.groupName ?? expense.internalCategory ?? ""

        return Transaction(
            title: title,
            details: details,
            amount: abs(expense.amount),
            date: date,
            dueDate: dueDate ?? date,
            suspensionDate: suspensionDate,
            type: .expense,
            isPaid: expense.isPaid ?? false,
            remoteId: expense.id
        )
    }

    static func fromIncome(_ income: APIIncome) -> Transaction {
        let dateString = income.receivedDate ?? income.expectedByDate ?? ""
        let date = parseDate(dateString) ?? Date()
        let dueDate = parseDate(income.expectedByDate ?? "") ?? parseDate(income.receivedDate ?? "")
        let title = income.client ?? income.invoiceNumber ?? "Income"
        let details = income.invoiceNumber ?? income.notes ?? income.paymentProcessor ?? ""

        return Transaction(
            title: title,
            details: details,
            amount: abs(income.invoiceTotal),
            date: date,
            dueDate: dueDate ?? date,
            type: .income,
            isPaid: income.isPaid ?? false,
            remoteId: income.id
        )
    }

    static func parseDate(_ value: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        return simpleFormatter.date(from: value)
    }
}

enum TransactionType: String, Codable {
    case income
    case expense
}

@Model
final class ExpenseListItem {
    var id: UUID
    var title: String
    var amount: Double
    var dueDate: Date?
    var isPaid: Bool
    var notes: String
    var sortOrder: Int
    var parentList: ExpenseList?

    init(
        title: String,
        amount: Double,
        dueDate: Date? = nil,
        isPaid: Bool = false,
        notes: String = "",
        sortOrder: Int = 0,
        parentList: ExpenseList? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.notes = notes
        self.sortOrder = sortOrder
        self.parentList = parentList
    }
}

@Model
final class ExpenseList {
    var id: UUID
    var name: String
    var vendor: String
    var internalCategory: String
    var dueDate: Date?
    var frequency: String
    var recurrencePattern: String
    var isPaid: Bool
    var isRecurring: Bool
    var isShared: Bool
    var paymentDate: Date?
    var paymentAccount: String
    var linkedDebtId: String
    var linkedTransactionId: String
    var groupId: String
    var groupName: String
    var notes: String
    var isRecurringInstance: Bool
    var originalId: String
    var suspensionPeriodValue: Int?
    var suspensionPeriodUnit: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ExpenseListItem.parentList) var items: [ExpenseListItem]

    init(
        name: String,
        vendor: String = "",
        internalCategory: String = "",
        dueDate: Date? = nil,
        frequency: String = "",
        recurrencePattern: String = "",
        isPaid: Bool = false,
        isRecurring: Bool = false,
        isShared: Bool = false,
        paymentDate: Date? = nil,
        paymentAccount: String = "",
        linkedDebtId: String = "",
        linkedTransactionId: String = "",
        groupId: String = "",
        groupName: String = "",
        notes: String = "",
        isRecurringInstance: Bool = false,
        originalId: String = "",
        suspensionPeriodValue: Int? = nil,
        suspensionPeriodUnit: String = "",
        createdAt: Date = Date(),
        items: [ExpenseListItem] = []
    ) {
        self.id = UUID()
        self.name = name
        self.vendor = vendor
        self.internalCategory = internalCategory
        self.dueDate = dueDate
        self.frequency = frequency
        self.recurrencePattern = recurrencePattern
        self.isPaid = isPaid
        self.isRecurring = isRecurring
        self.isShared = isShared
        self.paymentDate = paymentDate
        self.paymentAccount = paymentAccount
        self.linkedDebtId = linkedDebtId
        self.linkedTransactionId = linkedTransactionId
        self.groupId = groupId
        self.groupName = groupName
        self.notes = notes
        self.isRecurringInstance = isRecurringInstance
        self.originalId = originalId
        self.suspensionPeriodValue = suspensionPeriodValue
        self.suspensionPeriodUnit = suspensionPeriodUnit
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class BankAccount {
    var id: UUID
    var bankName: String
    var accountName: String
    var availableBalance: Double
    var currentBalance: Double
    var includeInTotal: Bool
    var isFavorite: Bool
    var isCredit: Bool
    var institutionId: String?
    var remoteId: String?

    init(
        bankName: String,
        accountName: String,
        availableBalance: Double,
        currentBalance: Double,
        includeInTotal: Bool,
        isFavorite: Bool = false,
        isCredit: Bool,
        institutionId: String? = nil,
        remoteId: String? = nil
    ) {
        self.id = UUID()
        self.bankName = bankName
        self.accountName = accountName
        self.availableBalance = availableBalance
        self.currentBalance = currentBalance
        self.includeInTotal = includeInTotal
        self.isFavorite = isFavorite
        self.isCredit = isCredit
        self.institutionId = institutionId
        self.remoteId = remoteId
    }
}
