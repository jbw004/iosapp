import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

struct FollowedZineMetadata: Codable {
    let zineName: String
    let followedAt: Date
    let lastViewedAt: Date?
    let lastNotificationAt: Date?
    var hasUnreadIssues: Bool
}

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
    
    @Published var notificationStatus: String = "Not initialized"
    @Published var followedZines: Set<String> = []
    @Published var followedZinesMetadata: [String: FollowedZineMetadata] = [:]  // Add this
    @Published var unreadCount: Int = 0  // Add this
    @Published var error: NotificationError?
    
    // Make these optional and lazy initialize them
    private var messaging: Messaging?
    private var db: Firestore?
    private var analytics: AnalyticsService?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationStatus() // Add this line
    }
    
    // Add a setup method that ensures everything is initialized
    private func ensureInitialized() {
        if messaging == nil {
            messaging = Messaging.messaging()
            messaging?.delegate = self  // Add this line here
        }
        if db == nil {
            db = Firestore.firestore()
        }
        if analytics == nil {
            analytics = AnalyticsService.shared
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = "Authorization: \(settings.authorizationStatus.rawValue)\nAlert: \(settings.alertSetting.rawValue)\nSound: \(settings.soundSetting.rawValue)\nBadge: \(settings.badgeSetting.rawValue)"
            }
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
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NotificationError.firebaseError("No authenticated user")
        }
        
        guard let messaging = messaging, let db = db else {
            throw NotificationError.initializationError
        }
        
        do {
            try await messaging.subscribe(toTopic: "zine_\(zine.id)")
            
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).setData([
                    "zineName": zine.name,
                    "zineId": zine.id,  // Add this line
                    "followedAt": FieldValue.serverTimestamp(),
                    "lastNotificationAt": NSNull(),
                    "hasUnreadIssues": false
                ])
            
            await MainActor.run {
                self.followedZines.insert(zine.id)
                return
            }
            
        } catch {
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }

    func unfollowZine(_ zine: Zine) async throws {
        ensureInitialized()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NotificationError.firebaseError("No authenticated user")
        }
        
        guard let messaging = messaging, let db = db else {
            throw NotificationError.initializationError
        }
        
        do {
            try await messaging.unsubscribe(fromTopic: "zine_\(zine.id)")
            
            try await db.collection("users").document(userId)
                .collection("followed_zines").document(zine.id).delete()
            
            await MainActor.run {
                self.followedZines.remove(zine.id)
                return
            }
            
        } catch {
            throw NotificationError.firebaseError(error.localizedDescription)
        }
    }
    
    func isFollowingZine(_ zineId: String) -> Bool {
        followedZines.contains(zineId)
    }
    
    func cleanup() {
            DispatchQueue.main.async {
                self.followedZines.removeAll()
            }
        }
    
    func updateLastViewed(for zine: Zine) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db else {
            throw NotificationError.firebaseError("No authenticated user")
        }
        
        try await db.collection("users").document(userId)
            .collection("followed_zines").document(zine.id)
            .setData([
                "lastViewedAt": FieldValue.serverTimestamp(),
                "hasUnreadIssues": false
            ], merge: true)
    }
    
    func setupForUser() {
        ensureInitialized()
        
        // Request permissions right away
        Task {
            do {
                try await requestNotificationPermissions()
                loadFollowedZines()  // Make sure this runs even if permissions fail
            } catch {
                loadFollowedZines()  // Still try to load followed zines even if permissions fail
            }
        }
    }

    private func loadFollowedZines() {
        guard let userId = Auth.auth().currentUser?.uid,
              let db = db else {
            return
        }
        
        db.collection("users").document(userId)
            .collection("followed_zines")
            .addSnapshotListener { [weak self] snapshot, error in
                if error != nil {
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                var newMetadata: [String: FollowedZineMetadata] = [:]
                var unreadCount = 0
                
                for document in documents {
                    let zineId = document.documentID
                    let data = document.data()
                    
                    let metadata = FollowedZineMetadata(
                        zineName: data["zineName"] as? String ?? "",
                        followedAt: (data["followedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        lastViewedAt: (data["lastViewedAt"] as? Timestamp)?.dateValue(),
                        lastNotificationAt: (data["lastNotificationAt"] as? Timestamp)?.dateValue(),
                        hasUnreadIssues: data["hasUnreadIssues"] as? Bool ?? false
                    )
                    
                    newMetadata[zineId] = metadata
                    if metadata.hasUnreadIssues {
                        unreadCount += 1
                    }
                }
                
                DispatchQueue.main.async {
                    self?.followedZinesMetadata = newMetadata
                    self?.followedZines = Set(newMetadata.keys)
                    self?.unreadCount = unreadCount
                }
            }
    }
    
    func verifyNotificationSetup() async throws {
        
        do {
            _ = await UNUserNotificationCenter.current().notificationSettings()
            
            if try await messaging?.token() != nil {
                if let firstZine = followedZines.first {
                    try await messaging?.subscribe(toTopic: "zine_\(firstZine)")
                }
            }
        } catch {
            throw NotificationError.initializationError  // Or handle the error appropriately
        }
    }
}

// Add this extension at the bottom of the file
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Optional: Store the token in UserDefaults or send to your server
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "FCMToken")
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}


