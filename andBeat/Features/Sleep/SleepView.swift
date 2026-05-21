import SwiftUI
import SwiftData

struct SleepView: View {
    @Query private var profiles: [CycleProfile]
    @State private var viewModel = SleepViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                SleepPageHeader(viewModel: viewModel)
                    .padding(.top, 18).padding(.horizontal, 24).padding(.bottom, 6)

                TonightForecastCard(viewModel: viewModel)
                    .padding(.top, 20).padding(.horizontal, 20)

                LastNightCard(viewModel: viewModel)
                    .padding(.top, 14).padding(.horizontal, 20)

                SleepStagesCard(viewModel: viewModel)
                    .padding(.top, 14).padding(.horizontal, 20)

                SleepTipsCard(viewModel: viewModel)
                    .padding(.top, 14).padding(.horizontal, 20)

                Spacer().frame(height: 32)
            }
        }
        .background(Pulse.bg.ignoresSafeArea())
        .onChange(of: profiles) { viewModel.load(profiles: profiles) }
        .onAppear              { viewModel.load(profiles: profiles) }
    }
}

// MARK: - ① Header
private struct SleepPageHeader: View {
    let viewModel: SleepViewModel
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("今晚的睡眠 · SLEEP")
                    .font(.system(size: 10, design: .monospaced)).tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                Text("睡眠分析")
                    .font(.custom("Georgia", size: 30)).foregroundStyle(Pulse.ink).tracking(-0.5)
            }
            Spacer()
            // Last night score badge
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(viewModel.lastNight.score)")
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(scoreColor(viewModel.lastNight.score))
                Text("昨夜得分")
                    .font(.system(size: 9, design: .monospaced)).tracking(1.5)
                    .foregroundStyle(Pulse.inkFaint)
            }
        }
    }
    private func scoreColor(_ s: Int) -> Color {
        if s >= 85 { return Color(hex: "7B9E87") }
        if s >= 70 { return Pulse.gold }
        return Color(hex: "C4A882")
    }
}

// MARK: - ② Tonight Forecast
private struct TonightForecastCard: View {
    let viewModel: SleepViewModel
    var forecast: (score: Int, bedtime: String, note: String) { viewModel.tonightForecast }

    var body: some View {
        PulseCard(radius: 14) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("今晚预测 · TONIGHT")
                        .font(.system(size: 9, design: .monospaced)).tracking(2.5)
                        .foregroundStyle(Pulse.inkSoft)
                    Spacer()
                    GlowIcon(sfSymbol: "moon.stars", size: 20)
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 16)

                HStack(alignment: .top, spacing: 0) {
                    // Predicted score
                    VStack(alignment: .leading, spacing: 4) {
                        Text("预测得分")
                            .font(.system(size: 9, design: .monospaced)).tracking(1.5)
                            .foregroundStyle(Pulse.inkFaint)
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text("\(forecast.score)")
                                .font(.custom("Georgia", size: 42)).foregroundStyle(Pulse.ink)
                            Text("/ 100")
                                .font(.system(size: 10, design: .monospaced)).tracking(1)
                                .foregroundStyle(Pulse.inkSoft)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Recommended bedtime
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("建议入睡")
                            .font(.system(size: 9, design: .monospaced)).tracking(1.5)
                            .foregroundStyle(Pulse.inkFaint)
                        Text(forecast.bedtime)
                            .font(.custom("Georgia", size: 28)).foregroundStyle(Pulse.gold)
                    }
                }
                .padding(.horizontal, 20)

                Rectangle().fill(Pulse.inkHair).frame(height: 1).padding(.horizontal, 20).padding(.top, 16)

                Text(forecast.note)
                    .font(.custom("Georgia", size: 14)).italic()
                    .foregroundStyle(Pulse.inkSoft).lineSpacing(3)
                    .padding(.horizontal, 20).padding(.vertical, 14)
            }
        }
    }
}

// MARK: - ③ Last Night Summary
private struct LastNightCard: View {
    let viewModel: SleepViewModel

