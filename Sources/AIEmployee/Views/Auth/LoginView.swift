import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0a0f1e"), Color(hex: "0f172a"), Color(hex: "1e1b4b")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // Logo Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "3b82f6"), Color(hex: "6366f1")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: Color(hex: "3b82f6").opacity(0.5), radius: 20, x: 0, y: 10)

                            Text("🤖")
                                .font(.system(size: 44))
                        }

                        VStack(spacing: 6) {
                            Text("AI Employee")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Ihr KI-Assistent")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "94a3b8"))
                        }
                    }

                    // Login Form
                    VStack(spacing: 16) {
                        // Server URL
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundColor(Color(hex: "3b82f6"))
                                .frame(width: 20)
                            TextField("Server-URL (z.B. https://ai.example.com)", text: $viewModel.serverURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color(hex: "131929"))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "1e293b"), lineWidth: 1)
                        )

                        // Email
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundColor(Color(hex: "3b82f6"))
                                .frame(width: 20)
                            TextField("E-Mail-Adresse", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color(hex: "131929"))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "1e293b"), lineWidth: 1)
                        )

                        // Password
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundColor(Color(hex: "3b82f6"))
                                .frame(width: 20)
                            SecureField("Passwort", text: $viewModel.password)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color(hex: "131929"))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "1e293b"), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if viewModel.showError, let error = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "ef4444"))
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "ef4444"))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .background(Color(hex: "ef4444").opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "ef4444").opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Login Button
                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Anmelden")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: viewModel.canLogin
                                    ? [Color(hex: "3b82f6"), Color(hex: "6366f1")]
                                    : [Color(hex: "334155"), Color(hex: "334155")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(
                            color: viewModel.canLogin ? Color(hex: "3b82f6").opacity(0.4) : .clear,
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .disabled(!viewModel.canLogin)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.canLogin)

                    Spacer(minLength: 40)

                    // Version Info
                    VStack(spacing: 4) {
                        Text("AI Employee iOS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "475569"))
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "334155"))
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            viewModel.serverURL = authManager.baseURL
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showError)
    }
}
