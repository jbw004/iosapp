import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

enum NotificationError: LocalizedError {
    case notificationsDenied
    case notificationsNotDetermined
    case firebaseError(String)
    case initializationError
    case subscriptionError(String)
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .notificationsDenied:
            return "Push notifications are disabled. Please enable them in Settings."
        case .notificationsNotDetermined:
            return "Please allow push notifications to follow zines."
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        case .initializationError:
            return "Failed to initialize Firebase services"
        case .subscriptionError(let message):
            return "Failed to subscribe: \(message)"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var followedZines: Set<String> = []
    @Published var error: NotificationError?
    @Published var debugMessage: String?  // For debugging
    
    // Make these optional and lazy initialize them
    private var messaging: Messaging?
    private var db: Firestore?
    private var analytics: AnalyticsService?
    
    private override init() {
        super.init()
        debugMessage = "NotificationService initialized"
    }
    
    // Add a setup method that ensures everything is initialized
    private func ensureInitialized() {
        if messaging == nil {
            messaging = Messaging.messaging()
            messaging?.delegate = self  // Add this line here
            debugMessage = "Messaging initialized"
        }
        if db == nil {
            db = Firestore.firestore()
            debugMessage = "Firestore initialized"
        }
        if analytics == nil {
            analytics = AnalyticsService.shared
            debugMessage = "Analytics initialized"
        }
    }
    
    func requestNotificationPermissions() async throws {
        ensureInitialized()
        debugMessage = "Requesting notification permissions"
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        do {
            let settings = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            
            if settings {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    debugMessage = "Notification permissions granted"
                }
                
                // Wait for FCM token
                _ = try await Messaging.messaging().token()
                debugMessage = "FCM token retrieved"
            } else {
                debugMessage = "Notification permissions denied"
                throw NotificationError.notificationsDenied
            }
        } catch {
            debugMessage = "Notification permission error: \(error.localizedDescription)"
            throw NotificationError.notificationsDenied
        }
    }

    func followZine(_ zine: Zine) async throws {
        ensureInitialized()
        guard let userId = Auth.auth().currentUser?.uid else {
            debugMessage = "No authenticated user"
            throw NotificationError.firebaseError("No authenticated user")
        }
        
        guard let messaging = messaging, let db = db else {
            debugMessage = "Services not initialized"
            throw NotificationError.initializationError
        }
        
        do {
            debugMessage = "Attempting to subscribe to topic: zine_\(zine.id)"
            try await messaging.subscribe(toTopic: "zine_\(zine.id)")
            
            debugMessage = "Subscription successful, updating Firestore"
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).setData([
                    "zineName": zine.name,
                    "followedAt": FieldValue.serverTimestamp()
                ])
            
            await MainActor.run {
                self.followedZines.insert(zine.id)
                self.debugMessage = "Follow operation completed successfully"
            }
            
        } catch {
            debugMessage = "Error during follow operation: \(error.localizedDescription)"
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }

    func unfollowZine(_ zine: Zine) async throws {
        ensureInitialized()
        guard let userId = Auth.auth().currentUser?.uid else {
            debugMessage = "No authenticated user"
            throw NotificationError.firebaseError("No authenticated user")
        }
        
        guard let messaging = messaging, let db = db else {
            debugMessage = "Services not initialized"
            throw NotificationError.initializationError
        }
        
        do {
            debugMessage = "Attempting to unsubscribe from topic: zine_\(zine.id)"
            try await messaging.unsubscribe(fromTopic: "zine_\(zine.id)")
            
            debugMessage = "Unsubscribe successful, updating Firestore"
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).delete()
            
            await MainActor.run {
                self.followedZines.remove(zine.id)
                self.debugMessage = "Unfollow operation completed successfully"
            }
            
        } catch {
            debugMessage = "Error during unfollow operation: \(error.localizedDescription)"
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }
    
    func isFollowingZine(_ zineId: String) -> Bool {
        followedZines.contains(zineId)
    }
    
    func cleanup() {
            debugMessage = "Cleaning up notification service"
            DispatchQueue.main.async {
                self.followedZines.removeAll()
            }
        }
    
    func setupForUser() {
        ensureInitialized()
        debugMessage = "Setting up for user"
        
        // Request permissions right away
        Task {
            do {
                try await requestNotificationPermissions()
                debugMessage = "Permissions requested, loading followed zines"
                loadFollowedZines()  // Make sure this runs even if permissions fail
            } catch {
                debugMessage = "Failed to request permissions: \(error.localizedDescription)"
                loadFollowedZines()  // Still try to load followed zines even if permissions fail
            }
        }
    }

    private func loadFollowedZines() {
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db else {
            debugMessage = "Cannot load zines - missing user or database"
            return
        }
        
        debugMessage = "Setting up Firestore listener for user: \(userId)"
        
        db.collection("users").document(userId)
            .collection("followed_zines")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.debugMessage = "Snapshot error: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.debugMessage = "No documents in snapshot"
                    return
                }
                
                let zineIds = Set(documents.map { $0.documentID })
                
                DispatchQueue.main.async {
                    self?.followedZines = zineIds
                    self?.debugMessage = "Updated followed zines from Firestore: \(zineIds.count) items - IDs: \(zineIds.joined(separator: ", "))"
                }
            }
    }
}

// Add this extension at the bottom of the file
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        debugMessage = "Received new FCM token"
        
        // Optional: Store the token in UserDefaults or send to your server
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "FCMToken")
        }
    }
}
