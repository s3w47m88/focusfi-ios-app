import Foundation
import os.log

private let logger = Logger(subsystem: "com.focusfi.app", category: "TransactionService")

struct APIExpense: Decodable, Identifiable {
    let id: String
    let name: String?
    let amount: Double
    let vendor: String?
    let internalCategory: String?
    let dueDate: String?
    let frequency: String?
    let recurrencePattern: String?
    let isPaid: Bool?
    let isRecurring: Bool?
    let isShared: Bool?
    let paymentDate: String?
    let paymentAccount: String?
    let linkedDebtId: String?
    let linkedTransactionId: String?
    let groupId: String?
    let groupName: String?
    let notes: String?
    let isRecurringInstance: Bool?
    let originalId: String?
    let suspensionPeriodValue: Int?
    let suspensionPeriodUnit: String?
}

struct APIIncome: Decodable, Identifiable {
    let id: String
    let client: String?
    let invoiceNumber: String?
    let invoiceLink: String?
    let invoiceTotal: Double
    let paidToDate: Double?
    let expectedByDate: String?
    let dependsOnCompletion: String?  // API returns string description, not bool
    let isPaid: Bool?
    let isRecurring: Bool?
    let isShared: Bool?
    let recurrencePattern: String?
    let notes: String?
    let receivedDate: String?
    let paymentProcessor: String?
    let groupId: String?
    let isRecurringInstance: Bool?
    let originalId: String?
}

