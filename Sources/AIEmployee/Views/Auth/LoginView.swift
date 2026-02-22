import SwiftUI

struct LoginView: View {
    @State private var viewModel = AuthViewModel()
    @Environment(AuthManager.self) var authManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Adaptive MeshGradient background — dark navy in dark mode, light blue in light mode
            meshGradientBackground
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

                            Image(systemName: "cpu.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 6) {
                            Text("AI Employee")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Ihr KI-Assistent")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }

                    // Login Form — glass card
                    VStack(spacing: 16) {
                        // Server URL
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 20)
                            TextField("Server-URL (z.B. https://ai.example.com)", text: $viewModel.serverURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .foregroundStyle(.primary)
                        }
                        .padding(16)
                        .glassEffect(in: .rect(cornerRadius: 14))

                        // Email
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 20)
                            TextField("E-Mail-Adresse", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .foregroundStyle(.primary)
                        }
                        .padding(16)
                        .glassEffect(in: .rect(cornerRadius: 14))

                        // Password
                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 20)
                            SecureField("Passwort", text: $viewModel.password)
                                .foregroundStyle(.primary)
                        }
                        .padding(16)
                        .glassEffect(in: .rect(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if viewModel.showError, let error = viewModel.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.appError)
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appError)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .glassEffect(in: .rect(cornerRadius: 12))
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
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 16))
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
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
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

    @ViewBuilder
    private var meshGradientBackground: some View {
        if colorScheme == .dark {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e"),
                Color(hex: "0f1b35"), Color(hex: "1a2744"), Color(hex: "0f1b35"),
                Color(hex: "0a0f1e"), Color(hex: "0f1b35"), Color(hex: "0a0f1e")
            ])
        } else {
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Color(hex: "e0f2fe"), Color(hex: "bfdbfe"), Color(hex: "e0f2fe"),
                Color(hex: "bfdbfe"), Color(hex: "dbeafe"), Color(hex: "bfdbfe"),
                Color(hex: "e0f2fe"), Color(hex: "bfdbfe"), Color(hex: "e0f2fe")
            ])
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager.shared)
}
