import SwiftUI
import SwiftData

// MARK: - TodayView (A2 · Refined)
struct TodayView: View {
    @Query private var profiles: [CycleProfile]
    @Query(sort: \DailyMetrics.date, order: .reverse) private var metricsHistory: [DailyMetrics]
    @State private var viewModel = TodayViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Very subtle vertical gradient lift (barely perceptible)
                Color.clear.frame(height: 0)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFFCEA").opacity(0), Color(hex: "F5EBC8").opacity(0.4)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                GreetingRow(viewModel: viewModel)
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)

                CyclePhaseCard(profile: viewModel.profile)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                MetricsGrid(metrics: viewModel.todayMetrics)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                StatusNoteCard(note: viewModel.statusNote)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                TipsCard(tips: viewModel.dailyTips)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                QuickLinksRow()
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 32)
            }
        }
        .background(Pulse.bg.ignoresSafeArea())
        .onChange(of: profiles)       { viewModel.load(profiles: profiles, metrics: metricsHistory) }
        .onChange(of: metricsHistory) { viewModel.load(profiles: profiles, metrics: metricsHistory) }
        .onAppear                     { viewModel.load(profiles: profiles, metrics: metricsHistory) }
    }
}

// MARK: - ① Greeting Row
private struct GreetingRow: View {
    let viewModel: TodayViewModel

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // Monospaced "下午好 · 5月21日"
                Text("\(viewModel.greeting) · \(viewModel.dateString)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)

                // Serif user name
                Text(viewModel.profile?.userName ?? "PULSE")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.regular)
                    .foregroundStyle(Pulse.ink)
                    .tracking(-0.5)
            }
            Spacer()
            // NOT CONNECTED pill
            HStack(spacing: 8) {
                Circle()
                    .fill(Pulse.inkFaint)
                    .frame(width: 5, height: 5)
                Text("NOT CONNECTED")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Pulse.inkSoft)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .overlay(Capsule().strokeBorder(Pulse.cardBorder, lineWidth: 1))
            )
            .overlay(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
            )
            .clipShape(Capsule())
        }
    }
}

// MARK: - ② Cycle Phase Card
private struct CyclePhaseCard: View {
    let profile: CycleProfile?

