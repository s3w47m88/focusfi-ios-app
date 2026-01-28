import Foundation

/// Configuration for API and Supabase connections
enum APIConfig {
    // MARK: - Environment

    #if DEBUG
    static let environment: Environment = .development
    #else
    static let environment: Environment = .production
    #endif

    enum Environment {
        case development
        case production

        var apiBaseHost: String {
            switch self {
            case .development:
                return "http://localhost:4243"
            case .production:
                return "https://api.yourfinanceapp.com"
            }
        }

        var apiScheme: String {
            switch self {
            case .development:
                return "http"
            case .production:
                return "https"
            }
        }
    }

    // MARK: - API Configuration

    static var apiBaseURL: String {
        let baseHost = configValue("API_BASE_URL") ?? environment.apiBaseHost
        return normalizedAPIBaseURL(from: baseHost)
    }

    // MARK: - Supabase Configuration
    // These values should be set from environment or secure storage
    // For now, they need to be configured before use

    static var supabaseURL: String {
        let rawValue = configValue("SUPABASE_URL") ?? ""
        return normalizedURL(from: rawValue, defaultScheme: "https")
    }

    static var supabaseAnonKey: String {
        configValue("SUPABASE_ANON_KEY")
            ?? configValue("SUPABASE_PUBLIC_KEY")
            ?? configValue("REACT_APP_SUPABASE_PUBLIC_KEY")
            ?? ""
    }

    // MARK: - Request Configuration

    static let requestTimeout: TimeInterval = 30
    static let maxRetryAttempts = 3

    private static func configValue(_ key: String) -> String? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !infoValue.isEmpty {
            return infoValue
        }
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        return nil
    }

    private static func normalizedAPIBaseURL(from baseHost: String) -> String {
        let normalizedHost = normalizedURL(from: baseHost, defaultScheme: environment.apiScheme)
        if normalizedHost.isEmpty {
            return ""
        }
        var trimmed = normalizedHost
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return "\(trimmed)/api"
    }

    private static func normalizedURL(from value: String, defaultScheme: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }
        if trimmed.contains("://") {
            return trimmed
        }
        return "\(defaultScheme)://\(trimmed)"
    }
}
