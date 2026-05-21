//
//  ContentView.swift — Tab 导航根视图（项目负责人维护）
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content — hide system tab bar
            TabView(selection: $selectedTab) {
                TodayView().tag(0)
                CycleView().tag(1)
                SleepView().tag(2)
                AIView().tag(3)
            }
            .toolbar(.hidden, for: .tabBar)

            // Custom A2 frosted glass tab bar
            PulseTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar (A2 · Refined)
private struct PulseTabBar: View {
    @Binding var selectedTab: Int

    private struct Tab {
        let sfSymbol: String; let label: String; let tag: Int
    }
    private let tabs: [Tab] = [
        Tab(sfSymbol: "sun.max",      label: "今天",  tag: 0),
        Tab(sfSymbol: "circle.dotted",label: "周期",  tag: 1),
        Tab(sfSymbol: "moon.stars",   label: "睡眠",  tag: 2),
        Tab(sfSymbol: "message",      label: "AI",    tag: 3),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Upward ambient glow (sits behind bar)
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "D6B370").opacity(0.18),
                    .clear
                ]),
                center: .init(x: 0.5, y: 1.0),
                startRadius: 0,
                endRadius: 120
            )
            .frame(height: 80)
            .offset(y: -16)
            .allowsHitTesting(false)

            // Frosted glass bar
            VStack(spacing: 0) {
                // Top 1pt highlight line
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(height: 1)

                HStack(spacing: 0) {
                    ForEach(tabs, id: \.tag) { tab in
                        TabItemButton(
                            sfSymbol: tab.sfSymbol,
                            label: tab.label,
                            isActive: selectedTab == tab.tag
                        ) {
                            selectedTab = tab.tag
                        }
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 30) // safe area pad
            }
            .background(
                Color(hex: "FFFCEA").opacity(0.55)
                    .background(.ultraThinMaterial)
            )
        }
    }
}

private struct TabItemButton: View {
    let sfSymbol: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: sfSymbol)
                    .font(.system(size: 20, weight: isActive ? .regular : .thin))
                    .foregroundStyle(isActive ? Pulse.gold : Pulse.inkFaint)
                    .shadow(color: isActive ? Pulse.goldGlow : .clear, radius: 4)

                Text(label)
                    .font(.system(size: 9, weight: isActive ? .semibold : .regular, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(isActive ? Pulse.gold : Pulse.inkFaint)

                // Active indicator line
                if isActive {
                    Rectangle()
                        .fill(Pulse.gold)
                        .frame(width: 14, height: 1.5)
                        .clipShape(Capsule())
                        .shadow(color: Pulse.gold.opacity(0.8), radius: 3)
                } else {
                    Color.clear.frame(width: 14, height: 1.5)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: [CycleProfile.self, DailyMetrics.self], inMemory: true)
}
