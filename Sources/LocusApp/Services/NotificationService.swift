import Foundation
import UserNotifications

final class NotificationService {
    func authorizationStatus() async -> UNAuthorizationStatus {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return .notDetermined }
        return await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return false }
        return (try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        )) ?? false
    }

    func postRuleApplied(ssid: String, volume: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Locus 已应用规则"
        content.body = "\(ssid) · 系统音量 \(Int((volume * 100).rounded()))%"
        content.sound = nil
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