    var body: some View {
        PulseCard(radius: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text("昨夜总结 · LAST NIGHT")
                    .font(.system(size: 9, design: .monospaced)).tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                    .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 0) {
                    SleepStatItem(label: "时长",    value: viewModel.totalSleepFormatted, unit: "")
                    SleepStatItem(label: "入睡",    value: viewModel.lastNight.bedtime,   unit: "")
                    SleepStatItem(label: "夜间HR",  value: "\(Int(viewModel.lastNight.avgHR))", unit: "bpm")
                    SleepStatItem(label: "夜间HRV", value: "\(Int(viewModel.lastNight.avgHRV))", unit: "ms")
                }

                Rectangle().fill(Pulse.inkHair).frame(height: 1).padding(.horizontal, 20).padding(.top, 12)

                // Latency note
                HStack(spacing: 8) {
                    GlowIcon(sfSymbol: "timer", size: 14, glowRadius: 10)
                    Text("入睡潜伏期 \(viewModel.lastNight.latencyMin) 分钟 — 排卵期正常范围")
                        .font(.system(size: 11, design: .monospaced)).tracking(0.5)
                        .foregroundStyle(Pulse.inkSoft)
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }
        }
    }
}

private struct SleepStatItem: View {
    let label: String; let value: String; let unit: String
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.system(size: 8, design: .monospaced)).tracking(1.5)
                .foregroundStyle(Pulse.inkFaint)
            Text(value)
                .font(.custom("Georgia", size: 20)).foregroundStyle(Pulse.ink)
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 8, design: .monospaced)).tracking(1)
                    .foregroundStyle(Pulse.inkFaint)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 4)
    }
}

// MARK: - ④ Sleep Stages
private struct SleepStagesCard: View {
    let viewModel: SleepViewModel

    private var totalMin: Int { viewModel.sleepStages.reduce(0) { $0 + $1.duration } }

    var body: some View {
        PulseCard(radius: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text("睡眠阶段 · STAGES")
                    .font(.system(size: 9, design: .monospaced)).tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                    .padding(.horizontal, 20).padding(.top, 18)

                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        ForEach(viewModel.sleepStages) { stage in
                            let width = geo.size.width * CGFloat(stage.duration) / CGFloat(totalMin)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: stage.color).opacity(0.75))
                                .frame(width: width, height: 28)
                        }
                    }
                }
                .frame(height: 28)
                .padding(.horizontal, 20)

                // Legend
                HStack(spacing: 0) {
                    ForEach(viewModel.sleepStages) { stage in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: stage.color))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(stage.name)
                                    .font(.system(size: 9, design: .monospaced)).tracking(1)
                                    .foregroundStyle(Pulse.inkSoft)
                                Text(formatMins(stage.duration))
                                    .font(.custom("Georgia", size: 13)).foregroundStyle(Pulse.ink)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 18)
            }
        }
    }

    private func formatMins(_ m: Int) -> String { "\(m/60)h\(m%60)m" }
}

// MARK: - ⑤ Sleep Tips
private struct SleepTipsCard: View {
    let viewModel: SleepViewModel

    var body: some View {
        PulseCard(radius: 14) {
            VStack(spacing: 0) {
                HStack {
                    Text("今晚建议 · RITUAL")
                        .font(.system(size: 9, design: .monospaced)).tracking(2.5)
                        .foregroundStyle(Pulse.inkSoft)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14)

                ForEach(Array(viewModel.sleepTips.enumerated()), id: \.offset) { i, tip in
                    if i > 0 {
                        Rectangle().fill(Pulse.inkHair).frame(height: 1).padding(.leading, 52)
                    }
                    HStack(alignment: .top, spacing: 14) {
                        GlowIcon(sfSymbol: tip.icon, size: 18).frame(width: 32).padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tip.title)
                                .font(.system(size: 13, weight: .medium)).foregroundStyle(Pulse.ink)
                            Text(tip.body)
                                .font(.custom("Georgia", size: 13)).italic()
                                .foregroundStyle(Pulse.inkSoft).lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
                Spacer().frame(height: 4)
            }
        }
    }
}

#Preview {
    SleepView()
        .modelContainer(for: [CycleProfile.self, DailyMetrics.self], inMemory: true)
}