    var body: some View {
        PulseCard(radius: 14) {
            VStack(spacing: 0) {
                // Arc visualization
                if let profile {
                    RefCycleArcView(currentDay: profile.currentCycleDay,
                                    currentPhase: profile.currentPhase)
                        .padding(.vertical, 4)
                } else {
                    SetupPromptView()
                }

                // Divider + phase description
                if let profile {
                    Rectangle()
                        .fill(Pulse.inkHair)
                        .frame(height: 1)
                        .padding(.top, 16)

                    // Phase italic description
                    Text(profile.currentPhase.description)
                        .font(.custom("Georgia", size: 16))
                        .italic()
                        .foregroundStyle(Pulse.ink.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 8)

                    // Days-to-next + cycle position
                    HStack(spacing: 24) {
                        Text("距 \(profile.currentPhase.nextPhaseName) · ")
                            .foregroundStyle(Pulse.inkSoft)
                        + Text("\(profile.daysToNextPhase)D")
                            .foregroundStyle(Pulse.gold)

                        Text("|").foregroundStyle(Pulse.inkHair)

                        Text("周期 · D\(profile.currentCycleDay)/\(profile.cycleLength)")
                            .foregroundStyle(Pulse.inkSoft)
                    }
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .tracking(1.5)
                    .padding(.top, 14)
                    .padding(.bottom, 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

// MARK: - 4-Arc Cycle Visualization
private struct RefCycleArcView: View {
    let currentDay: Int
    let currentPhase: CyclePhase

    private let size: CGFloat = 210
    private let strokeW: CGFloat = 8

    private var radius: CGFloat { (size - strokeW - 16) / 2 }

    @State private var pulsing = false

    private struct Segment {
        let phase: CyclePhase; let days: Int; let startDay: Int
    }
    private let segments: [Segment] = [
        Segment(phase: .menstrual,  days: 5,  startDay: 0),
        Segment(phase: .follicular, days: 8,  startDay: 5),
        Segment(phase: .ovulation,  days: 2,  startDay: 13),
        Segment(phase: .luteal,     days: 13, startDay: 15),
    ]

    // Position of the indicator dot on the ring
    private var dotOffset: CGSize {
        let dayFrac = (Double(currentDay) - 0.5) / 28.0
        let angle   = dayFrac * 2 * .pi - .pi / 2
        return CGSize(width:  radius * CGFloat(cos(angle)),
                      height: radius * CGFloat(sin(angle)))
    }

    var body: some View {
        ZStack {
            // Arcs via Canvas
            Canvas { ctx, _ in
                let center  = CGPoint(x: size / 2, y: size / 2)
                let gapFrac = 2.5 / 360.0

                for seg in segments {
                    let isActive  = seg.phase == currentPhase
                    let color     = isActive ? seg.phase.arcActive : seg.phase.arcDim
                    let opacity   = isActive ? 1.0 : 0.55
                    let startFrac = Double(seg.startDay) / 28.0 + gapFrac / 2
                    let lenFrac   = Double(seg.days) / 28.0 - gapFrac
                    let start     = Angle(radians: startFrac * 2 * .pi - .pi / 2)
                    let end       = Angle(radians: (startFrac + lenFrac) * 2 * .pi - .pi / 2)

                    var path = Path()
                    path.addArc(center: center, radius: radius,
                                startAngle: start, endAngle: end, clockwise: false)

                    let style = StrokeStyle(lineWidth: strokeW, lineCap: .round)

                    if isActive {
                        // Glow layer for active segment
                        ctx.drawLayer { lCtx in
                            lCtx.addFilter(.shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0))
                            lCtx.stroke(path, with: .color(color), style: style)
                        }
                    } else {
                        ctx.stroke(path, with: .color(color.opacity(opacity)), style: style)
                    }
                }
            }
            .frame(width: size, height: size)

            // Pulsing indicator dot
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Pulse.goldBright, .clear]),
                            center: .center, startRadius: 0, endRadius: 14
                        )
                    )
                    .frame(width: 28, height: 28)
                    .scaleEffect(pulsing ? 1.35 : 1.0)
                    .opacity(pulsing ? 0.55 : 0.9)

                Circle()
                    .fill(Pulse.goldBright)
                    .frame(width: 10, height: 10)
                    .shadow(color: Pulse.goldBright.opacity(0.7), radius: 4)
                    .shadow(color: Pulse.goldGlow, radius: 8)
            }
            .offset(dotOffset)

            // Center text
            VStack(spacing: 0) {
                Text("DAY")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(Pulse.inkSoft)

                Text("\(currentDay)")
                    .font(.custom("Georgia", size: 68))
                    .fontWeight(.light)
                    .foregroundStyle(Pulse.ink)
                    .tracking(-2)
                    .padding(.top, 4)

                Text(currentPhase.bilingualLabel)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.gold)
                    .padding(.top, 10)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

private struct SetupPromptView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(Pulse.inkFaint)
            Text("记录你的经期开始日期")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Pulse.inkSoft)
            Text("GET STARTED →")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Pulse.gold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - ③ Metrics 2×2 Grid
private struct MetricsGrid: View {
    let metrics: DailyMetrics?

    private struct MetricSpec {
        let label: String; let sfSymbol: String
        let value: String; let unit: String
    }
    private func specs(from m: DailyMetrics?) -> [MetricSpec] {[
        MetricSpec(label: "HR · 心率",   sfSymbol: "heart",              value: m?.heartRate.map        { "\(Int($0))" }               ?? "--", unit: "BPM"),
        MetricSpec(label: "TEMP · 体温", sfSymbol: "thermometer.medium", value: m?.bodyTemperature.map  { String(format: "%.1f", $0) }  ?? "--", unit: "°C"),
        MetricSpec(label: "HRV",         sfSymbol: "waveform.path.ecg",  value: m?.hrv.map              { "\(Int($0))" }               ?? "--", unit: "MS"),
        MetricSpec(label: "RESP · 呼吸", sfSymbol: "lungs",              value: m?.respiratoryRate.map  { "\(Int($0))" }               ?? "--", unit: "/MIN"),
    ]}

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(specs(from: metrics), id: \.label) { spec in
                RefMetricCard(label: spec.label, sfSymbol: spec.sfSymbol,
                              value: spec.value, unit: spec.unit)
            }
        }
    }
}

