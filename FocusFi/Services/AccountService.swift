import Foundation

/// API response model for accounts (from Plaid)
struct APIAccount: Codable, Identifiable {
    let accountId: String
    let name: String
    let type: String
    let subtype: String?
    let balances: AccountBalances
    let itemId: String?

    var id: String { accountId }

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case name
        case type
        case subtype
        case balances
        case itemId = "item_id"
    }
}

struct AccountBalances: Codable {
    let available: Double?
    let current: Double?
}

/// Response wrapper for accounts endpoint
struct AccountsResponse: Codable {
    let accounts: [APIAccount]
}

/// Service for fetching account information
@MainActor
class AccountService: ObservableObject {
    static let shared = AccountService()

    @Published var accounts: [APIAccount] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Fetch Accounts

    /// Fetch all connected bank accounts
    func fetchAccounts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result: AccountsResponse = try await apiClient.get(endpoint: "/plaid/accounts")
            self.accounts = result.accounts
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Get total balance across all accounts
    var totalBalance: Double {
        accounts.reduce(0) { $0 + ($1.balances.current ?? $1.balances.available ?? 0) }
    }

    /// Convert API accounts to local BankAccount models
    func toBankAccounts() -> [BankAccount] {
        accounts.map { apiAccount in
            let isCredit = apiAccount.type.lowercased().contains("credit")
            let available = apiAccount.balances.available ?? 0
            let current = apiAccount.balances.current ?? available
            let bankName = Self.inferBankName(from: apiAccount.name, fallback: apiAccount.type.capitalized)
            return BankAccount(
                bankName: bankName,
                accountName: apiAccount.name,
                availableBalance: available,
                currentBalance: current,
                includeInTotal: !isCredit,
                isCredit: isCredit,
                institutionId: apiAccount.itemId,
                remoteId: apiAccount.accountId
            )
        }
    }

    static func inferBankName(from accountName: String, fallback: String) -> String {
        let lower = accountName.lowercased()
        let knownBanks: [(name: String, matches: [String])] = [
            ("Chase", ["chase", "jpmorgan", "jp morgan", "jpm"]),
            ("Selco", ["selco"]),
            ("PayPal", ["paypal", "pay pal"]),
            ("Venmo", ["venmo"])
        ]

        for bank in knownBanks {
            if bank.matches.contains(where: { lower.contains($0) }) {
                if bank.name == "Chase" {
                    let businessHints = ["business", "biz", "ink", "commercial"]
                    if businessHints.contains(where: { lower.contains($0) }) {
                        return "Chase Business"
                    }
                    return "Chase Personal"
                }
                return bank.name
            }
        }

        let separators = [" - ", " • ", " | ", " / "]
        for separator in separators {
            if let range = accountName.range(of: separator) {
                let prefix = String(accountName[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !prefix.isEmpty {
                    return prefix
                }
            }
        }

        let typeWords: Set<String> = ["checking", "savings", "credit", "loan", "brokerage", "investment", "cash", "prepaid", "money", "market"]
        let words = accountName.split(separator: " ")
        if words.count > 1, let last = words.last, typeWords.contains(last.lowercased()) {
            let prefix = words.dropLast().joined(separator: " ")
            if !prefix.isEmpty {
                return prefix
            }
        }

        return fallback
    }
}
