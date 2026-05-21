import SwiftUI
import SwiftData

struct CycleView: View {
    @Query private var profiles: [CycleProfile]
    @Query(sort: \DailyMetrics.date, order: .forward) private var metrics: [DailyMetrics]
    @State private var viewModel = CycleViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                CyclePageHeader(profile: viewModel.profile)
                    .padding(.top, 18)
                    .padding(.horizontal, 24)

                PhaseInsightCard(profile: viewModel.profile, insight: viewModel.phaseInsight)
                    .padding(.horizontal, 16)

                CycleStripCard(cells: viewModel.dayCells)
                    .padding(.horizontal, 16)

                if !viewModel.tempPoints.isEmpty {
                    BBTChartCard(points: viewModel.tempPoints)
                        .padding(.horizontal, 16)
                }

                PredictionsCard(viewModel: viewModel)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 24)
            }
        }
        .background(Pulse.bg.ignoresSafeArea())
        .onChange(of: profiles) { viewModel.load(profiles: profiles, metrics: metrics) }
        .onChange(of: metrics)  { viewModel.load(profiles: profiles, metrics: metrics) }
        .onAppear              { viewModel.load(profiles: profiles, metrics: metrics) }
    }
}

// MARK: - ① Header
private struct CyclePageHeader: View {
    let profile: CycleProfile?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("周期追踪 · CYCLE")
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                Text(profile?.currentPhase.rawValue ?? "—")
                    .font(.custom("Georgia", size: 30))
                    .foregroundStyle(Pulse.ink)
                    .tracking(-0.5)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("D\(profile?.currentCycleDay ?? 0)")
                    .font(.system(size: 26, weight: .light, design: .monospaced))
                    .foregroundStyle(Pulse.gold)
                Text("/ \(profile?.cycleLength ?? 28) 天")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Pulse.inkFaint)
            }
        }
    }
}

