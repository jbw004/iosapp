import Foundation

struct Zine: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String
    let coverImageUrl: String
    let instagramUrl: String
    let issues: [Issue]
    
    struct Issue: Identifiable, Codable {
        let id: String
        let title: String
        let coverImageUrl: String
        let linkUrl: String
        let publishedDate: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case coverImageUrl = "cover_image_url"
            case linkUrl = "link_url"
            case publishedDate = "published_date"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case coverImageUrl = "cover_image_url"
        case instagramUrl = "instagram_url"
        case issues
    }
}

struct ZineResponse: Codable {
    let version: String
    let lastUpdated: String
    let zines: [Zine]
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case zines
    }
}

