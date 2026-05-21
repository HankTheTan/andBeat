import Foundation
import SwiftData

/// 每日身体数据快照
@Model
final class DailyMetrics {
    var date: Date
    var heartRate: Double?
    var bodyTemperature: Double?
    var hrv: Double?
    var respiratoryRate: Double?
    var notes: String?

    init(
        date: Date = Date(),
        heartRate: Double? = nil,
        bodyTemperature: Double? = nil,
        hrv: Double? = nil,
        respiratoryRate: Double? = nil,
        notes: String? = nil
    ) {
        self.date = date
        self.heartRate = heartRate
        self.bodyTemperature = bodyTemperature
        self.hrv = hrv
        self.respiratoryRate = respiratoryRate
        self.notes = notes
    }
}

// MARK: - Preview
extension DailyMetrics {
    static var preview: DailyMetrics {
        DailyMetrics(
            date: Date(),
            heartRate: 72,
            bodyTemperature: 36.5,
            hrv: 45,
            respiratoryRate: 16
        )
    }
}
