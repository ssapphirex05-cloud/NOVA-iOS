import Foundation
import UIKit

final class NovaPushManager {
    static let shared = NovaPushManager()

    private let baseURL = URL(string: "https://246830.9yy8ob5y94yx.mjtest.ru/nova_messenger_v1/")!
    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "nova.ios.push.registration")

    private enum Keys {
        static let authToken = "nova_ios_auth_token"
        static let fcmToken = "nova_ios_fcm_token"
        static let deviceID = "nova_ios_device_id"
        static let enabled = "nova_ios_push_enabled"
    }

    private init() {}

    func updateSession(authToken: String, enabled: Bool) {
        let auth = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if auth.isEmpty || !enabled {
            unregister(authOverride: auth.isEmpty ? nil : auth)
            defaults.set(false, forKey: Keys.enabled)
            if auth.isEmpty { defaults.removeObject(forKey: Keys.authToken) }
            return
        }

        defaults.set(auth, forKey: Keys.authToken)
        defaults.set(true, forKey: Keys.enabled)
        registerIfReady()
    }

    func updateFCMToken(_ token: String) {
        let normalized = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        defaults.set(normalized, forKey: Keys.fcmToken)
        registerIfReady()
    }

    private var deviceID: String {
        if let existing = defaults.string(forKey: Keys.deviceID), !existing.isEmpty { return existing }
        let id = UUID().uuidString
        defaults.set(id, forKey: Keys.deviceID)
        return id
    }

    private func registerIfReady() {
        guard defaults.bool(forKey: Keys.enabled),
              let auth = defaults.string(forKey: Keys.authToken), !auth.isEmpty,
              let fcm = defaults.string(forKey: Keys.fcmToken), !fcm.isEmpty else { return }

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        request(method: "POST", auth: auth, body: [
            "token": fcm,
            "deviceId": deviceID,
            "appVersion": version
        ])
    }

    private func unregister(authOverride: String? = nil) {
        let auth = authOverride ?? defaults.string(forKey: Keys.authToken) ?? ""
        let fcm = defaults.string(forKey: Keys.fcmToken) ?? ""
        guard !auth.isEmpty else { return }
        request(method: "DELETE", auth: auth, body: ["token": fcm, "deviceId": deviceID])
    }

    private func request(method: String, auth: String, body: [String: Any]) {
        queue.async {
            guard let url = URL(string: "api.php?route=push/ios/subscribe", relativeTo: self.baseURL)?.absoluteURL else { return }
            var req = URLRequest(url: url, timeoutInterval: 9)
            req.httpMethod = method
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            URLSession.shared.dataTask(with: req).resume()
        }
    }
}
