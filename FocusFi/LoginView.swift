import SwiftUI

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LoginView: View {
    @ObservedObject var authService = AuthService.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !authService.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(spacing: 24) {
                            // Logo/Title
                            VStack(spacing: 12) {
                                Text("FocusFi")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                                Text("An AI driven tool to automate insight and management into your finances.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)

                                if isSignUp {
                                    Text("Create your account")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                    // Form with glass effect
                    VStack(spacing: 16) {
                        // Email field
                        TextField("", text: $email)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(alignment: .leading) {
                                Text("Email")
                                    .foregroundColor(Color(white: 0.9))
                                    .font(.body)
                                    .padding(.leading, 16)
                                    .opacity(email.isEmpty ? 1 : 0)
                                    .allowsHitTesting(false)
                            }

                        // Password field
                        SecureField("", text: $password)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .submitLabel(.go)
                            .onSubmit {
                                if isFormValid {
                                    performAuth()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.4), lineWidth: 1)
                            )
                            .overlay(alignment: .leading) {
                                Text("Password")
                                    .foregroundColor(Color(white: 0.9))
                                    .font(.body)
                                    .padding(.leading, 16)
                                    .opacity(password.isEmpty ? 1 : 0)
                                    .allowsHitTesting(false)
                            }
                    }
                    .padding(.horizontal, 24)

                    // Error message
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Action button with glass effect
                    Button(action: performAuth) {
                        Group {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: isFormValid
                                                ? [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]
                                                : [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .disabled(!isFormValid)
                    .buttonStyle(.plain)

                    // Toggle sign up/sign in
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)

                    // Forgot password
                    if !isSignUp {
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Features card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 10) {
                            FeatureRow(icon: "brain", text: "Automatically categorize all of your transaction history using AI instead of basic rules.")

                            FeatureRow(icon: "link", text: "Generate shareable links to your income, expenses, debts and other financial views for your accountant, business partners, spouse, family and friends.")

                            FeatureRow(icon: "building.columns", text: "Link all of your institutions through Plaid and our custom APIs.")

                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Real-time dashboards with spending trends, income forecasts, and budget tracking.")

                            FeatureRow(icon: "bell.badge", text: "Smart alerts for unusual spending, upcoming bills, and low balance warnings.")

                            FeatureRow(icon: "lock.shield", text: "Bank-level encryption and security to protect your financial data.")

                            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Automatic sync across all your devices with real-time updates.")

                            FeatureRow(icon: "doc.text.magnifyingglass", text: "AI-powered insights and recommendations to optimize your financial health.")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.black.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .background {
                ZStack {
                    Image("BendMountains")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                Button("Cancel", role: .cancel) {}
                Button("Send Reset Link") {
                    Task {
                        try? await authService.resetPassword(email: email)
                    }
                }
            } message: {
                Text("Enter your email to receive a password reset link.")
            }
        }
    }

    private func performAuth() {
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                // Error is already handled in AuthService
            }
        }
    }
}

#Preview {
    LoginView()
}
