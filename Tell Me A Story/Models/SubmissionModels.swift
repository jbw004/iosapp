import Foundation

struct ZineSubmission: Codable {
    let userId: String
    let timestamp: Date
    let name: String
    let bio: String
    let instagramUrl: String
    let coverImagePath: String
}

struct IssueSubmission: Codable {
    let userId: String
    let timestamp: Date
    let zineId: String
    let title: String
    let publishedDate: String
    let coverImagePath: String
    let linkUrl: String
}
