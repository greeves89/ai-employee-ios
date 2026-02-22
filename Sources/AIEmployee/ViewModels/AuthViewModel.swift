import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var serverURL: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    private let authManager: AuthManager

    init(authManager: AuthManager = .shared) {
        self.authManager = authManager
        self.serverURL = authManager.baseURL
    }

    var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    func login() async {
        let trimmedURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURL.isEmpty else {
            showErrorMessage("Bitte geben Sie eine Server-URL ein.")
            return
        }
        guard !trimmedEmail.isEmpty else {
            showErrorMessage("Bitte geben Sie Ihre E-Mail-Adresse ein.")
            return
        }
        guard !password.isEmpty else {
            showErrorMessage("Bitte geben Sie Ihr Passwort ein.")
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        authManager.saveBaseURL(trimmedURL)

        do {
            try await authManager.login(email: trimmedEmail, password: password)
        } catch let error as APIError {
            showErrorMessage(error.errorDescription ?? "Anmeldung fehlgeschlagen.")
        } catch {
            showErrorMessage("Verbindungsfehler: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}
