import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

class AuthenticationService: NSObject, ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var debugMessage: String?  // Add this for debugging

    
    // Needed for Sign in with Apple
    private var currentNonce: String?
    private let analytics = AnalyticsService.shared
    private let db = Firestore.firestore() 
    
    override init() {
            super.init()
            
            debugMessage = "AuthenticationService initialized"
            
            // Store the listener to keep it alive
            _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.debugMessage = "Auth state changed: user \(user != nil ? "logged in" : "logged out")"
                    self?.user = user
                    self?.isAuthenticated = user != nil
                    
                    // Set user ID for analytics if available
                    if let userId = user?.uid {
                        self?.analytics.setUserIdentifier(userId)
                        self?.debugMessage = "Setting up notifications for user: \(userId)"
                        NotificationService.shared.setupForUser()
                    }
                }
            }
        }
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error
                    self?.analytics.trackEvent(.signInFailure(
                        method: "email",
                        error: error.localizedDescription
                    ))
                } else {
                    self?.authError = nil
                    self?.analytics.trackEvent(.signInSuccess(method: "email"))
                }
            }
        }
    }
    
    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error
                    self?.analytics.trackEvent(.signUpFailure(
                        method: "email",
                        error: error.localizedDescription
                    ))
                } else {
                    self?.authError = nil
                    self?.analytics.trackEvent(.signUpSuccess(method: "email"))
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            NotificationService.shared.cleanup()  // Add this line
        } catch {
            self.authError = error
            analytics.trackEvent(.signInFailure(
                method: "signout",
                error: error.localizedDescription
            ))
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        // Start a batch write to delete user data
        let batch = db.batch()
        
        // Delete user's bookmarks
        let bookmarksRef = db.collection("users").document(user.uid).collection("bookmarked_issues")
        let bookmarkDocs = try await bookmarksRef.getDocuments()
        bookmarkDocs.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }
        
        // Delete user's followed zines
        let followedRef = db.collection("users").document(user.uid).collection("followed_zines")
        let followedDocs = try await followedRef.getDocuments()
        followedDocs.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }
        
        // Delete user's read issues
        let readRef = db.collection("users").document(user.uid).collection("read_issues")
        let readDocs = try await readRef.getDocuments()
        readDocs.documents.forEach { doc in
            batch.deleteDocument(doc.reference)
        }
        
        // Delete user's votes
        let votesRef = db.collection("user_votes").document(user.uid)
        batch.deleteDocument(votesRef)
        
        // Commit all deletions
        try await batch.commit()
        
        // Finally, delete the user account
        try await user.delete()
        
        // Track the deletion in analytics
        analytics.trackEvent(.signInFailure(
            method: "account_deletion",
            error: "User initiated account deletion"
        ))
    }
    
    // MARK: - Sign in with Apple
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let idTokenString = String(data: appleIDToken, encoding: .utf8),
           let nonce = currentNonce {
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.authError = error
                        self?.analytics.trackEvent(.signInFailure(
                            method: "apple",
                            error: error.localizedDescription
                        ))
                    } else {
                        self?.authError = nil
                        self?.analytics.trackEvent(.signInSuccess(method: "apple"))
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.authError = error
            self.analytics.trackEvent(.signInFailure(
                method: "apple",
                error: error.localizedDescription
            ))
        }
    }
}
