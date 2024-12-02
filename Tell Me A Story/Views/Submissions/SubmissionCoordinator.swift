import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum SubmissionType {
    case zine
    case issue
    
    var analyticsName: String {
        switch self {
        case .zine: return "zine"
        case .issue: return "issue"
        }
    }
}

class SubmissionCoordinator: ObservableObject {
    @Published var submissionType: SubmissionType?
    @Published var isSubmitting = false
    @Published var showAuthPrompt = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let analytics = AnalyticsService.shared
    
    func submitZine(name: String, bio: String, instagramUrl: String, coverImage: UIImage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAuthPrompt = true
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Track submission start
        analytics.trackEvent(.submissionStarted(type: SubmissionType.zine.analyticsName))
        
        do {
            // Upload image
            let imageData = coverImage.jpegData(compressionQuality: 0.8)!
            let imagePath = "submissions/zines/\(UUID().uuidString)/cover.jpg"
            let imageRef = storage.reference().child(imagePath)
            _ = try await imageRef.putDataAsync(imageData)
            
            // Create and store submission
            let submission = ZineSubmission(
                userId: userId,
                timestamp: Date(),
                name: name,
                bio: bio,
                instagramUrl: instagramUrl,
                coverImagePath: imagePath
            )
            
            try await db.collection("zine_submissions").addDocument(data: [
                "userId": submission.userId,
                "timestamp": submission.timestamp,
                "name": submission.name,
                "bio": submission.bio,
                "instagramUrl": submission.instagramUrl,
                "coverImagePath": submission.coverImagePath
            ])
            
            // Track successful submission
            analytics.trackEvent(.submissionCompleted(type: SubmissionType.zine.analyticsName))
            
        } catch {
            // Track failed submission
            analytics.trackEvent(.submissionFailed(
                type: SubmissionType.zine.analyticsName,
                error: error.localizedDescription
            ))
            
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
    
    func submitIssue(zineId: String, title: String, publishedDate: String, linkUrl: String, coverImage: UIImage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAuthPrompt = true
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Track submission start
        analytics.trackEvent(.submissionStarted(type: SubmissionType.issue.analyticsName))
        
        do {
            // Upload image
            let imageData = coverImage.jpegData(compressionQuality: 0.8)!
            let imagePath = "submissions/issues/\(UUID().uuidString)/cover.jpg"
            let imageRef = storage.reference().child(imagePath)
            _ = try await imageRef.putDataAsync(imageData)
            
            // Create submission
            let submission = IssueSubmission(
                userId: userId,
                timestamp: Date(),
                zineId: zineId,
                title: title,
                publishedDate: publishedDate,
                coverImagePath: imagePath,
                linkUrl: linkUrl
            )
            
            try await db.collection("issue_submissions").addDocument(data: [
                "userId": submission.userId,
                "timestamp": submission.timestamp,
                "zineId": submission.zineId,
                "title": submission.title,
                "publishedDate": submission.publishedDate,
                "coverImagePath": submission.coverImagePath,
                "linkUrl": submission.linkUrl
            ])
            
            // Track successful submission
            analytics.trackEvent(.submissionCompleted(type: SubmissionType.issue.analyticsName))
            
        } catch {
            // Track failed submission
            analytics.trackEvent(.submissionFailed(
                type: SubmissionType.issue.analyticsName,
                error: error.localizedDescription
            ))
            
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
}

struct SubmissionTypeSelectionView: View {
    @StateObject private var coordinator = SubmissionCoordinator()
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var showingAuthSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !authService.isAuthenticated {
                    Text("Login to Submit a Zine or Issue")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                } else {
                    Text("What would you like to submit?")
                        .font(.headline)
                }
                
                // Zine Button
                NavigationLink {
                    ZineSubmissionForm()
                        .environmentObject(coordinator)
                } label: {
                    Text("New Zine")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(authService.isAuthenticated ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!authService.isAuthenticated)
                
                // Issue Button
                NavigationLink {
                    IssueSubmissionForm()
                        .environmentObject(coordinator)
                } label: {
                    Text("New Issue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(authService.isAuthenticated ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!authService.isAuthenticated)
                
                if !authService.isAuthenticated {
                    Button("Login") {
                        showingAuthSheet = true
                    }
                    .padding(.top, 20)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Submit Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}

struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        PhotosPicker(selection: .init(get: { nil }, set: { newValue in
            Task {
                if let imageData = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        selectedImage = uiImage
                    }
                }
            }
        }), matching: .images) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}
