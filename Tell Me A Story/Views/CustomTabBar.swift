import SwiftUI

// MARK: - Tab Bar Item Model
enum TabItem: Int, Hashable {
    case home = 0
    case bookmarks
    case submit
    case history
    case discussion
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .bookmarks: return "Bookmarks"
        case .submit: return "Submit"
        case .history: return "History"
        case .discussion: return "Discussion"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .bookmarks: return "bookmark"
        case .submit: return "plus"
        case .history: return "clock"
        case .discussion: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Custom Tab Bar View
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showingSubmissionSheet: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([TabItem.home, .bookmarks, .submit, .history, .discussion], id: \.self) { tab in
                Button {
                    if tab == .submit {
                        showingSubmissionSheet = true
                    } else {
                        selectedTab = tab
                    }
                } label: {
                    if tab == .submit {
                        // Enhanced submit button
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .offset(y: -16) // Lift button above tab bar
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Regular tab buttons
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .symbolVariant(selectedTab == tab ? .fill : .none)
                                .font(.body)
                                .frame(width: 24, height: 24)
                            
                            Text(tab.title)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .foregroundStyle(selectedTab == tab ? Color.blue : Color.gray)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background {
            Color(.systemBackground)
                .opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct BookmarksView: View {
    @EnvironmentObject var bookmarkService: BookmarkService
    @EnvironmentObject var authService: AuthenticationService
    @State private var groupedBookmarks: [String: [BookmarkedIssue]] = [:]
    @State private var isLoading = false
    @State private var showingAuthSheet = false
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("Sign in to see your bookmarks")
                        .font(.headline)
                    
                    Button("Sign In") {
                        showingAuthSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            } else if isLoading {
                ProgressView()
            } else if groupedBookmarks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No bookmarks yet")
                        .font(.headline)
                    
                    Text("Bookmark issues to read them later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(Array(groupedBookmarks.keys.sorted()), id: \.self) { zineName in
                        Section(header: Text(zineName)) {
                            ForEach(groupedBookmarks[zineName] ?? []) { bookmark in
                                Button {
                                    if let url = URL(string: bookmark.linkUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        CachedAsyncImage(url: bookmark.coverImageUrl) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .foregroundColor(.gray.opacity(0.2))
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(bookmark.issueTitle)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text(bookmark.publishedDate)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            Task {
                                                // Create a temporary Zine.Issue and Zine for the toggleBookmark call
                                                let issue = Zine.Issue(
                                                    id: bookmark.issueId,
                                                    title: bookmark.issueTitle,
                                                    coverImageUrl: bookmark.coverImageUrl,
                                                    linkUrl: bookmark.linkUrl,
                                                    publishedDate: bookmark.publishedDate
                                                )
                                                let zine = Zine(
                                                    id: bookmark.zineId,
                                                    name: bookmark.zineName,
                                                    bio: "",
                                                    coverImageUrl: "",
                                                    instagramUrl: "",
                                                    issues: []
                                                )
                                                try await bookmarkService.toggleBookmark(for: issue, in: zine)
                                                await loadBookmarks()
                                            }
                                        } label: {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .task {
            await loadBookmarks()
        }
    }
    
    private func loadBookmarks() async {
        isLoading = true
        do {
            groupedBookmarks = try await bookmarkService.fetchGroupedBookmarks()
        } catch {
            // Handle error if needed
            print("Error loading bookmarks: \(error)")
        }
        isLoading = false
    }
}

struct HistoryView: View {
    @EnvironmentObject var readService: ReadService
    @EnvironmentObject var authService: AuthenticationService
    @State private var groupedReadIssues: [String: [ReadIssue]] = [:]
    @State private var isLoading = false
    @State private var showingAuthSheet = false
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("Sign in to see your reading history")
                        .font(.headline)
                    
                    Button("Sign In") {
                        showingAuthSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            } else if isLoading {
                ProgressView()
            } else if groupedReadIssues.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No read issues yet")
                        .font(.headline)
                    
                    Text("Mark issues as read to track your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(Array(groupedReadIssues.keys.sorted()), id: \.self) { zineName in
                        Section(header: Text(zineName)) {
                            ForEach(groupedReadIssues[zineName] ?? []) { readIssue in
                                Button {
                                    if let url = URL(string: readIssue.linkUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        CachedAsyncImage(url: readIssue.coverImageUrl) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .foregroundColor(.gray.opacity(0.2))
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(readIssue.issueTitle)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text(readIssue.publishedDate)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            Task {
                                                // Create temporary Issue and Zine for the toggleReadStatus call
                                                let issue = Zine.Issue(
                                                    id: readIssue.issueId,
                                                    title: readIssue.issueTitle,
                                                    coverImageUrl: readIssue.coverImageUrl,
                                                    linkUrl: readIssue.linkUrl,
                                                    publishedDate: readIssue.publishedDate
                                                )
                                                let zine = Zine(
                                                    id: readIssue.zineId,
                                                    name: readIssue.zineName,
                                                    bio: "",
                                                    coverImageUrl: "",
                                                    instagramUrl: "",
                                                    issues: []
                                                )
                                                try await readService.toggleReadStatus(for: issue, in: zine)
                                                await loadReadIssues()
                                            }
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .task {
            await loadReadIssues()
        }
    }
    
    private func loadReadIssues() async {
        isLoading = true
        do {
            groupedReadIssues = try await readService.fetchGroupedReadIssues()
        } catch {
            // Handle error if needed
            print("Error loading read issues: \(error)")
        }
        isLoading = false
    }
}