private struct RefMetricCard: View {
    let label: String; let sfSymbol: String
    let value: String; let unit: String

    var body: some View {
        PulseCard(radius: 12) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Monospaced label
                    Text(label)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Pulse.inkSoft)
                    Spacer()
                    // Gold thin-line glow icon
                    GlowIcon(sfSymbol: sfSymbol, size: 22)
                }
                // Serif value + mono unit
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.custom("Georgia", size: 32))
                        .foregroundStyle(Pulse.ink)
                        .tracking(-0.8)
                    Text(unit)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(Pulse.inkSoft)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
        }
    }
}

// MARK: - ④ Status Note Card
private struct StatusNoteCard: View {
    let note: String

    var body: some View {
        PulseCard(radius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY · NOTE")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.gold)

                Text(note)
                    .font(.custom("Georgia", size: 17))
                    .italic()
                    .foregroundStyle(Pulse.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - ⑤ Tips Card
private struct TipsCard: View {
    let tips: [DailyTip]

    var body: some View {
        PulseCard(radius: 12) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("今日建议 · RITUAL")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .tracking(2.5)
                        .foregroundStyle(Pulse.inkSoft)
                    Spacer()
                    Text(String(format: "%02d", tips.count))
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(Pulse.inkFaint)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)

                ForEach(Array(tips.enumerated()), id: \.element.id) { i, tip in
                    if i > 0 {
                        Rectangle()
                            .fill(Pulse.inkHair)
                            .frame(height: 1)
                            .padding(.leading, 50 + 18)
                    }
                    TipRow(tip: tip)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                Spacer().frame(height: 4)
            }
        }
    }
}

private struct TipRow: View {
    let tip: DailyTip

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GlowIcon(sfSymbol: tip.sfSymbol, size: 20)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Pulse.ink)
                    .tracking(-0.1)

                Text(tip.body)
                    .font(.custom("Georgia", size: 13))
                    .italic()
                    .foregroundStyle(Pulse.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

// MARK: - ⑥ Quick Links
private struct QuickLinksRow: View {
    var body: some View {
        HStack(spacing: 10) {
            QuickLinkCard(sfSymbol: "moon.stars", label: "今晚的睡眠", sub: "SLEEP FORECAST")
            QuickLinkCard(sfSymbol: "message",    label: "AI 顾问",    sub: "CONVERSATION")
        }
    }
}

private struct QuickLinkCard: View {
    let sfSymbol: String; let label: String; let sub: String

    var body: some View {
        PulseCard(radius: 12) {
            VStack(alignment: .leading, spacing: 10) {
                GlowIcon(sfSymbol: sfSymbol, size: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Pulse.ink)

                    Text("\(sub) →")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Pulse.inkFaint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

// MARK: - Shared: Gold Glow Icon
/// Semi-transparent thin-line icon with ambient radial glow (unified A2 language)
struct GlowIcon: View {
    let sfSymbol: String
    let size: CGFloat
    var glowRadius: CGFloat = 16

    var body: some View {
        ZStack {
            // Ambient radial halo
            RadialGradient(
                gradient: Gradient(colors: [Pulse.goldGlow, .clear]),
                center: .center, startRadius: 0, endRadius: glowRadius
            )
            .frame(width: glowRadius * 2, height: glowRadius * 2)

            // Thin-line SF Symbol in gold
            Image(systemName: sfSymbol)
                .font(.system(size: size, weight: .thin))
                .foregroundStyle(Pulse.gold.opacity(0.7))
                .shadow(color: Pulse.goldGlow, radius: 4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Shared: Pulse Card Container
/// Frosted glass card with hairline border (A2 card style)
struct PulseCard<Content: View>: View {
    let radius: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity)          // 确保卡片撑满可用宽度
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Pulse.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Pulse.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Preview
#Preview {
    TodayView()
        .modelContainer(for: [CycleProfile.self, DailyMetrics.self], inMemory: true)
}