// MARK: - ② Phase Insight Card
private struct PhaseInsightCard: View {
    let profile: CycleProfile?
    let insight: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                GlowIcon(sfSymbol: "info.circle", size: 16)
                Text("阶段解读 · PHASE INSIGHT")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
            }

            Text(insight)
                .font(.custom("Georgia", size: 15))
                .italic()
                .foregroundStyle(Pulse.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let phase = profile?.currentPhase {
                HStack(spacing: 8) {
                    ForEach(phase.characteristics, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 9, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(Pulse.gold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Pulse.goldGlow)
                                    .overlay(Capsule().strokeBorder(Pulse.goldDim, lineWidth: 1))
                            )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Pulse.card)
                .overlay(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).opacity(0.5))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pulse.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - ③ 28-Day Strip（阶段标签与日期点带同在 ScrollView 内，对齐保证）
private struct CycleStripCard: View {
    let cells: [CycleViewModel.DayCell]
    private let dotW: CGFloat = 24     // 每格宽度
    private let dotGap: CGFloat = 4    // 间距

    // 阶段 (name, days) 按顺序排列
    private let phases: [(name: String, days: Int)] = [
        ("经期", 5), ("卵泡期", 8), ("排卵期", 2), ("黄体期", 13)
    ]

    private var stripWidth: CGFloat {
        CGFloat(28) * dotW + CGFloat(27) * dotGap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("28日周期 · CYCLE MAP")
                .font(.system(size: 9, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(Pulse.inkSoft)
                .padding(.horizontal, 18)
                .padding(.top, 18)

            // 阶段标签 + 日期点带 同一 ScrollView 内滚动
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        // 阶段标签行
                        HStack(spacing: 0) {
                            ForEach(phases, id: \.name) { phase in
                                let w = CGFloat(phase.days) * (dotW + dotGap) - dotGap
                                Text(phase.name)
                                    .font(.system(size: 8, design: .monospaced))
                                    .tracking(0.5)
                                    .foregroundStyle(Pulse.inkFaint)
                                    .frame(width: w, alignment: .center)
                            }
                        }

                        // 日期点带
                        HStack(spacing: dotGap) {
                            ForEach(cells, id: \.day) { cell in
                                DayDot(cell: cell, w: dotW)
                                    .id(cell.day)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .onAppear {
                    // 滚动至当前天可见
                    if let today = cells.first(where: { $0.isToday }) {
                        let targetDay = max(1, today.day - 4)
                        withAnimation {
                            proxy.scrollTo(targetDay, anchor: .leading)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Pulse.card)
                .overlay(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).opacity(0.5))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pulse.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct DayDot: View {
    let cell: CycleViewModel.DayCell
    let w: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            // 当前天指示点
            Circle()
                .fill(cell.isToday ? Pulse.goldBright : Color.clear)
                .frame(width: 5, height: 5)
                .shadow(color: cell.isToday ? Pulse.goldBright : .clear, radius: 3)

            // 日期格
            RoundedRectangle(cornerRadius: 5)
                .fill(tileColor)
                .frame(width: w, height: cell.isToday ? 34 : 28)
                .shadow(color: cell.isToday ? cell.phase.arcActive.opacity(0.35) : .clear, radius: 4)
                .overlay(
                    Text("\(cell.day)")
                        .font(.system(size: 9, weight: cell.isToday ? .semibold : .regular,
                                      design: .monospaced))
                        .foregroundStyle(cell.isToday ? Color.white : Pulse.inkFaint)
                )
        }
    }

    private var tileColor: Color {
        if cell.isToday  { return cell.phase.arcActive }
        if cell.isFuture { return cell.phase.arcDim.opacity(0.3) }
        return cell.phase.arcActive.opacity(0.45)
    }
}

// MARK: - ④ BBT 图表（Y 轴自适应数据范围）
private struct BBTChartCard: View {
    let points: [CycleViewModel.TempPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("基础体温 · BBT")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                Spacer()
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Pulse.gold.opacity(0.5))
                        .frame(width: 16, height: 1)
                    Text("36.6°C 基准线")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(Pulse.gold.opacity(0.7))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 10)

            // 使用 GeometryReader 获取准确宽度
            GeometryReader { geo in
                BBTCanvas(points: points, width: geo.size.width)
                    .frame(width: geo.size.width, height: 120)
            }
            .frame(height: 120)
            .padding(.horizontal, 8)

            // X 轴标签行
            HStack(spacing: 0) {
                ForEach(points, id: \.label) { p in
                    Text(p.label)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(p.isToday ? Pulse.gold : Pulse.inkFaint)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Pulse.card)
                .overlay(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).opacity(0.5))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pulse.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct BBTCanvas: View {
    let points: [CycleViewModel.TempPoint]
    let width: CGFloat

    // Y 轴自适应：在数据范围两侧各留 0.08°C 空白
    private var yMin: Double {
        let base = points.map(\.value).min() ?? 36.2
        return floor((base - 0.08) * 10) / 10
    }
    private var yMax: Double {
        let top = max(points.map(\.value).max() ?? 36.8, 36.65)
        return ceil((top + 0.08) * 10) / 10
    }
    private let coverLine = 36.6

    var body: some View {
        Canvas { ctx, size in
            guard points.count > 1 else { return }
            let W = size.width, H = size.height
            let padL: CGFloat = 38, padR: CGFloat = 8
            let padT: CGFloat = 6,  padB: CGFloat = 4
            let chartW = W - padL - padR
            let chartH = H - padT - padB

            // 坐标映射
            func xAt(_ i: Int) -> CGFloat {
                padL + (chartW / CGFloat(points.count - 1)) * CGFloat(i)
            }
            func yAt(_ temp: Double) -> CGFloat {
                let frac = (temp - yMin) / (yMax - yMin)
                return padT + chartH * CGFloat(1 - frac)
            }

            // Y 轴刻度（3条横线 + 标签）
            let ticks = stride(from: yMin, through: yMax, by: 0.2).map { $0 }
            for t in ticks {
                let yPos = yAt(t)
                // 刻度线
                var tickPath = Path()
                tickPath.move(to:    CGPoint(x: padL - 4, y: yPos))
                tickPath.addLine(to: CGPoint(x: padL + chartW, y: yPos))
                ctx.stroke(tickPath, with: .color(Pulse.inkHair), lineWidth: 0.5)
                // 标签
                ctx.draw(
                    Text(String(format: "%.1f", t))
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(Pulse.inkFaint),
                    at: CGPoint(x: padL - 6, y: yPos),
                    anchor: .trailing
                )
            }

            // 盖线（36.6°C 基准虚线）
            if coverLine >= yMin && coverLine <= yMax {
                var cl = Path()
                cl.move(to:    CGPoint(x: padL,        y: yAt(coverLine)))
                cl.addLine(to: CGPoint(x: padL + chartW, y: yAt(coverLine)))
                ctx.stroke(cl, with: .color(Pulse.gold.opacity(0.5)),
                           style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }

            // 填充面积
            var area = Path()
            area.move(to: CGPoint(x: xAt(0), y: yAt(yMin)))
            for (i, p) in points.enumerated() { area.addLine(to: CGPoint(x: xAt(i), y: yAt(p.value))) }
            area.addLine(to: CGPoint(x: xAt(points.count - 1), y: yAt(yMin)))
            area.closeSubpath()
            ctx.fill(area, with: .color(Pulse.gold.opacity(0.07)))

            // 折线
            var line = Path()
            for (i, p) in points.enumerated() {
                let pt = CGPoint(x: xAt(i), y: yAt(p.value))
                i == 0 ? line.move(to: pt) : line.addLine(to: pt)
            }
            ctx.stroke(line, with: .color(Pulse.gold),
                       style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

            // 数据点
            for (i, p) in points.enumerated() {
                let pt = CGPoint(x: xAt(i), y: yAt(p.value))
                let r: CGFloat = p.isToday ? 5 : 3.5
                // 光晕
                if p.isToday {
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x-9, y: pt.y-9, width: 18, height: 18)),
                             with: .color(Pulse.goldGlow))
                }
                // 点
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x-r, y: pt.y-r, width: r*2, height: r*2)),
                         with: .color(p.isToday ? Pulse.goldBright : Pulse.gold))
            }
        }
    }
}

// MARK: - ⑤ 预测卡片
private struct PredictionsCard: View {
    let viewModel: CycleViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("即将到来 · UPCOMING")
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle().fill(Pulse.inkHair).frame(height: 1)

            PredRow(icon: "drop.fill",
                    label: "下次经期",
                    value: "\(viewModel.nextPeriodDays)",
                    unit: "天后")

            Rectangle().fill(Pulse.inkHair).frame(height: 1)

            PredRow(icon: "arrow.clockwise",
                    label: "周期长度",
                    value: "\(viewModel.profile?.cycleLength ?? 28)",
                    unit: "天")

            Rectangle().fill(Pulse.inkHair).frame(height: 1)

            PredRow(icon: "waveform.path.ecg",
                    label: "当前周期天",
                    value: "D\(viewModel.profile?.currentCycleDay ?? 0)",
                    unit: "/ \(viewModel.profile?.cycleLength ?? 28)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Pulse.card)
                .overlay(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).opacity(0.5))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pulse.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct PredRow: View {
    let icon: String; let label: String; let value: String; let unit: String

    var body: some View {
        HStack(spacing: 14) {
            GlowIcon(sfSymbol: icon, size: 18).frame(width: 28)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Pulse.ink)
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.custom("Georgia", size: 24))
                    .foregroundStyle(Pulse.gold)
                Text(unit)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Pulse.inkSoft)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - CyclePhase: 阶段特征标签
extension CyclePhase {
    var characteristics: [String] {
        switch self {
        case .menstrual:  return ["修复期", "低能量", "内省"]
        case .follicular: return ["能量回升", "认知清晰", "创造力↑"]
        case .ovulation:  return ["能量峰值", "社交活跃", "自信↑"]
        case .luteal:     return ["内敛期", "孕酮主导", "关注感受"]
        }
    }
}

#Preview {
    CycleView()
        .modelContainer(for: [CycleProfile.self, DailyMetrics.self], inMemory: true)
}
