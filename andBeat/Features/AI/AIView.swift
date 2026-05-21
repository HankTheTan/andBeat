import SwiftUI
import SwiftData

struct AIView: View {
    @Query private var profiles: [CycleProfile]
    @State private var viewModel = AIViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // ① Header
                AIPageHeader(profile: viewModel.profile)
                    .padding(.top, 18).padding(.horizontal, 24).padding(.bottom, 12)

                // ② Quick prompts (visible when no keyboard)
                if !inputFocused {
                    QuickPromptsRow(prompts: viewModel.quickPrompts) { prompt in
                        viewModel.inputText = prompt
                        viewModel.sendMessage()
                    }
                    .padding(.horizontal, 20).padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ③ Chat messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 90) // space for input bar
                    }
                    .onChange(of: viewModel.messages.count) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) {
                        if viewModel.isTyping {
                            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                        }
                    }
                }
            }

            // ④ Input bar (floating at bottom)
            ChatInputBar(text: $viewModel.inputText, isFocused: $inputFocused) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.sendMessage()
                }
            }
        }
        .background(Pulse.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: inputFocused)
        .onChange(of: profiles) { viewModel.load(profiles: profiles) }
        .onAppear              { viewModel.load(profiles: profiles) }
        .onTapGesture          { inputFocused = false }
    }
}

// MARK: - ① Header
private struct AIPageHeader: View {
    let profile: CycleProfile?
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AI 顾问 · PULSE AI")
                    .font(.system(size: 10, design: .monospaced)).tracking(2.5)
                    .foregroundStyle(Pulse.inkSoft)
                Text("健康对话")
                    .font(.custom("Georgia", size: 30)).foregroundStyle(Pulse.ink).tracking(-0.5)
            }
            Spacer()
            // Context chip: cycle day + phase
            if let profile {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("D\(profile.currentCycleDay) · \(profile.currentPhase.rawValue)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.5)
                        .foregroundStyle(Pulse.gold)
                    Text("当前上下文")
                        .font(.system(size: 8, design: .monospaced)).tracking(1)
                        .foregroundStyle(Pulse.inkFaint)
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Pulse.goldDim, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Pulse.goldGlow))
                )
            }
        }
    }
}

// MARK: - ② Quick Prompts
private struct QuickPromptsRow: View {
    let prompts: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .tracking(0.3)
                            .foregroundStyle(Pulse.inkSoft)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.5))
                                    .overlay(Capsule().strokeBorder(Pulse.cardBorder, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - ③ Message Bubbles
private struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 56) }

            if !isUser {
                // AI avatar dot
                Circle()
                    .fill(Pulse.goldGlow)
                    .overlay(Circle().strokeBorder(Pulse.goldDim, lineWidth: 1))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "sparkle")
                            .font(.system(size: 10, weight: .thin))
                            .foregroundStyle(Pulse.gold)
                    )
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                ZStack {
                    if isUser {
                        // User bubble: gold-tinted
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Pulse.gold.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Pulse.goldDim.opacity(0.4), lineWidth: 1))
                    } else {
                        // AI bubble: frosted glass card
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.5))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial).opacity(0.5))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Pulse.cardBorder, lineWidth: 1))
                    }

                    Text(message.content)
                        .font(isUser
                              ? .system(size: 14, weight: .regular)
                              : .custom("Georgia", size: 14))
                        .foregroundStyle(Pulse.ink)
                        .lineSpacing(4)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(timeString(message.timestamp))
                    .font(.system(size: 8, design: .monospaced)).tracking(0.5)
                    .foregroundStyle(Pulse.inkFaint)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 32) }
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Typing Indicator
private struct TypingIndicator: View {
    @State private var dotPhase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(Pulse.goldGlow)
                .overlay(Circle().strokeBorder(Pulse.goldDim, lineWidth: 1))
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .thin)).foregroundStyle(Pulse.gold))

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial).opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Pulse.cardBorder, lineWidth: 1))
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Pulse.gold.opacity(dotPhase == i ? 1.0 : 0.3))
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                dotPhase = (dotPhase + 1) % 3
            }
            // Cycle through dots
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }
}

// MARK: - ④ Chat Input Bar
private struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Upward ambient glow
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "D6B370").opacity(0.14), .clear]),
                center: .init(x: 0.5, y: 1.0),
                startRadius: 0, endRadius: 100
            )
            .frame(height: 80).offset(y: -16).allowsHitTesting(false)

            VStack(spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.6)).frame(height: 1)

                HStack(spacing: 12) {
                    // Input field
                    TextField("和 PULSE 说说你的感受…", text: $text, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(Pulse.ink)
                        .lineLimit(1...4)
                        .focused(isFocused)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Pulse.cardBorder, lineWidth: 1))
                        )

                    // Send button
                    Button(action: onSend) {
                        ZStack {
                            Circle()
                                .fill(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? Pulse.inkHair : Pulse.gold)
                                .frame(width: 38, height: 38)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(
                                    text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Pulse.inkFaint : Color.white
                                )
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32) // safe area
            }
            .background(
                Color(hex: "FFFCEA").opacity(0.6)
                    .background(.ultraThinMaterial)
            )
        }
    }
}

#Preview {
    AIView()
        .modelContainer(for: [CycleProfile.self, DailyMetrics.self], inMemory: true)
}
