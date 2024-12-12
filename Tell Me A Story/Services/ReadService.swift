import Foundation
import FirebaseFirestore
import FirebaseAuth

class ReadService: ObservableObject {
    static let shared = ReadService()
    
    private let db = Firestore.firestore()
    @Published var error: ReadError?
    @Published private(set) var readIssueIds: Set<String> = []
    
    enum ReadError: Error {
        case notAuthenticated
        case databaseError(String)
        case unknown
        
        var message: String {
            switch self {
            case .notAuthenticated:
                return "You must be signed in to mark issues as read"
            case .databaseError(let message):
                return "Database error: \(message)"
            case .unknown:
                return "An unknown error occurred. Please try again."
            }
        }
    }
    
    func isIssueRead(_ issueId: String, in zineId: String) -> Bool {
        let uniqueId = "\(zineId)_\(issueId)"
        return readIssueIds.contains(uniqueId)
    }
    
    func toggleReadStatus(for issue: Zine.Issue, in zine: Zine) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ReadError.notAuthenticated
        }
        
        let uniqueId = "\(zine.id)_\(issue.id)"
        let userReadRef = db.collection("users").document(userId)
            .collection("read_issues")
        
        do {
            if isIssueRead(issue.id, in: zine.id) {
                try await userReadRef.document(uniqueId).delete()
                
                await MainActor.run {
                    self.readIssueIds.remove(uniqueId)
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
                
                try await userReadRef.document(uniqueId).setData(data)
                
                await MainActor.run {
                    self.readIssueIds.insert(uniqueId)
                    return
                }
            }
        } catch {
            throw ReadError.databaseError(error.localizedDescription)
        }
    }
    
    func loadReadIssues() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ReadError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("read_issues")
                .getDocuments()
            
            await MainActor.run {
                self.readIssueIds = Set(snapshot.documents.map { $0.documentID })
                return
            }
        } catch {
            throw ReadError.databaseError(error.localizedDescription)
        }
    }
    
    // Method to get grouped read issues for the History tab
    func fetchGroupedReadIssues() async throws -> [String: [ReadIssue]] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ReadError.notAuthenticated
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("read_issues")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let readIssues = snapshot.documents.compactMap { document -> ReadIssue? in
            guard let data = try? document.data(as: ReadIssue.self) else {
                return nil
            }
            return data
        }
        
        // Group by zineName and sort groups alphabetically
        return Dictionary(grouping: readIssues) { $0.zineName }
            .mapValues { $0.sorted { $0.issueTitle < $1.issueTitle } }
            .sorted(by: { $0.key < $1.key })
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
}

// Model for read issues
struct ReadIssue: Codable, Identifiable {
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
