import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var title: String
    var details: String
    var amount: Double
    var date: Date
    var type: TransactionType

    init(title: String, details: String, amount: Double, date: Date, type: TransactionType) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.amount = amount
        self.date = date
        self.type = type
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
    var balance: Double

    init(bankName: String, accountName: String, balance: Double) {
        self.id = UUID()
        self.bankName = bankName
        self.accountName = accountName
        self.balance = balance
    }
}
