import Foundation
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseCrashlytics
import FirebaseAuth

enum AnalyticsEventType {
    case appOpen
    case signUpSuccess(method: String)
    case signUpFailure(method: String, error: String)
    case signInSuccess(method: String)
    case signInFailure(method: String, error: String)
    case magazineView(zineId: String, zineName: String)
    case issueClick(zineId: String, zineName: String, issueId: String, issueTitle: String, publishedDate: String, success: Bool)
    case instagramClick(zineId: String, zineName: String, success: Bool)
    case shareAction(zineId: String, zineName: String)
    case submissionStarted(type: String)
    case submissionCompleted(type: String)
    case submissionFailed(type: String, error: String)
    case followZine(zineId: String, zineName: String)
    case unfollowZine(zineId: String, zineName: String)
    
    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .signUpSuccess: return "sign_up_success"
        case .signUpFailure: return "sign_up_failure"
        case .signInSuccess: return "sign_in_success"
        case .signInFailure: return "sign_in_failure"
        case .magazineView: return "magazine_view"
        case .issueClick: return "issue_click"
        case .instagramClick: return "instagram_click"
        case .shareAction: return "share_action"
        case .submissionStarted: return "submission_started"
        case .submissionCompleted: return "submission_completed"
        case .submissionFailed: return "submission_failed"
        case .followZine: return "follow_zine"
        case .unfollowZine: return "unfollow_zine"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .appOpen:
            return [:]
            
        case .signUpSuccess(let method), .signInSuccess(let method):
            return ["method": method]
            
        case .signUpFailure(let method, let error), .signInFailure(let method, let error):
            return [
                "method": method,
                "error": error
            ]
            
        case .magazineView(let zineId, let zineName):
            return [
                "zine_id": zineId,
                "zine_name": zineName
            ]
            
        case .issueClick(let zineId, let zineName, let issueId, let issueTitle, let publishedDate, let success):
            return [
                "zine_id": zineId,
                "zine_name": zineName,
                "issue_id": issueId,
                "issue_title": issueTitle,
                "published_date": publishedDate,
                "success": success
            ]
            
        case .instagramClick(let zineId, let zineName, let success):
            return [
                "zine_id": zineId,
                "zine_name": zineName,
                "success": success
            ]
            
        case .shareAction(let zineId, let zineName):
            return [
                "zine_id": zineId,
                "zine_name": zineName
            ]
            
        case .submissionStarted(let type), .submissionCompleted(let type):
            return ["type": type]
            
        case .submissionFailed(let type, let error):
            return [
                "type": type,
                "error": error
            ]
            
        case .followZine(let zineId, let zineName), .unfollowZine(let zineId, let zineName):
            return [
                "zine_id": zineId,
                "zine_name": zineName
            ]
        }
    }
}

class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let analytics = Analytics.self
    private let db = Firestore.firestore()
    private let crashlytics = Crashlytics.crashlytics()
    
    private init() {}
    
    func trackEvent(_ event: AnalyticsEventType) {
        // Track in Firebase Analytics
        analytics.logEvent(event.name, parameters: event.parameters)
        
        // Store in Firestore
        storeEventInFirestore(event)
        
        // Log to console in debug builds
        #if DEBUG
        print("📊 Analytics Event: \(event.name)")
        print("Parameters: \(event.parameters)")
        #endif
    }
    
    private func storeEventInFirestore(_ event: AnalyticsEventType) {
        var data: [String: Any] = [
            "event_name": event.name,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Add user ID if available
        if let userId = Auth.auth().currentUser?.uid {
            data["user_id"] = userId
        }
        
        // Add event-specific parameters
        data["parameters"] = event.parameters
        
        // Store in Firestore
        db.collection("analytics_events").addDocument(data: data) { error in
            if let error = error {
                print("Error storing analytics event: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Tracking
    
    func logError(_ error: Error, additionalParameters: [String: Any]? = nil) {
        crashlytics.record(error: error)
        
        if let params = additionalParameters {
            crashlytics.setCustomKeysAndValues(params)
        }
    }
    
    // MARK: - User Properties
    
    func setUserIdentifier(_ userId: String) {
        analytics.setUserID(userId)
        crashlytics.setUserID(userId)
    }
}
