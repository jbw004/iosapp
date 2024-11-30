import SwiftUI
import FirebaseCore

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

class AppDelegate: NSObject, UIApplicationDelegate {
    let deepLinkManager = DeepLinkManager.shared
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
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
