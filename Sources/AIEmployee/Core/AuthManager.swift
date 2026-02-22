import Foundation
import SwiftUI

@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()

    var isLoggedIn: Bool = false
    var currentUser: User?
    var baseURL: String = ""

    private let userDefaultsBaseURLKey = "ai_employee_base_url"
    private let userDefaultsUserEmailKey = "ai_employee_user_email"
    private let userDefaultsUserIDKey = "ai_employee_user_id"
    private let userDefaultsUserNameKey = "ai_employee_user_name"
    private let userDefaultsLoggedInKey = "ai_employee_logged_in"

    private init() {
        loadSavedState()
    }

    // MARK: - State Persistence

    private func loadSavedState() {
        let savedURL = UserDefaults.standard.string(forKey: userDefaultsBaseURLKey) ?? ""
        let savedLoggedIn = UserDefaults.standard.bool(forKey: userDefaultsLoggedInKey)

        baseURL = savedURL
        APIClient.shared.configure(baseURL: savedURL)

        if savedLoggedIn,
           let savedID = UserDefaults.standard.string(forKey: userDefaultsUserIDKey),
           let savedEmail = UserDefaults.standard.string(forKey: userDefaultsUserEmailKey) {
            let savedName = UserDefaults.standard.string(forKey: userDefaultsUserNameKey)
            currentUser = User(id: savedID, email: savedEmail, name: savedName, role: nil, isActive: true)
            isLoggedIn = true
        }
    }

    private func saveUserState(user: User) {
        UserDefaults.standard.set(user.id, forKey: userDefaultsUserIDKey)
        UserDefaults.standard.set(user.email, forKey: userDefaultsUserEmailKey)
        UserDefaults.standard.set(user.name, forKey: userDefaultsUserNameKey)
        UserDefaults.standard.set(true, forKey: userDefaultsLoggedInKey)
    }

    private func clearUserState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsUserIDKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsUserEmailKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsUserNameKey)
        UserDefaults.standard.set(false, forKey: userDefaultsLoggedInKey)
    }

    // MARK: - Public Methods

    func saveBaseURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        baseURL = trimmed
        UserDefaults.standard.set(trimmed, forKey: userDefaultsBaseURLKey)
        APIClient.shared.configure(baseURL: trimmed)
    }

    func login(email: String, password: String) async throws {
        let user = try await APIClient.shared.login(email: email, password: password)
        currentUser = user
        isLoggedIn = true
        saveUserState(user: user)
    }

    func logout() async {
        await APIClient.shared.logout()
        currentUser = nil
        isLoggedIn = false
        clearUserState()
    }

    func forceLogout() {
        currentUser = nil
        isLoggedIn = false
        clearUserState()
    }
}
