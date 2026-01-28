import Foundation

/// HTTP methods supported by the API
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// API error types
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String?)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// API response wrapper for error messages
struct APIErrorResponse: Codable {
    let error: String
}

/// HTTP client for making authenticated API requests
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 with fractional seconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try ISO8601 without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }

            // Try simple date format (YYYY-MM-DD)
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            if let date = simpleFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            try container.encode(dateString)
        }
    }

    // MARK: - Request Methods

    /// Make an authenticated GET request
    func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        return try await request(
            method: .get,
            endpoint: endpoint,
            queryItems: queryItems,
            body: nil as Empty?
        )
    }

    /// Make an authenticated POST request
    func post<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B
    ) async throws -> T {
        return try await request(
            method: .post,
            endpoint: endpoint,
            queryItems: nil,
            body: body
        )
    }

    /// Make an authenticated PUT request
    func put<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B
    ) async throws -> T {
        return try await request(
            method: .put,
            endpoint: endpoint,
            queryItems: nil,
            body: body
        )
    }

    /// Make an authenticated DELETE request
    func delete<T: Decodable>(endpoint: String) async throws -> T {
        return try await request(
            method: .delete,
            endpoint: endpoint,
            queryItems: nil,
            body: nil as Empty?
        )
    }

    // MARK: - Private Methods

    private func request<T: Decodable, B: Encodable>(
        method: HTTPMethod,
        endpoint: String,
        queryItems: [URLQueryItem]?,
        body: B?,
        retryCount: Int = 0
    ) async throws -> T {
        // Build URL
        var urlComponents = URLComponents(string: "\(APIConfig.apiBaseURL)\(endpoint)")
        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token
        do {
            let token = try await AuthService.shared.getAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } catch {
            throw APIError.unauthorized
        }

        // Add body if present
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        // Make request
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        // Handle response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                return try decoder.decode(T.self, from: data)
            } catch let decodingError as DecodingError {
                // Log detailed decoding error
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("[APIClient] Decoding error - Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("[APIClient] Decoding error - Type mismatch for \(type): \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("[APIClient] Decoding error - Value not found for \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("[APIClient] Decoding error - Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("[APIClient] Decoding error - Unknown: \(decodingError)")
                }
                // Also print first 500 chars of response for debugging
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("[APIClient] Response preview: \(String(responseStr.prefix(500)))")
                }
                throw APIError.decodingError(decodingError)
            } catch {
                throw APIError.decodingError(error)
            }

        case 401:
            // Unauthorized - try to refresh token and retry once
            if retryCount < 1 {
                do {
                    _ = try await AuthService.shared.refreshSession()
                    return try await self.request(
                        method: method,
                        endpoint: endpoint,
                        queryItems: queryItems,
                        body: body,
                        retryCount: retryCount + 1
                    )
                } catch {
                    throw APIError.unauthorized
                }
            }
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        default:
            // Try to decode error message
            let errorMessage = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(httpResponse.statusCode, errorMessage?.error)
        }
    }
}

/// Empty type for requests without body
private struct Empty: Codable {}
