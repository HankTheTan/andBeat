import SwiftUI

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - PULSE Design Tokens (A2 · Refined)
// 50% 生活方式 / 30% 科技感 / 20% 时尚感
// Reference: Oura, Whoop (tech) + Diptyque, Byredo (material)
enum Pulse {
    // Background
    static let bg         = Color(hex: "FFFCEA")   // skin-tone warm white

    // Ink
    static let ink        = Color(hex: "2A231C")   // deep warm near-black
    static let inkSoft    = Color(hex: "2A231C").opacity(0.58)
    static let inkFaint   = Color(hex: "2A231C").opacity(0.36)
    static let inkHair    = Color(hex: "2A231C").opacity(0.10)

    // Gold — aged brass, the single material accent
    static let gold        = Color(hex: "B89456")
    static let goldBright  = Color(hex: "D6B370")
    static let goldDim     = Color(hex: "B89456").opacity(0.55)
    static let goldGlow    = Color(hex: "B89456").opacity(0.22)

    // Cards
    static let card        = Color.white.opacity(0.50)
    static let cardBorder  = Color(hex: "2A231C").opacity(0.06)
}

// MARK: - CyclePhase Arc Colors & Labels (A2 palette)
extension CyclePhase {
    /// Active arc color (current phase)
    var arcActive: Color {
        switch self {
        case .menstrual:  return Color(hex: "8C6A38")  // deep amber
        case .follicular: return Color(hex: "B89456")  // mid brass
        case .ovulation:  return Color(hex: "E8B549")  // bright honey
        case .luteal:     return Color(hex: "A88A5C")  // muted brass
        }
    }
    /// Dim arc color (inactive phases)
    var arcDim: Color {
        switch self {
        case .menstrual:  return Color(hex: "C9B89A")
        case .follicular: return Color(hex: "D6C7A6")
        case .ovulation:  return Color(hex: "E2D2A8")
        case .luteal:     return Color(hex: "CDBEA0")
        }
    }
    /// Bilingual label for the ring center
    var bilingualLabel: String {
        switch self {
        case .menstrual:  return "经期 · MENSTRUAL"
        case .follicular: return "卵泡期 · FOLLICULAR"
        case .ovulation:  return "排卵期 · OVULATION"
        case .luteal:     return "黄体期 · LUTEAL"
        }
    }
}
