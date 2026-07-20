import Foundation
import UserNotifications

final class NotificationService {
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(
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
