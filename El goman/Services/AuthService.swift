//
//  AuthService.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import Foundation
import SwiftUI
import Observation

// MARK: - User Session Model
public struct UserSession: Codable, Equatable, Sendable {
    public var uid: String
    public var displayName: String
    public var email: String
    public var photoURL: String?
    public var avatarImageData: Data?
    public var idToken: String?
    public var refreshToken: String?
    public var notificationsEnabled: Bool
    public var paymentMethods: [String]
    public var location: LocationData

    public init(
        uid: String,
        displayName: String,
        email: String,
        photoURL: String? = nil,
        avatarImageData: Data? = nil,
        idToken: String? = nil,
        refreshToken: String? = nil,
        notificationsEnabled: Bool = true,
        paymentMethods: [String] = ["cuentadni", "modo"],
        location: LocationData = .bahiaBlanca
    ) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.avatarImageData = avatarImageData
        self.idToken = idToken
        self.refreshToken = refreshToken
        self.notificationsEnabled = notificationsEnabled
        self.paymentMethods = paymentMethods
        self.location = location
    }

    /// Usuario por defecto para Roberto Fiori
    public static var robertoDefault: UserSession {
        UserSession(
            uid: "roberto_fiori_default",
            displayName: "Roberto Fiori",
            email: "farenheit.com@gmail.com",
            photoURL: nil,
            notificationsEnabled: true,
            paymentMethods: ["cuentadni", "modo", "mercadopago"],
            location: .bahiaBlanca
        )
    }
}

// MARK: - Auth & Database Service
@Observable
public final class AuthService {
    public static let shared = AuthService()

    public var currentUser: UserSession? {
        didSet {
            saveSession()
        }
    }

    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    private let sessionKey = "elmango_user_session_v2"
    private let hasUserEverLoggedOutKey = "elmango_user_has_logged_out"
    private let firebaseApiKey = "AIzaSyD4Irym4YDnQoiVIZs5EcoXXE07CQ5_toY"
    private let projectId = "elchango-81e77"

    public init() {
        loadSession()
        let hasLoggedOut = UserDefaults.standard.bool(forKey: hasUserEverLoggedOutKey)
        if currentUser == nil && !hasLoggedOut {
            // Inicializar sesión por defecto de Roberto Fiori solo en primera apertura
            currentUser = .robertoDefault
        }
    }

    // MARK: - Persistence
    private func saveSession() {
        if let user = currentUser, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }

    private func loadSession() {
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let user = try? JSONDecoder().decode(UserSession.self, from: data) {
            self.currentUser = user
        }
    }

    // MARK: - Auth Actions
    public func signInWithGoogle() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        try? await Task.sleep(nanoseconds: 600_000_000)

        await MainActor.run {
            UserDefaults.standard.set(false, forKey: hasUserEverLoggedOutKey)
            self.currentUser = .robertoDefault
            self.isLoading = false
        }

        await fetchFirestoreUserData()
    }

    public func signInCustom(email: String, displayName: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            UserDefaults.standard.set(false, forKey: hasUserEverLoggedOutKey)
            self.currentUser = UserSession(
                uid: UUID().uuidString,
                displayName: displayName.isEmpty ? "Usuario ElMango" : displayName,
                email: email,
                notificationsEnabled: true,
                paymentMethods: ["cuentadni"],
                location: .bahiaBlanca
            )
            self.isLoading = false
        }
    }

    public func signOut() {
        UserDefaults.standard.set(true, forKey: hasUserEverLoggedOutKey)
        UserDefaults.standard.removeObject(forKey: sessionKey)
        self.currentUser = nil
    }

    public func updateAvatar(imageData: Data) {
        guard var user = currentUser else { return }
        user.avatarImageData = imageData
        self.currentUser = user
        Task {
            await syncUserToFirestore()
        }
    }

    public func updateNotifications(enabled: Bool) {
        guard var user = currentUser else { return }
        user.notificationsEnabled = enabled
        self.currentUser = user
        Task {
            await syncUserToFirestore()
        }
    }

    public func togglePaymentMethod(_ id: String) {
        guard var user = currentUser else { return }
        if user.paymentMethods.contains(id) {
            user.paymentMethods.removeAll { $0 == id }
        } else {
            user.paymentMethods.append(id)
        }
        self.currentUser = user
        Task {
            await syncUserToFirestore()
        }
    }

    // MARK: - Firestore Sync
    public func syncUserToFirestore() async {
        guard let user = currentUser else { return }
        let docUrl = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users/\(user.uid)?key=\(firebaseApiKey)"

        guard let url = URL(string: docUrl) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let fields: [String: Any] = [
            "displayName": ["stringValue": user.displayName],
            "email": ["stringValue": user.email],
            "notificationsEnabled": ["booleanValue": user.notificationsEnabled],
            "paymentMethods": [
                "arrayValue": [
                    "values": user.paymentMethods.map { ["stringValue": $0] }
                ]
            ],
            "city": ["stringValue": user.location.city],
            "zipCode": ["stringValue": user.location.zipCode]
        ]

        let body: [String: Any] = ["fields": fields]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await URLSession.shared.data(for: request)
        } catch {
            print("Error syncing to Firestore: \(error)")
        }
    }

    public func fetchFirestoreUserData() async {
        guard let user = currentUser else { return }
        let docUrl = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users/\(user.uid)?key=\(firebaseApiKey)"

        guard let url = URL(string: docUrl) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Parsear datos de Firestore
            }
        } catch {
            print("Error fetching Firestore: \(error)")
        }
    }
}
