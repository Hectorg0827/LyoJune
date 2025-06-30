import Foundation

/// Returns a human-readable time-ago string for a given date.
public func timeAgoString(from date: Date) -> String {
    let now = Date()
    let interval = now.timeIntervalSince(date)
    let minutes = Int(interval / 60)
    let hours = Int(interval / 3600)
    let days = Int(interval / 86400)
    if days > 0 {
        return "\(days)d ago"
    } else if hours > 0 {
        return "\(hours)h ago"
    } else if minutes > 0 {
        return "\(minutes)m ago"
    } else {
        return "Just now"
    }
}
