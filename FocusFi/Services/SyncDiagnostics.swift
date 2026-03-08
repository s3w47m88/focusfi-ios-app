import Foundation

enum SyncStatus: String {
    case idle
    case syncing
    case success
    case failure
}

struct SyncErrorContext {
    let endpoint: String
    let message: String
    let statusCode: Int?
    let timestamp: Date
}
