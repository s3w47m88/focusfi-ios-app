import Foundation
import Supabase

/// Service for handling Supabase authentication
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    private let supabase: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private init() {
        // Initialize Supabase client
        guard let url = URL(string: APIConfig.supabaseURL), !APIConfig.supabaseURL.isEmpty else {
            fatalError("Invalid or missing SUPABASE_URL")
        }

        guard !APIConfig.supabaseAnonKey.isEmpty else {
            fatalError("Missing Supabase anon/public key")
        }

        self.supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: APIConfig.supabaseAnonKey
        )

        // Always require explicit sign-in on app launch
        self.isAuthenticated = false
    }

    // MARK: - Session Management

    /// Check if user has an existing valid session
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    /// Get current access token for API requests
    func getAccessToken() async throws -> String {
        let session = try await supabase.auth.session
        return session.accessToken
    }

    /// Refresh the session token
    func refreshSession() async throws -> String {
        let session = try await supabase.auth.refreshSession()
        return session.accessToken
    }

    // MARK: - Authentication Methods

    /// Sign up a new user
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            self.currentUser = response.user
            self.isAuthenticated = response.session != nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
}
