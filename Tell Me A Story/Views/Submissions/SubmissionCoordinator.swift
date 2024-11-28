import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

enum SubmissionType {
    case zine
    case issue
}

class SubmissionCoordinator: ObservableObject {
    @Published var submissionType: SubmissionType?
    @Published var isSubmitting = false
    @Published var showAuthPrompt = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func submitZine(name: String, bio: String, instagramUrl: String, coverImage: UIImage) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAuthPrompt = true
            return
        }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
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
        } catch {
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
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
}

struct SubmissionTypeSelectionView: View {
    @StateObject private var coordinator = SubmissionCoordinator()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("What would you like to submit?")
                    .font(.headline)
                
                NavigationLink {
                    ZineSubmissionForm()
                        .environmentObject(coordinator)
                } label: {
                    Text("New Zine")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink {
                    IssueSubmissionForm()
                        .environmentObject(coordinator)
                } label: {
                    Text("New Issue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
