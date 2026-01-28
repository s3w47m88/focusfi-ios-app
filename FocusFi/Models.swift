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
    var type: TransactionType
    var isSynced: Bool // Track if synced with API

    init(title: String, details: String, amount: Double, date: Date, type: TransactionType, remoteId: String? = nil) {
        self.id = UUID()
        self.remoteId = remoteId
        self.title = title
        self.details = details
        self.amount = amount
        self.date = date
        self.type = type
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
            type: type,
            remoteId: apiTransaction.id
        )
    }

    static func fromExpense(_ expense: APIExpense) -> Transaction {
        let dateString = expense.paymentDate ?? expense.dueDate ?? ""
        let date = parseDate(dateString) ?? Date()
        let title = expense.name ?? "Expense"
        let details = expense.vendor ?? expense.notes ?? expense.groupName ?? expense.internalCategory ?? ""

        return Transaction(
            title: title,
            details: details,
            amount: abs(expense.amount),
            date: date,
            type: .expense,
            remoteId: expense.id
        )
    }

    static func fromIncome(_ income: APIIncome) -> Transaction {
        let dateString = income.receivedDate ?? income.expectedByDate ?? ""
        let date = parseDate(dateString) ?? Date()
        let title = income.client ?? income.invoiceNumber ?? "Income"
        let details = income.invoiceNumber ?? income.notes ?? income.paymentProcessor ?? ""

        return Transaction(
            title: title,
            details: details,
            amount: abs(income.invoiceTotal),
            date: date,
            type: .income,
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
