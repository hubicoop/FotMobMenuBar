import Foundation
import UserNotifications

struct NotificationService: Sendable {
    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func sendGoal(for match: Match) async {
        let content = UNMutableNotificationContent()
        content.title = "Goal!  \(match.score)"
        content.body = "\(match.home.name) - \(match.away.name)  \(match.minuteText)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "goal-\(match.id)-\(match.totalGoals)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
