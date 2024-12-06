import Foundation
import FirebaseFirestore
import FirebaseAuth

class BookmarkService: ObservableObject {
    static let shared = BookmarkService()
    
    private let db = Firestore.firestore()
    @Published var error: BookmarkError?
    @Published private(set) var bookmarkedIssueIds: Set<String> = []
    
    enum BookmarkError: Error {
        case notAuthenticated
        case databaseError(String)
        case unknown
        
        var message: String {
            switch self {
            case .notAuthenticated:
                return "You must be signed in to bookmark issues"
            case .databaseError(let message):
                return "Database error: \(message)"
            case .unknown:
                return "An unknown error occurred. Please try again."
            }
        }
    }
    
    func isIssueBookmarked(_ issueId: String) -> Bool {
        bookmarkedIssueIds.contains(issueId)
    }
    
    func toggleBookmark(for issue: Zine.Issue, in zine: Zine) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BookmarkError.notAuthenticated
        }
        
        let userBookmarksRef = db.collection("users").document(userId)
            .collection("bookmarked_issues")
        
        do {
            if isIssueBookmarked(issue.id) {
                try await userBookmarksRef.document(issue.id).delete()
                
                await MainActor.run {
                    self.bookmarkedIssueIds.remove(issue.id)
                    return
                }
            } else {
                let data: [String: Any] = [
                    "issueId": issue.id,
                    "zineId": zine.id,
                    "zineName": zine.name,
                    "issueTitle": issue.title,
                    "timestamp": FieldValue.serverTimestamp(),
                    "coverImageUrl": issue.coverImageUrl,
                    "linkUrl": issue.linkUrl,
                    "publishedDate": issue.publishedDate
                ]
                
                try await userBookmarksRef.document(issue.id).setData(data)
                
                await MainActor.run {
                    self.bookmarkedIssueIds.insert(issue.id)
                    return
                }
            }
        } catch {
            throw BookmarkError.databaseError(error.localizedDescription)
        }
    }
    
    func loadBookmarkedIssues() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BookmarkError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("bookmarked_issues")
                .getDocuments()
            
            await MainActor.run {
                self.bookmarkedIssueIds = Set(snapshot.documents.map { $0.documentID })
                return
            }
        } catch {
            throw BookmarkError.databaseError(error.localizedDescription)
        }
    }
    
    // Method to get grouped bookmarks for the Bookmarks tab
    func fetchGroupedBookmarks() async throws -> [String: [BookmarkedIssue]] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BookmarkError.notAuthenticated
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("bookmarked_issues")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let bookmarks = snapshot.documents.compactMap { document -> BookmarkedIssue? in
            guard let data = try? document.data(as: BookmarkedIssue.self) else {
                return nil
            }
            return data
        }
        
        // Group by zineName and sort groups alphabetically
        return Dictionary(grouping: bookmarks) { $0.zineName }
            .mapValues { $0.sorted { $0.issueTitle < $1.issueTitle } }
            .sorted(by: { $0.key < $1.key })
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
}

// Model for bookmarked issues
struct BookmarkedIssue: Codable, Identifiable {
    let issueId: String
    let zineId: String
    let zineName: String
    let issueTitle: String
    let coverImageUrl: String
    let linkUrl: String
    let publishedDate: String
    let timestamp: Date
    
    var id: String { issueId }
}
