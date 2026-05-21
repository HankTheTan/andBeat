import SwiftUI
import SwiftData

@Observable
final class CycleViewModel {
    private(set) var profile: CycleProfile?
    private(set) var recentMetrics: [DailyMetrics] = []

    func load(profiles: [CycleProfile], metrics: [DailyMetrics]) {
        profile = profiles.first
        // 按日期升序排列，用于 BBT 图表
        recentMetrics = metrics.sorted { $0.date < $1.date }
    }

    // MARK: - 28-day strip data
    struct DayCell {
        let day: Int
        let phase: CyclePhase
        let isToday: Bool
        let isFuture: Bool
    }

    var dayCells: [DayCell] {
        guard let profile else { return [] }
        let today = profile.currentCycleDay
        return (1...28).map { day in
            let phase: CyclePhase
            let pd = profile.periodLength
            if day <= pd              { phase = .menstrual }
            else if day <= 13         { phase = .follicular }
            else if day <= 15         { phase = .ovulation }
            else                      { phase = .luteal }
            return DayCell(day: day, phase: phase,
                           isToday: day == today, isFuture: day > today)
        }
    }

    // MARK: - BBT chart — 近 8 天体温数据
    struct TempPoint {
        let label: String   // "D7", "D8" …
        let value: Double
        let isToday: Bool
    }

    var tempPoints: [TempPoint] {
        guard let profile else { return [] }
        let today = profile.currentCycleDay
        return recentMetrics.compactMap { m -> TempPoint? in
            guard let temp = m.bodyTemperature else { return nil }
            let daysAgo = Calendar.current.dateComponents([.day], from: m.date, to: Date()).day ?? 0
            let cycleDay = today - daysAgo
            guard cycleDay > 0 else { return nil }
            return TempPoint(label: "D\(cycleDay)", value: temp, isToday: daysAgo == 0)
        }
    }

    // MARK: - 预测卡片
    var nextPeriodDays: Int {
        guard let profile else { return 0 }
        return profile.cycleLength - profile.currentCycleDay + 1
    }

    var nextOvulationDays: Int? {
        guard let profile, profile.currentPhase == .follicular else { return nil }
        return 13 - profile.currentCycleDay + 1
    }

    var phaseInsight: String {
        switch profile?.currentPhase {
        case .menstrual:
            return "子宫内膜正在脱落更新。这是整个周期的起点，身体的自我修复正在发生。"
        case .follicular:
            return "卵泡在雌激素的推动下快速发育。脑雾消散，认知能力和创造力正在回升。"
        case .ovulation:
            return "成熟卵泡破裂释放卵子。体温升幅 0.2–0.5°C 是排卵的可靠信号，你的传感器已记录到这一变化。"
        case .luteal:
            return "黄体分泌孕酮，体温维持高位。如未受孕，黄体在 10–14 天后退化，进入下一个周期。"
        case .none:
            return "记录你的周期，解锁完整的生理节律分析。"
        }
    }
}