/// API response model for transactions
struct APITransaction: Decodable, Identifiable {
    let id: String
    let transactionId: String
    let accountId: String
    let amount: Double
    let date: String
    let name: String
    let title: String
    let details: String
    let merchantName: String?
    let category: [String]?
    let pending: Bool
    let type: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case transactionId
        case accountId
        case amount
        case date
        case name
        case title
        case details
        case merchantName = "merchant_name"
        case category
        case pending
        case type
        case createdAt
    }

    enum AltCodingKeys: String, CodingKey {
        case merchantName = "merchantName"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let altContainer = try decoder.container(keyedBy: AltCodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.transactionId = try container.decode(String.self, forKey: .transactionId)
        self.accountId = try container.decode(String.self, forKey: .accountId)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.date = try container.decode(String.self, forKey: .date)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        self.name = decodedName ?? decodedTitle ?? ""
        self.title = decodedTitle ?? decodedName ?? ""
        let decodedDetails = try container.decodeIfPresent(String.self, forKey: .details)
        let decodedMerchantName = try container.decodeIfPresent(String.self, forKey: .merchantName)
            ?? altContainer.decodeIfPresent(String.self, forKey: .merchantName)
        self.details = decodedDetails ?? decodedMerchantName ?? ""
        self.merchantName = decodedMerchantName
        self.category = try container.decodeIfPresent([String].self, forKey: .category)
        self.pending = try container.decode(Bool.self, forKey: .pending)
        self.type = try container.decode(String.self, forKey: .type)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

/// Request model for creating/updating transactions
struct TransactionRequest: Codable {
    let title: String
    let details: String?
    let amount: Double
    let date: String
    let type: String
    let accountId: String?
    let category: [String]?
    let pending: Bool?

    init(
        title: String,
        details: String? = nil,
        amount: Double,
        date: Date,
        type: TransactionType,
        accountId: String? = nil,
        category: [String]? = nil,
        pending: Bool? = nil
    ) {
        self.title = title
        self.details = details
        self.amount = abs(amount) // Always send positive, type determines sign
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.string(from: date)
        self.type = type.rawValue
        self.accountId = accountId
        self.category = category
        self.pending = pending
    }
}

/// Request model for updating transactions (all fields optional)
struct TransactionUpdateRequest: Codable {
    let title: String?
    let details: String?
    let amount: Double?
    let date: String?
    let type: String?

    init(
        title: String? = nil,
        details: String? = nil,
        amount: Double? = nil,
        date: Date? = nil,
        type: TransactionType? = nil
    ) {
        self.title = title
        self.details = details
        self.amount = amount
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.date = formatter.string(from: date)
        } else {
            self.date = nil
        }
        self.type = type?.rawValue
    }
}

/// Response for delete operation
struct DeleteResponse: Codable {
    let success: Bool
    let id: String
}

/// Service for transaction CRUD operations
@MainActor
class TransactionService: ObservableObject {
    static let shared = TransactionService()

    @Published var transactions: [APITransaction] = []
    @Published var expenses: [APIExpense] = []
    @Published var income: [APIIncome] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Fetch Transactions

    func fetchExpensesAndIncome() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        logger.notice("Starting fetchExpensesAndIncome...")

        do {
            async let expensesResult: [APIExpense] = apiClient.get(endpoint: "/expenses")
            async let incomeResult: [APIIncome] = apiClient.get(endpoint: "/income")
            let (expenses, income) = try await (expensesResult, incomeResult)
            self.expenses = expenses
            self.income = income
            logger.notice("Fetched \(expenses.count) expenses, \(income.count) income items")
            let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
            let totalIncome = income.reduce(0) { $0 + $1.invoiceTotal }
            logger.notice("Total Expenses: $\(totalExpenses), Total Income: $\(totalIncome)")
        } catch let error as APIError {
            if case .decodingError(let underlyingError) = error {
                if let decodingError = underlyingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        self.errorMessage = "Missing key: \(key.stringValue)"
                    case .typeMismatch(let type, let context):
                        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                        self.errorMessage = "Type mismatch at '\(path)': expected \(type)"
                    case .valueNotFound(let type, let context):
                        let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                        self.errorMessage = "Null value at '\(path)': expected \(type)"
                    case .dataCorrupted(let context):
                        self.errorMessage = "Data corrupted: \(context.debugDescription)"
                    @unknown default:
                        self.errorMessage = "Decoding error: \(decodingError.localizedDescription)"
                    }
                } else {
                    self.errorMessage = error.errorDescription
                }
            } else {
                self.errorMessage = error.errorDescription
            }
            logger.error("APIError: \(self.errorMessage ?? "unknown")")
        } catch {
            self.errorMessage = error.localizedDescription
            logger.error("Error: \(error.localizedDescription)")
        }
    }

    /// Fetch all transactions with optional filters
    func fetchTransactions(
        startDate: Date? = nil,
        endDate: Date? = nil,
        type: TransactionType? = nil,
        accountId: String? = nil
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var queryItems: [URLQueryItem] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
        }
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
        }
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        if let accountId = accountId {
            queryItems.append(URLQueryItem(name: "account_id", value: accountId))
        }

        do {
            let result: [APITransaction] = try await apiClient.get(
                endpoint: "/transactions",
                queryItems: queryItems.isEmpty ? nil : queryItems
            )
            self.transactions = result
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Fetch a single transaction by ID
    func fetchTransaction(id: String) async -> APITransaction? {
        do {
            let result: APITransaction = try await apiClient.get(endpoint: "/transactions/\(id)")
            return result
        } catch {
            self.errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return nil
        }
    }

    // MARK: - Create Transaction

    /// Create a new transaction
    func createTransaction(
        title: String,
        details: String? = nil,
        amount: Double,
        date: Date,
        type: TransactionType
    ) async -> APITransaction? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = TransactionRequest(
            title: title,
            details: details,
            amount: amount,
            date: date,
            type: type
        )

        do {
            let result: APITransaction = try await apiClient.post(
                endpoint: "/transactions",
                body: request
            )
            // Add to local list
            self.transactions.insert(result, at: 0)
            return result
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            return nil
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Update Transaction

    /// Update an existing transaction
    func updateTransaction(
        id: String,
        title: String? = nil,
        details: String? = nil,
        amount: Double? = nil,
        date: Date? = nil,
        type: TransactionType? = nil
    ) async -> APITransaction? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = TransactionUpdateRequest(
            title: title,
            details: details,
            amount: amount.map { abs($0) },
            date: date,
            type: type
        )

        do {
            let result: APITransaction = try await apiClient.put(
                endpoint: "/transactions/\(id)",
                body: request
            )

            // Update local list
            if let index = self.transactions.firstIndex(where: { $0.id == id }) {
                self.transactions[index] = result
            }
            return result
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            return nil
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Delete Transaction

    /// Delete a transaction
    func deleteTransaction(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let _: DeleteResponse = try await apiClient.delete(endpoint: "/transactions/\(id)")
            // Remove from local list
            self.transactions.removeAll { $0.id == id }
            return true
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
