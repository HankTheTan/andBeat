import SwiftUI
import SwiftData

@Observable
final class SleepViewModel {
    private(set) var profile: CycleProfile?

    func load(profiles: [CycleProfile]) {
        profile = profiles.first
    }

    // MARK: - 昨晚睡眠（Mock · 符合排卵期特征）
    struct SleepStage: Identifiable {
        let id = UUID()
        let name: String
        let duration: Int   // 分钟
        let color: String   // hex
    }

    let lastNight = (
        bedtime:      "23:05",
        wakeTime:     "06:48",
        totalMin:     463,      // 7h 43min
        score:        82,
        latencyMin:   12,       // 入睡潜伏期
        avgHR:        58.0,
        avgHRV:       47.0,
        avgTemp:      36.68
    )

    var sleepStages: [SleepStage] { [
        SleepStage(name: "深睡",  duration: 112, color: "4A6FA5"),
        SleepStage(name: "REM",   duration: 98,  color: "7B9E87"),
        SleepStage(name: "浅睡",  duration: 253, color: "C4A882"),
    ]}

    var totalSleepFormatted: String {
        let h = lastNight.totalMin / 60
        let m = lastNight.totalMin % 60
        return "\(h)h \(m)min"
    }

    // MARK: - 今晚预测（基于周期阶段）
    var tonightForecast: (score: Int, bedtime: String, note: String) {
        switch profile?.currentPhase {
        case .menstrual:
            return (78, "22:30", "经期体温偏低，褪黑素分泌较早，早睡效果更好。")
        case .follicular:
            return (85, "23:00", "卵泡期睡眠质量通常最佳，入睡快、深睡比例高。")
        case .ovulation:
            return (76, "22:45", "BBT 升高会轻微延长入睡时间，比平时早 15 分钟上床更理想。")
        case .luteal:
            return (71, "22:15", "黄体酮升高维持体温，易造成夜间觉醒。凉爽的睡眠环境（18–19°C）有帮助。")
        case .none:
            return (80, "23:00", "记录你的周期以获取个性化睡眠建议。")
        }
    }

    var sleepTips: [(icon: String, title: String, body: String)] {
        switch profile?.currentPhase {
        case .ovulation, .luteal:
            return [
                ("thermometer.medium", "控制室温",  "18–20°C 是最佳睡眠温度，有助于平衡体温升高的影响"),
                ("moon.stars",         "减少屏幕",  "睡前 1 小时关闭蓝光，辅助褪黑素正常分泌"),
                ("leaf",               "镁补充",    "睡前食用少量坚果或香蕉，镁元素有助于放松神经"),
            ]
        default:
            return [
                ("moon.stars",  "固定作息",  "每天同一时间入睡和起床，稳定昼夜节律"),
                ("figure.yoga", "睡前舒展",  "5 分钟轻柔拉伸可降低皮质醇，缩短入睡时间"),
                ("drop",        "睡前水分",  "睡前 2 小时避免大量饮水，减少夜间觉醒"),
            ]
        }
    }
}
