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

    private let sessionKey = "elmango_user_session_v1"
    private let firebaseApiKey = "AIzaSyD4Irym4YDnQoiVIZs5EcoXXE07CQ5_toY"
    private let projectId = "elchango-81e77"

    public init() {
        loadSession()
        if currentUser == nil {
            // Inicializar sesión por defecto de Roberto Fiori
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

        // Simular o conectar autenticación de Google con Firebase
        try? await Task.sleep(nanoseconds: 600_000_000)

        await MainActor.run {
            self.currentUser = .robertoDefault
            self.isLoading = false
        }

        // Intentar sincronizar datos desde Firestore si hay token
        await fetchFirestoreUserData()
    }

    public func signInCustom(email: String, displayName: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
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

    public func updateLocation(_ location: LocationData) {
        guard var user = currentUser else { return }
        user.location = location
        self.currentUser = user
        Task {
            await syncUserToFirestore()
        }
    }

    // MARK: - Firestore Database Synchronization
    public func fetchFirestoreUserData() async {
        guard let user = currentUser, let token = user.idToken else { return }
        let urlString = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users/\(user.uid)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Parsear datos de Firestore
                print("Firestore user data synchronized successfully")
            }
        } catch {
            print("Firestore fetch error: \(error.localizedDescription)")
        }
    }

    public func syncUserToFirestore() async {
        guard let user = currentUser, let token = user.idToken else { return }
        let urlString = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/users/\(user.uid)?updateMask.fieldPaths=paymentMethods&updateMask.fieldPaths=notifications"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "fields": [
                "notifications": ["booleanValue": user.notificationsEnabled],
                "paymentMethods": [
                    "arrayValue": [
                        "values": user.paymentMethods.map { ["stringValue": $0] }
                    ]
                ]
            ]
        ]

        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
