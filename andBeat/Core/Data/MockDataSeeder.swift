import Foundation
import SwiftData

// MARK: - Mock Data Seeder
// 模拟用户「林夏」过去 8 天的真实感健康数据
// 周期背景：28天周期，上次经期开始于13天前，当前处于排卵期(第14天)
// 数据特征：卵泡期末 → 排卵期，体温BBT升高，HRV微降，心率略升

final class MockDataSeeder {

    /// 仅在数据库为空时执行，避免重复写入
    static func seedIfNeeded(in context: ModelContext) {
        // 检查是否已有数据
        let profileDescriptor = FetchDescriptor<CycleProfile>()
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []
        guard existingProfiles.isEmpty else { return }

        // ── CycleProfile ──────────────────────────────────────────
        // 上次经期开始：13天前（当前为周期第14天，排卵期）
        let lastPeriodStart = Calendar.current.date(byAdding: .day, value: -13, to: Date())!
        let profile = CycleProfile(
            lastPeriodStart: lastPeriodStart,
            cycleLength: 28,
            periodLength: 5,
            userName: "林夏"
        )
        context.insert(profile)

        // ── DailyMetrics — 8 天数据 ──────────────────────────────
        // 数据设计依据：
        // 卵泡期(D7–D13)：基础体温 36.2–36.5°C，HRV 高位，心率平稳偏低
        // 排卵日(D14)：BBT出现0.3–0.5°C升幅，HRV轻微下降，心率略升
        // 所有数值加入±1–3% 的随机波动，模拟真实传感器数据
        let rawData: [(daysAgo: Int, hr: Double, temp: Double, hrv: Double, resp: Double)] = [
            // daysAgo  心率(bpm)  体温(°C)   HRV(ms)  呼吸(/min)
            (7,         67,        36.25,      58,       15),   // D7  卵泡期中段，能量恢复
            (6,         69,        36.30,      55,       15),   // D8  状态稳定上升
            (5,         71,        36.35,      53,       16),   // D9  雌激素继续升高
            (4,         72,        36.40,      50,       16),   // D10 接近排卵前期
            (3,         74,        36.45,      47,       16),   // D11 LH峰值前，轻微紧张
            (2,         76,        36.55,      44,       17),   // D12 LH surge开始，体温预升
            (1,         78,        36.72,      41,       17),   // D13 排卵前夜，BBT显著升高
            (0,         72,        36.68,      45,       16),   // D14 排卵日，心率稍回落，体温维持高位
        ]

        for entry in rawData {
            // 取当天 8:00 AM 作为记录时间点，模拟晨间同步
            var components  = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.day! -= entry.daysAgo
            components.hour   = 8
            components.minute = Int.random(in: 0...15)  // 8:00–8:15 微小波动
            let recordDate    = Calendar.current.date(from: components) ?? Date()

            // 加入 ±1–3% 真实感噪声
            let metrics = DailyMetrics(
                date:            recordDate,
                heartRate:       jitter(entry.hr,   range: 2),
                bodyTemperature: jitter(entry.temp,  range: 0.04),
                hrv:             jitter(entry.hrv,   range: 3),
                respiratoryRate: jitter(entry.resp,  range: 0.5)
            )
            context.insert(metrics)
        }

        // 保存
        try? context.save()
        print("✅ MockDataSeeder: 周期档案 + 8 天健康数据写入完成")
    }

    // 在基础值上叠加随机波动，模拟传感器精度
    private static func jitter(_ base: Double, range: Double) -> Double {
        let noise = Double.random(in: -range...range)
        return (base + noise * 0.5).rounded(toPlaces: 2)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
