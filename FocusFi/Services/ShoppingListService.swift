import Foundation

extension Notification.Name {
    static let focusFiDataShouldRefresh = Notification.Name("focusFiDataShouldRefresh")
}

enum JSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

struct APIShoppingListItem: Decodable, Identifiable, Equatable {
    let id: String
    let listId: String
    let title: String
    let vendor: String?
    let link: String?
    let price: Double
    let dateRequested: Date?
    let dueDate: Date?
    let isPaid: Bool
    let isSkipped: Bool
    let paymentDate: Date?
    let paymentAccount: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case listId = "list_id"
        case title
        case vendor
        case link
        case price
        case dateRequested = "date_requested"
        case dueDate = "due_date"
        case isPaid = "is_paid"
        case isSkipped = "is_skipped"
        case paymentDate = "payment_date"
        case paymentAccount = "payment_account"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APIShoppingList: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let status: String
    let dueDateMode: String?
    let dueDate: Date?
    let isRecurring: Bool
    let recurrencePattern: String?
    let recurrenceType: String?
    let recurrenceConfig: [String: JSONValue]?
    let linkedExpenseId: String?
    let items: [APIShoppingListItem]
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case dueDateMode = "due_date_mode"
        case dueDate = "due_date"
        case isRecurring = "is_recurring"
        case recurrencePattern = "recurrence_pattern"
        case recurrenceType = "recurrence_type"
        case recurrenceConfig = "recurrence_config"
        case linkedExpenseId = "linked_expense_id"
        case shoppingListItems = "shopping_list_items"
        case items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        dueDateMode = try container.decodeIfPresent(String.self, forKey: .dueDateMode)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        recurrencePattern = try container.decodeIfPresent(String.self, forKey: .recurrencePattern)
        recurrenceType = try container.decodeIfPresent(String.self, forKey: .recurrenceType)
        recurrenceConfig = try container.decodeIfPresent([String: JSONValue].self, forKey: .recurrenceConfig)
        linkedExpenseId = try container.decodeIfPresent(String.self, forKey: .linkedExpenseId)
        items =
            (try? container.decode([APIShoppingListItem].self, forKey: .shoppingListItems))
            ?? (try? container.decode([APIShoppingListItem].self, forKey: .items))
            ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

struct ShoppingListRequest: Encodable {
    let title: String
    let dueDateMode: String?
    let dueDate: Date?
    let isRecurring: Bool
    let recurrencePattern: String?
    let recurrenceType: String?
    let recurrenceConfig: [String: JSONValue]?
    let status: String?
    let linkedExpenseId: String?

    enum CodingKeys: String, CodingKey {
        case title
        case dueDateMode = "dueDateMode"
        case dueDate = "dueDate"
        case isRecurring = "isRecurring"
        case recurrencePattern = "recurrencePattern"
        case recurrenceType = "recurrenceType"
        case recurrenceConfig = "recurrenceConfig"
        case status
        case linkedExpenseId = "linkedExpenseId"
    }
}

struct ShoppingListItemRequest: Encodable {
    let title: String
    let vendor: String?
    let link: String?
    let price: Double
    let dueDate: Date?
    let isPaid: Bool?
    let isSkipped: Bool?
    let paymentDate: Date?
    let paymentAccount: String?

    enum CodingKeys: String, CodingKey {
        case title
        case vendor
        case link
        case price
        case dueDate = "dueDate"
        case isPaid = "isPaid"
        case isSkipped = "isSkipped"
        case paymentDate = "paymentDate"
        case paymentAccount = "paymentAccount"
    }
}

struct ShoppingExpenseSyncResponse: Decodable {
    let expense: APIExpense
    let total: Double
}

struct ShoppingListDraftItem: Identifiable, Equatable {
    let id: UUID
    var remoteId: String?
    var title: String
    var vendor: String
    var link: String
    var price: String
    var dueDateEnabled: Bool
    var dueDate: Date
    var isPaid: Bool
    var isSkipped: Bool
    var paymentDateEnabled: Bool
    var paymentDate: Date
    var paymentAccount: String

    init(
        id: UUID = UUID(),
        remoteId: String? = nil,
        title: String = "",
        vendor: String = "",
        link: String = "",
        price: String = "",
        dueDateEnabled: Bool = false,
        dueDate: Date = Date(),
        isPaid: Bool = false,
        isSkipped: Bool = false,
        paymentDateEnabled: Bool = false,
        paymentDate: Date = Date(),
        paymentAccount: String = ""
    ) {
        self.id = id
        self.remoteId = remoteId
        self.title = title
        self.vendor = vendor
        self.link = link
        self.price = price
        self.dueDateEnabled = dueDateEnabled
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isSkipped = isSkipped
        self.paymentDateEnabled = paymentDateEnabled
        self.paymentDate = paymentDate
        self.paymentAccount = paymentAccount
    }
}

struct ShoppingListDraft {
    var title: String
    var dueDateMode: String
    var dueDate: Date
    var isRecurring: Bool
    var recurrenceType: String
    var selectedWeekdays: Set<Int>
    var weekOfMonth: Int
    var weekday: Int
    var annualMode: String
    var selectedMonths: Set<Int>
    var items: [ShoppingListDraftItem]
}

@MainActor
final class ShoppingListService: ObservableObject {
    static let shared = ShoppingListService()

