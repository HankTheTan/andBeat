import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date

    enum Role { case user, assistant }
}

@Observable
final class AIViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var isTyping: Bool = false
    var inputText: String = ""
    var profile: CycleProfile?

    init() { seedConversation() }

    func load(profiles: [CycleProfile]) {
        profile = profiles.first
    }

    // MARK: - 预置对话（展示 AI 的数据感知能力）
    private func seedConversation() {
        let base = Date().addingTimeInterval(-300)
        messages = [
            ChatMessage(role: .assistant,
                        content: "林夏，今天是你周期的第 14 天，排卵期能量峰值。\n\n我注意到你的基础体温在昨天出现了 +0.17°C 的升幅——这是典型的排卵信号，说明排卵很可能已经发生。",
                        timestamp: base),
            ChatMessage(role: .user,
                        content: "今天感觉精力特别好，是正常的吗？",
                        timestamp: base.addingTimeInterval(60)),
            ChatMessage(role: .assistant,
                        content: "完全正常，而且是有生理依据的。\n\n排卵期雌激素和睾酮同时处于高位，大脑的神经可塑性和多巴胺分泌都在峰值。很多人在这个阶段会感到自信、社交欲强、思维清晰。\n\n这是你每月自然的能量高峰，适合安排重要会议、创意工作或高强度运动。",
                        timestamp: base.addingTimeInterval(90)),
        ]
    }

    // MARK: - 发送消息
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: text, timestamp: Date()))
        inputText = ""

        isTyping = true
        // 模拟 AI 响应延迟（实际接入 Claude API 后替换此处）
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            isTyping = false
            let response = generateMockResponse(for: text)
            messages.append(ChatMessage(role: .assistant, content: response, timestamp: Date()))
        }
    }

    // MARK: - 快速提问
    var quickPrompts: [String] {
        switch profile?.currentPhase {
        case .ovulation:
            return ["为什么我今天这么有活力？", "排卵期应该怎么运动？", "体温升高是排卵信号吗？"]
        case .luteal:
            return ["黄体期情绪波动怎么应对？", "为什么最近容易疲倦？", "今晚应该几点睡？"]
        case .menstrual:
            return ["经期应该避免什么运动？", "怎么缓解经期不适？", "经期饮食有什么建议？"]
        case .follicular:
            return ["卵泡期为什么脑子特别清楚？", "这阶段适合什么运动？", "雌激素怎么影响心情？"]
        case .none:
            return ["什么是基础体温？", "周期追踪有什么用？", "HRV 和睡眠有关系吗？"]
        }
    }

    // MARK: - Mock 响应生成器（接入 Claude API 前的占位逻辑）
    private func generateMockResponse(for input: String) -> String {
        let lower = input.lowercased()
        let phase = profile?.currentPhase

        if lower.contains("睡眠") || lower.contains("睡觉") || lower.contains("几点睡") {
            switch phase {
            case .ovulation:
                return "排卵期 BBT 升高，体温的变化会轻微延长入睡潜伏期。建议今晚比平时早 15 分钟上床，保持室温 18–19°C。\n\n你昨晚的 HRV 是 41ms，略低于本周均值，说明身体在适应激素变化——早睡对明天的恢复很有帮助。"
            default:
                return "根据你当前的周期阶段，建议在 22:30–23:00 之间入睡。保持固定作息时间是改善睡眠质量最有效的单一习惯。"
            }
        }

        if lower.contains("运动") || lower.contains("锻炼") || lower.contains("健身") {
            switch phase {
            case .ovulation:
                return "排卵期是全周期运动表现最佳的时段。雌激素和睾酮的协同作用让你的肌肉力量、耐力和恢复能力都处于高峰。\n\n今天可以尝试高强度间歇训练（HIIT）、力量训练或长跑，代谢效率会比经期高出约 20%。"
            case .luteal:
                return "黄体期适合中等强度的有氧运动。高强度训练可能加重孕酮引起的疲倦感。游泳、快走、瑜伽都是不错的选择，有助于稳定情绪。"
            case .menstrual:
                return "经期前两天建议以低强度活动为主——散步、拉伸、轻柔瑜伽。从第三天起如果感觉好转，可以逐渐增加强度。"
            default:
                return "卵泡期是开始新训练计划的好时机。雌激素上升会增强肌肉合成效率，这个阶段的力量训练效果尤其显著。"
            }
        }

        if lower.contains("体温") || lower.contains("bbt") {
            return "基础体温（BBT）是排卵追踪的核心指标。排卵后，孕酮分泌导致体温升高 0.2–0.5°C，并维持整个黄体期。\n\n你的传感器在昨天（D13）记录到 36.72°C，比前一天上升了 0.17°C——这符合排卵的标准特征。这个升幅会在接下来 10–14 天内持续。"
        }

        if lower.contains("hrv") || lower.contains("心率变异") {
            return "HRV 是衡量自主神经系统状态的指标，数值越高通常代表身体恢复越好、压力越低。\n\n你这周的 HRV 从 58ms（D7）下降到 41ms（D13），这是排卵期激素变化的正常反应，不需要担心。黄体期后半段 HRV 通常会回升。"
        }

        // 通用回复
        return "这是个好问题。根据你当前处于\(phase?.rawValue ?? "")阶段的数据，我需要了解更多细节才能给出更精准的建议。可以告诉我你具体想了解哪方面——睡眠、运动、情绪，还是其他的？"
    }
}
