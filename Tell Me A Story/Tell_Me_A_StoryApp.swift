import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    let deepLinkManager = DeepLinkManager.shared
    let notificationService = NotificationService.shared
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Track app open
        AnalyticsService.shared.trackEvent(.appOpen)
        
        return true
    }
    
    // Handle device token for APNs
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Store FCM token if needed
        print("Firebase registration token: \(String(describing: fcmToken))")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Print message ID for debugging
        if let messageID = userInfo["gcm.message_id"] as? String {
            print("Message ID: \(messageID)")
        }
        
        // Show banner and play sound for notifications while app is in foreground
        completionHandler([[.banner, .sound]])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Print message ID for debugging
        if let messageID = userInfo["gcm.message_id"] as? String {
            print("Message ID: \(messageID)")
        }
        
        // Handle notification data - you can add custom handling here
        if let zineId = userInfo["zine_id"] as? String {
            deepLinkManager.handleDeepLink(zineId)
        }
        
        completionHandler()
    }
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    @Published var deepLinkZineId: String?
    private init() {}
    
    func handleDeepLink(_ zineId: String) {
        DispatchQueue.main.async {
            self.deepLinkZineId = zineId
        }
    }
}

@main
struct Tell_Me_A_StoryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkZineId: Binding(
                get: { deepLinkManager.deepLinkZineId },
                set: { deepLinkManager.deepLinkZineId = $0 }
            ))
            .environmentObject(authService)
            .onOpenURL { url in
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   components.path.starts(with: "/zine/") {
                    let zineId = components.path.replacingOccurrences(of: "/zine/", with: "")
                    deepLinkManager.handleDeepLink(zineId)
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let incomingURL = userActivity.webpageURL,
                   let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
                   components.path.starts(with: "/zine/") {
                    let zineId = components.path.replacingOccurrences(of: "/zine/", with: "")
                    deepLinkManager.handleDeepLink(zineId)
                }
            }
        }
    }
}
