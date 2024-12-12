import Foundation
import SwiftUI

struct ThemeTypography {
    let displayFont: String  // For titles and headers
    let bodyFont: String    // For regular text
}

struct PassportTheme: Identifiable {
    let id = UUID()
    let name: String
    let background: String
    let primaryColor: String
    let secondaryColor: String
    let accentColor: String
    let textColor: String
    let typography: ThemeTypography
}

// Updated Passport Themes with System Fonts
let passportThemes = [
    PassportTheme(
        name: "Riot Grrrl Revival",
        background: "#1A1A1A",
        primaryColor: "#FF4D6D",
        secondaryColor: "#7FFF00",
        accentColor: "#FFD700",
        textColor: "#FFFFFF",
        typography: ThemeTypography(
            displayFont: ".system(.headline, design: .rounded)",
            bodyFont: ".system(.body, design: .monospaced)"
        )
    ),
    PassportTheme(
        name: "Underground Press",
        background: "#2B2D42",
        primaryColor: "#FF9F1C",
        secondaryColor: "#4ECDC4",
        accentColor: "#FF477E",
        textColor: "#EDF2F4",
        typography: ThemeTypography(
            displayFont: ".system(.largeTitle, design: .serif)",
            bodyFont: ".system(.body, design: .default)"
        )
    ),
    PassportTheme(
        name: "Analog Dreams",
        background: "#F7F3E9",
        primaryColor: "#FF6B6B",
        secondaryColor: "#4D96FF",
        accentColor: "#6B4423",
        textColor: "#2C3333",
        typography: ThemeTypography(
            displayFont: ".system(.title, design: .rounded)",
            bodyFont: ".system(.body, design: .serif)"
        )
    ),
    PassportTheme(
        name: "Digital Dystopia",
        background: "#0F0F0F",
        primaryColor: "#00FF9F",
        secondaryColor: "#FF2A6D",
        accentColor: "#7700FF",
        textColor: "#E0E0E0",
        typography: ThemeTypography(
            displayFont: ".system(.largeTitle, design: .monospaced)",
            bodyFont: ".system(.body, design: .monospaced)"
        )
    ),
    PassportTheme(
        name: "Vintage Xerox",
        background: "#F5F5F5",
        primaryColor: "#1A1A1A",
        secondaryColor: "#666666",
        accentColor: "#FF3366",
        textColor: "#000000",
        typography: ThemeTypography(
            displayFont: ".system(.title, design: .default)",
            bodyFont: ".system(.body, design: .monospaced)"
        )
    ),
    PassportTheme(
        name: "Neo Tokyo",
        background: "#1F1F1F",
        primaryColor: "#FF0099",
        secondaryColor: "#00FF8C",
        accentColor: "#FFB800",
        textColor: "#FFFFFF",
        typography: ThemeTypography(
            displayFont: ".system(.largeTitle, design: .default)",
            bodyFont: ".system(.body, design: .monospaced)"
        )
    ),
    PassportTheme(
        name: "Botanical Underground",
        background: "#EBE5D9",
        primaryColor: "#2D5A27",
        secondaryColor: "#8B4513",
        accentColor: "#FF6B6B",
        textColor: "#1A1A1A",
        typography: ThemeTypography(
            displayFont: ".system(.title, design: .serif)",
            bodyFont: ".system(.body, design: .serif)"
        )
    ),
    PassportTheme(
        name: "Midnight Radio",
        background: "#150050",
        primaryColor: "#3F0071",
        secondaryColor: "#FB2576",
        accentColor: "#FFE61B",
        textColor: "#FFFFFF",
        typography: ThemeTypography(
            displayFont: ".system(.title, design: .rounded)",
            bodyFont: ".system(.body, design: .default)"
        )
    ),
    PassportTheme(
        name: "Protest Press",
        background: "#F5F5F5",
        primaryColor: "#FF0000",
        secondaryColor: "#000000",
        accentColor: "#FFD700",
        textColor: "#1A1A1A",
        typography: ThemeTypography(
            displayFont: ".system(.title, design: .default)",
            bodyFont: ".system(.body, design: .default)"
        )
    ),
    PassportTheme(
        name: "Vaporwave Vision",
        background: "#181818",
        primaryColor: "#FF71CE",
        secondaryColor: "#01CDFE",
        accentColor: "#05FFA1",
        textColor: "#FFFFFF",
        typography: ThemeTypography(
            displayFont: ".system(.largeTitle, design: .monospaced)",
            bodyFont: ".system(.body, design: .default)"
        )
    )
]

// Helper extension to convert theme typography to SwiftUI Font
extension ThemeTypography {
    func displayFont(size: CGFloat = 34) -> Font {
        if displayFont.contains("monospaced") {
            return .system(size: size, design: .monospaced)
        } else if displayFont.contains("serif") {
            return .system(size: size, design: .serif)
        } else if displayFont.contains("rounded") {
            return .system(size: size, design: .rounded)
        }
        return .system(size: size)
    }
    
    func bodyFont(size: CGFloat = 16) -> Font {
        if bodyFont.contains("monospaced") {
            return .system(size: size, design: .monospaced)
        } else if bodyFont.contains("serif") {
            return .system(size: size, design: .serif)
        } else if bodyFont.contains("rounded") {
            return .system(size: size, design: .rounded)
        }
        return .system(size: size)
    }
}
