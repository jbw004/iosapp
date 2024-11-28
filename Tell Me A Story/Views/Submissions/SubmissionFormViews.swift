import SwiftUI
import UIKit
import Foundation
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ZineSubmissionForm: View {
    @EnvironmentObject var coordinator: SubmissionCoordinator
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    
    @State private var name = ""
    @State private var bio = ""
    @State private var instagramUrl = ""
    @State private var selectedImage: UIImage?
    @State private var showingAuthSheet = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCelebration = false  // Add this with your other @State variables
    
    var body: some View {
        ZStack {  // New wrapper
            Form {
                Section("Cover Image") {
                    ImagePickerView(selectedImage: $selectedImage)
                }
                
                Section("Zine Details") {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Instagram URL", text: $instagramUrl)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section {
                    Button(action: submit) {
                        Text("Submit")
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isSubmitting || !isValid)
                }
            }
            .disabled(isSubmitting)  // Disable the whole form while submitting
                
            if isSubmitting {
                LoadingView()
            }
                
            if showCelebration {
                ConfettiView {
                    dismiss()
                }
            }
        }
        .navigationTitle("Submit Zine")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !bio.isEmpty && !instagramUrl.isEmpty && selectedImage != nil
    }
    
    private func submit() {
        guard let image = selectedImage else { return }
        isSubmitting = true
        
        Task {
            do {
                try await coordinator.submitZine(
                    name: name,
                    bio: bio,
                    instagramUrl: instagramUrl,
                    coverImage: image
                )
                isSubmitting = false
                showCelebration = true  // Show celebration instead of immediate dismiss
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct IssueSubmissionForm: View {
    @EnvironmentObject var coordinator: SubmissionCoordinator
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @StateObject private var zineService = ZineService()
    
    @State private var selectedZine: Zine?
    @State private var title = ""
    @State private var publishedDate = Date()
    @State private var linkUrl = ""
    @State private var selectedImage: UIImage?
    @State private var showingAuthSheet = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCelebration = false
    
    var body: some View {
        ZStack {
            Form {
                Section("Cover Image") {
                    ImagePickerView(selectedImage: $selectedImage)
                }
                
                Section("Issue Details") {
                    ZinePicker(selectedZine: $selectedZine)
                        .environmentObject(zineService)
                    TextField("Title", text: $title)
                    DatePicker("Published Date", selection: $publishedDate, displayedComponents: .date)
                    TextField("Link URL", text: $linkUrl)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section {
                    Button(action: submit) {
                        Text("Submit")
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isSubmitting || !isValid)
                }
            }
            .disabled(isSubmitting)
            
            if isSubmitting {
                LoadingView()
            }
            
            if showCelebration {
                ConfettiView {
                    dismiss()
                }
            }
        }
        .navigationTitle("Submit Issue")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        selectedZine != nil && !title.isEmpty && !linkUrl.isEmpty && selectedImage != nil
    }
    
    private func submit() {
        guard let zine = selectedZine, let image = selectedImage else { return }
        isSubmitting = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: publishedDate)
        
        Task {
            do {
                try await coordinator.submitIssue(
                    zineId: zine.id,
                    title: title,
                    publishedDate: formattedDate,
                    linkUrl: linkUrl,
                    coverImage: image
                )
                isSubmitting = false
                showCelebration = true
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
