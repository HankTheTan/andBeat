import SwiftUI
import SwiftData

// MARK: - Daily Tip Model (title + body, per A2 design)
struct DailyTip: Identifiable {
    let id = UUID()
    let sfSymbol: String   // SF Symbol name for icon
    let title: String
    let body: String
}

// MARK: - Today ViewModel
@Observable
final class TodayViewModel {
    private(set) var profile: CycleProfile?
    private(set) var todayMetrics: DailyMetrics?

    func load(profiles: [CycleProfile], metrics: [DailyMetrics]) {
        profile = profiles.first
        todayMetrics = metrics.first
    }

    // MARK: - Greeting (time-of-day)
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "早上好"
        case 12..<18: return "下午好"
        default:      return "晚上好"
        }
    }

    // MARK: - Date string
    var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: Date())
    }

    // MARK: - Status one-liner (rule-matched per phase; later: Claude API)
    var statusNote: String {
        switch profile?.currentPhase {
        case .menstrual:  return "身体正处于修复节奏，今天适合放慢脚步、给自己更多温柔。"
        case .follicular: return "能量正在回升，新的周期让一切重新开始。"
        case .ovulation:  return "身体处于活跃节奏，今天是表达与连接的好时机。"
        case .luteal:     return "趋于内敛的阶段，关注感受比完成清单更重要。"
        case .none:       return "记录你的周期，解锁每日身体洞察。"
        }
    }

    // MARK: - Today's tips (3 per phase, title + body)
    var dailyTips: [DailyTip] {
        switch profile?.currentPhase {
        case .menstrual:
            return [
                DailyTip(sfSymbol: "figure.walk", title: "低强度舒展",
                         body: "散步或轻柔瑜伽，让身体顺应自然节律"),
                DailyTip(sfSymbol: "fork.knife",  title: "补充铁质",
                         body: "深色叶菜、红肉或豆类，帮助补充流失矿物质"),
                DailyTip(sfSymbol: "bed.double",  title: "早睡优先",
                         body: "经期睡眠需求增加，21:30前进入休息准备"),
            ]
        case .follicular:
            return [
                DailyTip(sfSymbol: "figure.run",           title: "增加运动强度",
                         body: "雌激素上升，力量训练和跑步的效率都在提升"),
                DailyTip(sfSymbol: "brain.head.profile",   title: "启动新计划",
                         body: "思维最清晰的阶段，适合学习新技能或开始创意项目"),
                DailyTip(sfSymbol: "sun.max",              title: "多晒太阳",
                         body: "增加户外时间，促进维生素D合成，提升整体情绪"),
            ]
        case .ovulation:
            return [
                DailyTip(sfSymbol: "person.2",     title: "安排深度交流",
                         body: "排卵期社交直觉敏锐，适合面谈或重要会议"),
                DailyTip(sfSymbol: "dumbbell",     title: "中高强度运动",
                         body: "尝试30分钟跑步或力量训练，代谢效率最高"),
                DailyTip(sfSymbol: "drop",         title: "关注水分摄入",
                         body: "体温略升，今天比平时多喝300ml水"),
            ]
        case .luteal:
            return [
                DailyTip(sfSymbol: "figure.yoga",  title: "情绪优先",
                         body: "瑜伽和冥想有助于缓解黄体期焦虑感"),
                DailyTip(sfSymbol: "leaf",         title: "减少咖啡因",
                         body: "补充镁元素（坚果、香蕉）可减轻经前不适"),
                DailyTip(sfSymbol: "moon.zzz",     title: "建立睡眠仪式",
                         body: "睡眠质量可能下降，固定作息时间是最好的应对"),
            ]
        case .none:
            return [
                DailyTip(sfSymbol: "plus.circle", title: "记录你的周期",
                         body: "输入上次经期时间，开始你的健康追踪之旅"),
            ]
        }
    }
}
