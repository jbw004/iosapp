import SwiftUI
import UIKit

struct PassportView: View {
    @EnvironmentObject var readService: ReadService
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedCanvasIndex = 0
    @State private var isGeneratingImage = false
    @State private var showingAuthSheet = false
    @State private var showingSaveSuccess = false
    
    // Canvas options from your data.json
    private let canvasOptions = [
        CanvasTemplate(id: "template_1", name: "Template 1", imageUrl: "https://raw.githubusercontent.com/jbw004/zine-data/main/images/template_1.png"),
        CanvasTemplate(id: "template_2", name: "Template 2", imageUrl: "https://raw.githubusercontent.com/jbw004/zine-data/main/images/template_2.png"),
        CanvasTemplate(id: "template_3", name: "Template 3", imageUrl: "https://raw.githubusercontent.com/jbw004/zine-data/main/images/template_3.png"),
        CanvasTemplate(id: "template_4", name: "Template 4", imageUrl: "https://raw.githubusercontent.com/jbw004/zine-data/main/images/template_4.png")
    ]
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                SignInPromptView(showingAuthSheet: $showingAuthSheet)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Canvas Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<canvasOptions.count, id: \.self) { index in
                                    CanvasPreviewButton(
                                        canvas: canvasOptions[index],
                                        isSelected: selectedCanvasIndex == index,
                                        action: { selectedCanvasIndex = index }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Passport Preview
                        PassportPreviewView(
                            canvas: canvasOptions[selectedCanvasIndex],
                            readService: readService
                        )
                        .frame(height: UIScreen.main.bounds.width * 1.3) // Adjustable aspect ratio
                        .padding(.horizontal)
                        
                        // Save Button
                        Button(action: savePassport) {
                            HStack {
                                if isGeneratingImage {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save to Photos")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isGeneratingImage)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .alert("Saved!", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func savePassport() {
        isGeneratingImage = true
        
        Task {
            do {
                let passport = try await PassportGenerator.generatePassport(
                    canvas: canvasOptions[selectedCanvasIndex],
                    readIssues: Array(try await readService.fetchGroupedReadIssues().values.joined())
                )
                
                try await PassportGenerator.saveToPhotos(image: passport)
                
                await MainActor.run {
                    showingSaveSuccess = true
                    isGeneratingImage = false
                }
            } catch {
                print("Error saving passport: \(error)")
                await MainActor.run {
                    isGeneratingImage = false
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct CanvasPreviewButton: View {
    let canvas: CanvasTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AsyncImage(url: URL(string: canvas.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 100)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
    }
}

struct PassportPreviewView: View {
    let canvas: CanvasTemplate
    let readService: ReadService
    @State private var groupedIssues: [String: [ReadIssue]] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas Background
                AsyncImage(url: URL(string: canvas.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                
                // Issue Covers
                ForEach(Array(groupedIssues.values.joined()), id: \.id) { issue in
                    AsyncImage(url: URL(string: issue.coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .position(
                        x: CGFloat.random(in: 30...(geometry.size.width - 30)),
                        y: CGFloat.random(in: 30...(geometry.size.height - 30))
                    )
                }
            }
            .clipped()
            .cornerRadius(12)
        }
        .task {
            do {
                groupedIssues = try await readService.fetchGroupedReadIssues()
            } catch {
                print("Error loading issues: \(error)")
            }
        }
    }
}

// MARK: - Models
struct CanvasTemplate: Identifiable {
    let id: String
    let name: String
    let imageUrl: String
}

struct SignInPromptView: View {
    @Binding var showingAuthSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Sign in to see your reading passport")
                .font(.headline)
            
            Button("Sign In") {
                showingAuthSheet = true
            }
            .buttonStyle(.bordered)
        }
    }
}
