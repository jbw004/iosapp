import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

enum NotificationError: LocalizedError {
    case notificationsDenied
    case notificationsNotDetermined
    case firebaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .notificationsDenied:
            return "Push notifications are disabled. Please enable them in Settings."
        case .notificationsNotDetermined:
            return "Please allow push notifications to follow zines."
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        }
    }
}

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var followedZines: Set<String> = []
    @Published var error: NotificationError?
    
    // Make these optional and lazy initialize them
    private var messaging: Messaging?
    private var db: Firestore?
    private var analytics: AnalyticsService?
    
    private init() {
        // Don't initialize anything in init
    }
    
    // Add a setup method that ensures everything is initialized
    private func ensureInitialized() {
        if messaging == nil {
            messaging = Messaging.messaging()
        }
        if db == nil {
            db = Firestore.firestore()
        }
        if analytics == nil {
            analytics = AnalyticsService.shared
        }
    }
    
    func requestNotificationPermissions() async throws {
        ensureInitialized()
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        do {
            let settings = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            
            if settings {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                throw NotificationError.notificationsDenied
            }
        } catch {
            throw NotificationError.notificationsDenied
        }
    }

    func followZine(_ zine: Zine) async throws {
        ensureInitialized()
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db,
              let messaging = messaging,
              let analytics = analytics else { return }
        
        do {
            try await messaging.subscribe(toTopic: "zine_\(zine.id)")
            
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).setData([
                    "zineName": zine.name,
                    "followedAt": FieldValue.serverTimestamp()
                ])
            
            followedZines.insert(zine.id)
            
            analytics.trackEvent(.followZine(zineId: zine.id, zineName: zine.name))
            
        } catch {
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }

    func unfollowZine(_ zine: Zine) async throws {
        ensureInitialized()
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db,
              let messaging = messaging,
              let analytics = analytics else { return }
        
        do {
            try await messaging.unsubscribe(fromTopic: "zine_\(zine.id)")
            
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).delete()
            
            followedZines.remove(zine.id)
            
            analytics.trackEvent(.unfollowZine(zineId: zine.id, zineName: zine.name))
            
        } catch {
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }
    
    func isFollowingZine(_ zineId: String) -> Bool {
        followedZines.contains(zineId)
    }
    
    func setupForUser() {
        ensureInitialized()
        loadFollowedZines()
    }
    
    private func loadFollowedZines() {
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db else { return }
        
        db.collection("users").document(userId)
            .collection("followed_zines")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let zineIds = Set(documents.map { $0.documentID })
                
                DispatchQueue.main.async {
                    self?.followedZines = zineIds
                }
            }
    }
}
