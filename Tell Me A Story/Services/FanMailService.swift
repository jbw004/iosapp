import Foundation
import FirebaseFirestore
import Combine

struct FanMailMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let zineId: String
    let zineName: String
    let createdAt: Date
    var votes: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case zineId
        case zineName
        case createdAt
        case votes
    }
}

class FanMailService: ObservableObject {
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var currentUserVotesListener: ListenerRegistration?
    
    @Published var messages: [FanMailMessage] = []
    @Published var userVotes: [String: Int] = [:] // messageId: voteValue
    @Published var error: Error?
    
    init() {
        startListeningToMessages()
    }
    
    deinit {
        stopListening()
    }
    
    private func stopListening() {
        listenerRegistration?.remove()
        currentUserVotesListener?.remove()
    }
    
    func startListeningToMessages() {
        listenerRegistration = db.collection("fan_mail")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.messages = documents.compactMap { document in
                    try? document.data(as: FanMailMessage.self)
                }
            }
    }
    
    func startListeningToUserVotes(userId: String) {
        guard currentUserVotesListener == nil else { return }
        
        currentUserVotesListener = db.collection("user_votes")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() as? [String: Int] else { return }
                self.userVotes = data
            }
    }
    
    func postMessage(text: String, zineId: String, zineName: String) throws {
        let message = FanMailMessage(
            text: text,
            zineId: zineId,
            zineName: zineName,
            createdAt: Date(),
            votes: 0
        )
        
        try db.collection("fan_mail").document().setData(from: message)
    }
    
    func vote(messageId: String, userId: String, isUpvote: Bool) async throws {
        // Start a new batch
        let batch = db.batch()
        
        // Reference to the message document
        let messageRef = db.collection("fan_mail").document(messageId)
        
        // Reference to the user's votes document
        let userVotesRef = db.collection("user_votes").document(userId)
        
        // Get the current vote value for this message (if any)
        let currentVote = userVotes[messageId] ?? 0
        let newVote = isUpvote ? 1 : -1
        
        // If they're clicking the same vote again, remove their vote
        let finalVote = currentVote == newVote ? 0 : newVote
        
        // Calculate vote delta
        let voteDelta = finalVote - currentVote
        
        // Update the message's vote count
        batch.updateData([
            "votes": FieldValue.increment(Int64(voteDelta))
        ], forDocument: messageRef)
        
        // Update or remove the user's vote
        if finalVote == 0 {
            batch.updateData([
                messageId: FieldValue.delete()
            ], forDocument: userVotesRef)
        } else {
            batch.setData([
                messageId: finalVote
            ], forDocument: userVotesRef, merge: true)
        }
        
        // Commit the batch
        try await batch.commit()
    }
    
    func filterMessages(byZineIds zineIds: Set<String>) -> [FanMailMessage] {
        guard !zineIds.isEmpty else { return messages }
        return messages.filter { zineIds.contains($0.zineId) }
    }
}
