import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    static let zineColors: [String: Color] = [
            "bangs_zine": Color(hex: "#2D2D2D"),
            "rabid_zines": Color(hex: "#C41E3A"),
            "pink_disco": Color(hex: "#FFB6C1"),
            "pastel_serenity": Color(hex: "#B8B8B8"),
            "riot_maiden": Color(hex: "#FF4B4B"),
            "punk_sleepover": Color(hex: "#8B0000"),
            "duna_haller": Color(hex: "#8A2BE2"),
            "played_out": Color(hex: "#E6A8D7")
        ]
}