    @Published var lists: [APIShoppingList] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    private init() {}

    func fetchLists() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched: [APIShoppingList] = try await apiClient.get(endpoint: "/shopping-lists")
            lists = fetched.sorted {
                ($0.updatedAt ?? $0.createdAt ?? .distantPast) > ($1.updatedAt ?? $1.createdAt ?? .distantPast)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveList(draft: ShoppingListDraft, existing: APIShoppingList?) async throws -> APIShoppingList {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let request = ShoppingListRequest(
            title: draft.title,
            dueDateMode: draft.dueDateMode,
            dueDate: draft.dueDateMode == "specific_date" ? draft.dueDate : nil,
            isRecurring: draft.isRecurring,
            recurrencePattern: nil,
            recurrenceType: draft.isRecurring ? draft.recurrenceType : nil,
            recurrenceConfig: draft.isRecurring ? buildRecurrenceConfig(from: draft) : nil,
            status: existing?.status ?? "active",
            linkedExpenseId: existing?.linkedExpenseId
        )

        let baseList: APIShoppingList
        if let existing {
            baseList = try await apiClient.put(endpoint: "/shopping-lists/\(existing.id)", body: request)
        } else {
            baseList = try await apiClient.post(endpoint: "/shopping-lists", body: request)
        }

        let existingItems = Dictionary(uniqueKeysWithValues: baseList.items.map { ($0.id, $0) })
        let draftRemoteIds = Set(draft.items.compactMap(\.remoteId))

        for staleID in existingItems.keys where !draftRemoteIds.contains(staleID) {
            let _: DeleteResponse = try await apiClient.delete(endpoint: "/shopping-list-items/\(staleID)")
        }

        for item in draft.items {
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let request = ShoppingListItemRequest(
                title: title,
                vendor: emptyToNil(item.vendor),
                link: emptyToNil(item.link),
                price: Double(item.price) ?? 0,
                dueDate: item.dueDateEnabled ? item.dueDate : nil,
                isPaid: item.isPaid,
                isSkipped: item.isSkipped,
                paymentDate: item.paymentDateEnabled ? item.paymentDate : nil,
                paymentAccount: emptyToNil(item.paymentAccount)
            )

            if let remoteId = item.remoteId, existingItems[remoteId] != nil {
                let _: APIShoppingListItem = try await apiClient.put(
                    endpoint: "/shopping-list-items/\(remoteId)",
                    body: request
                )
            } else {
                let _: APIShoppingListItem = try await apiClient.post(
                    endpoint: "/shopping-lists/\(baseList.id)/items",
                    body: request
                )
            }
        }

        let _: ShoppingExpenseSyncResponse = try await apiClient.post(endpoint: "/shopping-lists/\(baseList.id)/sync-expense")
        let refreshed: APIShoppingList = try await apiClient.get(endpoint: "/shopping-lists/\(baseList.id)")
        await fetchLists()
        NotificationCenter.default.post(name: .focusFiDataShouldRefresh, object: nil)
        return refreshed
    }

    func deleteList(_ list: APIShoppingList) async throws {
        let _: DeleteResponse = try await apiClient.delete(endpoint: "/shopping-lists/\(list.id)")
        if let linkedExpenseId = list.linkedExpenseId {
            let _: DeleteResponse = try await apiClient.delete(endpoint: "/expenses/\(linkedExpenseId)")
        }
        await fetchLists()
        NotificationCenter.default.post(name: .focusFiDataShouldRefresh, object: nil)
    }

    private func buildRecurrenceConfig(from draft: ShoppingListDraft) -> [String: JSONValue]? {
        switch draft.recurrenceType {
        case "weekly":
            return [
                "weekdays": .array(draft.selectedWeekdays.sorted().map { .int($0) })
            ]
        case "monthly":
            return [
                "weekOfMonth": .int(draft.weekOfMonth),
                "weekday": .int(draft.weekday)
            ]
        case "annually":
            var config: [String: JSONValue] = [
                "annualMode": .string(draft.annualMode),
                "weekOfMonth": .int(draft.weekOfMonth),
                "weekday": .int(draft.weekday)
            ]
            if draft.annualMode == "specific_months" {
                config["months"] = .array(draft.selectedMonths.sorted().map { .int($0) })
            }
            return config
        default:
            return nil
        }
    }

    private func emptyToNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
