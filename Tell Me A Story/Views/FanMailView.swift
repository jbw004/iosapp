import SwiftUI

struct FanMailView: View {
    @Binding var selectedFooterTab: TabItem
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var zineService: ZineService
    @StateObject private var fanMailService = FanMailService()
    
    @State private var messageText = ""
    @State private var showingTagPicker = false
    @State private var selectedZineId: String?
    @State private var selectedZineName: String?
    @State private var showHeader = true
    @State private var searchText = ""
    @State private var showingAuthSheet = false

    
    private let maxCharacterCount = 120
    
    var filteredMessages: [FanMailMessage] {
        if searchText.isEmpty {
            return fanMailService.messages
        }
        return fanMailService.messages.filter { message in
            // Fuzzy matching logic - checks if search terms appear in order
            let searchTerms = searchText.lowercased().split(separator: " ")
            let zineName = message.zineName.lowercased()
            
            var currentIndex = zineName.startIndex
            for term in searchTerms {
                if let range = zineName[currentIndex...].range(of: term) {
                    currentIndex = range.upperBound
                } else {
                    return false
                }
            }
            return true
        }
    }
    
    var displayedMessages: [FanMailMessage] {
            let downvoteThreshold = -2  // Messages with votes <= this threshold will be hidden
            return filteredMessages.filter { message in
                message.votes > downvoteThreshold
            }
        }
    
    var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                CustomNavigationView(
                    selectedTab: .constant(0),
                    isDetailView: true
                ) {
                    selectedFooterTab = .home
                }
                .transition(.move(edge: .top))
            }
            
            // Search Section
            SearchSection(searchText: $searchText)
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedMessages) { message in
                            MessageRow(
                                message: message,
                                userVote: fanMailService.userVotes[message.id ?? ""] ?? 0,
                                onUpvote: {
                                    handleVote(for: message, isUpvote: true)
                                },
                                onDownvote: {
                                    handleVote(for: message, isUpvote: false)
                                }
                            )
                            .id(message.id)
                        }

                        if displayedMessages.isEmpty {
                            Text("No messages found")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    .padding()
                }
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            hideKeyboard()
                        }
                )
            }
            
            // Message Composer (rest remains the same)
            UnifiedMessageInput(
                messageText: $messageText,
                selectedZineName: $selectedZineName,
                onTagTap: {
                    if authService.isAuthenticated {
                        showingTagPicker = true
                    } else {
                        // Show auth sheet
                        showingAuthSheet = true
                    }
                },
                onSend: submitMessage,
                isAuthenticated: authService.isAuthenticated
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTagPicker) {
            ZineTagPickerView(
                zines: zineService.zines,
                selectedZineId: $selectedZineId,
                selectedZineName: $selectedZineName
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .onAppear {
            if let userId = authService.user?.uid {
                fanMailService.startListeningToUserVotes(userId: userId)
            }
            
            // Add this to load zines if they haven't been loaded yet
            if zineService.zines.isEmpty {
                Task {
                    await zineService.fetchZines()
                }
            }
        }
    }
    
    // Your existing handleVote and submitMessage functions remain the same
    private func handleVote(for message: FanMailMessage, isUpvote: Bool) {
        guard let messageId = message.id,
              let userId = authService.user?.uid else { return }
        
        Task {
            try? await fanMailService.vote(
                messageId: messageId,
                userId: userId,
                isUpvote: isUpvote
            )
        }
    }
    
    private func submitMessage() {
        guard let zineId = selectedZineId,
              let zineName = selectedZineName,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              messageText.count <= 140 else { return }
        
        do {
            try fanMailService.postMessage(
                text: messageText,
                zineId: zineId,
                zineName: zineName
            )
            messageText = ""
        } catch {
            print("Error posting message: \(error)")
        }
    }
}

struct UnifiedMessageInput: View {
    @Binding var messageText: String
    @Binding var selectedZineName: String?
    var onTagTap: () -> Void
    var onSend: () -> Void
    var isAuthenticated: Bool
    
    private let maxCharacters = 140
    private var remainingCharacters: Int {
        maxCharacters - messageText.count
    }
    
    private var isOverLimit: Bool {
        remainingCharacters < 0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                // Unified input container
                VStack {  // Changed from HStack to VStack for text wrapping
                    if !isAuthenticated {
                        Button(action: onTagTap) {
                            Text("Login to send a message")
                                .foregroundColor(.secondary)
                        }
                    } else if let zineName = selectedZineName {
                        HStack {
                            // Selected zine pill
                            Text("#\(zineName)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                                .onTapGesture(perform: onTagTap)
                            
                            Spacer()
                        }
                    } else {
                        // Tag selector button
                        Button(action: onTagTap) {
                            Text("Tag a zine for your message...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isAuthenticated && selectedZineName != nil {
                        TextField("Type your message...", text: $messageText, axis: .vertical) // Added axis: .vertical for text wrapping
                            .textFieldStyle(.plain)
                            .lineLimit(5) // Allows up to 5 lines before scrolling
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(selectedZineName != nil ? 0.2 : 0))
                )
                
                // Send button
                if isAuthenticated && !messageText.isEmpty && selectedZineName != nil {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(isOverLimit ? .gray : .blue)
                    }
                    .disabled(isOverLimit)
                }
            }
            
            // Character count
            if isAuthenticated && selectedZineName != nil {
                HStack {
                    Spacer()
                    Text("\(remainingCharacters)")
                        .font(.caption)
                        .foregroundColor(
                            remainingCharacters <= 20
                            ? (remainingCharacters < 0 ? .red : .orange)
                            : .secondary
                        )
                        .padding(.horizontal)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct SearchSection: View {
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search by #tag...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(Color(.systemGray6).opacity(0.5))
    }
}

struct MessageRow: View {
    let message: FanMailMessage
    let userVote: Int
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    private var zineColor: Color {
        Color.zineColors[message.zineId] ?? .accentColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.text)
                .font(.body)
            
            HStack {
                Text("#\(message.zineName)")
                    .font(.headline)
                    .foregroundColor(zineColor)
                
                Spacer()
                
                Button(action: {
                    if authService.isAuthenticated {
                        onUpvote()
                    } else {
                        showingAuthSheet = true
                    }
                }) {
                    Image(systemName: userVote == 1 ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .foregroundColor(userVote == 1 ? zineColor : .secondary)
                }
                
                Text("\(message.votes)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if authService.isAuthenticated {
                        onDownvote()
                    } else {
                        showingAuthSheet = true
                    }
                }) {
                    Image(systemName: userVote == -1 ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundColor(userVote == -1 ? zineColor : .secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(zineColor.opacity(0.15), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}

struct ZineTagPickerView: View {
    let zines: [Zine]
    @Binding var selectedZineId: String?
    @Binding var selectedZineName: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
           NavigationView {
               List(zines) { zine in
                   Button(action: {
                       selectedZineId = zine.id
                       selectedZineName = zine.name
                       dismiss()
                   }) {
                       Text(zine.name)
                           .foregroundColor(.primary)
                   }
               }
               .navigationTitle("Tag Your Message")  // Updated title
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .topBarTrailing) {
                       Button("Cancel") {
                           dismiss()
                    }
                }
            }
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
