import Foundation

struct ZineReadStats: Identifiable {
    let id = UUID()
    let zineName: String
    let issueCount: Int
    let coverImageUrl: String
}
