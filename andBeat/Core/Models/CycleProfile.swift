import Foundation
import SwiftData

/// 用户的月经周期基础档案
@Model
final class CycleProfile {
    var lastPeriodStart: Date
    var cycleLength: Int
    var periodLength: Int
    var userName: String

    init(
        lastPeriodStart: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
        cycleLength: Int = 28,
        periodLength: Int = 5,
        userName: String = "PULSE User"
    ) {
        self.lastPeriodStart = lastPeriodStart
        self.cycleLength = cycleLength
        self.periodLength = periodLength
        self.userName = userName
    }

    var currentCycleDay: Int {
        let days = Calendar.current.dateComponents([.day], from: lastPeriodStart, to: Date()).day ?? 0
        let day = (days % cycleLength) + 1
        return max(1, day)
    }

    var currentPhase: CyclePhase {
        let day = currentCycleDay
        if day <= periodLength       { return .menstrual }
        else if day <= 13            { return .follicular }
        else if day <= 15            { return .ovulation }
        else                         { return .luteal }
    }

    var daysToNextPhase: Int {
        let day = currentCycleDay
        switch currentPhase {
        case .menstrual:  return periodLength - day + 1
        case .follicular: return 13 - day + 1
        case .ovulation:  return 15 - day + 1
        case .luteal:     return cycleLength - day + 1
        }
    }
}

enum CyclePhase: String, Codable {
    case menstrual  = "经期"
    case follicular = "卵泡期"
    case ovulation  = "排卵期"
    case luteal     = "黄体期"

    var description: String {
        switch self {
        case .menstrual:  return "身体正在自我更新，注意保暖和休息"
        case .follicular: return "雌激素上升，精力和状态都在变好"
        case .ovulation:  return "能量高峰期，适合重要事项和运动"
        case .luteal:     return "身体趋于平稳，关注情绪和睡眠质量"
        }
    }

    var nextPhaseName: String {
        switch self {
        case .menstrual:  return "卵泡期"
        case .follicular: return "排卵期"
        case .ovulation:  return "黄体期"
        case .luteal:     return "经期"
        }
    }
}

// MARK: - Preview
extension CycleProfile {
    static var preview: CycleProfile {
        CycleProfile(
            lastPeriodStart: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            cycleLength: 28,
            periodLength: 5,
            userName: "Hank"
        )
    }
}
