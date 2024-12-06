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

// MARK: - Placeholder Views
struct BookmarksView: View {
    var body: some View {
        VStack {
            Image(systemName: "bookmark")
                .font(.largeTitle)
                .padding()
            Text("Bookmarks Coming Soon")
                .font(.headline)
            Text("Save your favorite zines for later")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct HistoryView: View {
    var body: some View {
        VStack {
            Image(systemName: "clock")
                .font(.largeTitle)
                .padding()
            Text("Read History Coming Soon")
                .font(.headline)
            Text("Track your reading journey")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
