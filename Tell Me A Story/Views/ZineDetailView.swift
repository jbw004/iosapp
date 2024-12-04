import SwiftUI
import LinkPresentation

class ZineActivityItemSource: NSObject, UIActivityItemSource {
    let url: String
    let zine: Zine
    private let analytics = AnalyticsService.shared
    
    init(url: String, zine: Zine) {
        self.url = url
        self.zine = zine
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = URL(string: url)
        metadata.url = URL(string: url)
        metadata.title = "Check out issues of \(zine.name)!"
        
        if let imageURL = URL(string: zine.coverImageUrl) {
            metadata.imageProvider = NSItemProvider(contentsOf: imageURL)
        }
        
        // Track share action
        analytics.trackEvent(.shareAction(zineId: zine.id, zineName: zine.name))
        
        return metadata
    }
}

struct ZineDetailView: View {
    let zine: Zine
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var notificationService: NotificationService
    @State private var isShowingAuthAlert = false
    @State private var isLoading = false
    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showingAuthSheet = false
    private let analytics = AnalyticsService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                CustomNavigationView(selectedTab: .constant(0), isDetailView: true)
                    .transition(.move(edge: .top))
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    VStack(alignment: .center, spacing: 16) {
                        // ... Cover image code ...
                        
                        VStack(spacing: 4) {
                            Text(zine.name)
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("\(zine.issues.count) issues")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 16) {
                                // Follow/Unfollow Button
                                Button(action: {
                                    if !authService.isAuthenticated {
                                        isShowingAuthAlert = true
                                        return
                                    }
                                    
                                    Task {
                                        isLoading = true
                                        do {
                                            if notificationService.isFollowingZine(zine.id) {
                                                try await notificationService.unfollowZine(zine)
                                            } else {
                                                try await notificationService.requestNotificationPermissions()
                                                try await notificationService.followZine(zine)
                                            }
                                        } catch {
                                            notificationService.error = error as? NotificationError
                                        }
                                        isLoading = false
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Image(systemName: notificationService.isFollowingZine(zine.id) ? "bell.fill" : "bell")
                                            Text(notificationService.isFollowingZine(zine.id) ? "Following" : "Follow")
                                        }
                                    }
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .disabled(isLoading)

                                // Share Button
                                Button(action: {
                                    let url = "https://app.tellmeastory.press/zine/\(zine.id)"
                                    let activityItem = ZineActivityItemSource(url: url, zine: zine)
                                    
                                    let activityVC = UIActivityViewController(
                                        activityItems: [activityItem],
                                        applicationActivities: nil
                                    )
                                    
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first,
                                       let rootVC = window.rootViewController {
                                        rootVC.present(activityVC, animated: true)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share")
                                    }
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Add Debug Information Section here
                                                        VStack(spacing: 8) {
                                                            if let authDebug = authService.debugMessage {
                                                                Text("Auth: \(authDebug)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.gray)
                                                            }
                                                            
                                                            if let notifDebug = notificationService.debugMessage {
                                                                Text("Notifications: \(notifDebug)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.gray)
                                                            }
                                                            
                                                            if let error = notificationService.error {
                                                                Text("Error: \(error.localizedDescription)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.red)
                                                            }
                                                        }
                                                        .padding()
                                                        .background(Color.gray.opacity(0.1))
                                                        .cornerRadius(8)
                                                        .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Text(zine.bio)
                            .font(.system(size: 15))
                        
                        if let url = URL(string: zine.instagramUrl) {
                            Link(destination: url) {
                                Text(zine.instagramUrl)
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                            .onTapGesture {
                                analytics.trackEvent(.instagramClick(
                                    zineId: zine.id,
                                    zineName: zine.name,
                                    success: true
                                ))
                                if let url = URL(string: zine.instagramUrl) {
                                    UIApplication.shared.open(url) { success in
                                        if !success {
                                            analytics.trackEvent(.instagramClick(
                                                zineId: zine.id,
                                                zineName: zine.name,
                                                success: false
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Issues List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issues")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal)
                        
                        ForEach(zine.issues) { issue in
                            Button {
                                analytics.trackEvent(.issueClick(
                                    zineId: zine.id,
                                    zineName: zine.name,
                                    issueId: issue.id,
                                    issueTitle: issue.title,
                                    publishedDate: issue.publishedDate,
                                    success: true
                                ))
                                if let url = URL(string: issue.linkUrl) {
                                    UIApplication.shared.open(url) { success in
                                        if !success {
                                            analytics.trackEvent(.issueClick(
                                                zineId: zine.id,
                                                zineName: zine.name,
                                                issueId: issue.id,
                                                issueTitle: issue.title,
                                                publishedDate: issue.publishedDate,
                                                success: false
                                            ))
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    CachedAsyncImage(url: issue.coverImageUrl) { image in
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
                                        Text(issue.title)
                                            .font(.system(size: 15, weight: .semibold))
                                        Text(issue.publishedDate)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                            }
                                                        .buttonStyle(PlainButtonStyle())
                                                        
                                                        Divider()
                                                    }
                                                }
                                                .padding(.top)
                                            }
                                        }
                                        .coordinateSpace(name: "scroll")
                                        .onScrollOffsetChange { offset in
                                            let scrollingDown = offset < lastScrollOffset
                                            if abs(offset - lastScrollOffset) > 30 {
                                                withAnimation {
                                                    showHeader = !scrollingDown
                                                }
                                                lastScrollOffset = offset
                                            }
                                        }
                                    }
                                    .navigationBarHidden(true)
                                    .onAppear {
                                        analytics.trackEvent(.magazineView(
                                            zineId: zine.id,
                                            zineName: zine.name
                                        ))
                                    }
                                    .alert("Sign in Required", isPresented: $isShowingAuthAlert) {
                                        Button("Sign In") {
                                            // Use your existing auth sheet
                                            showingAuthSheet = true
                                        }
                                        Button("Cancel", role: .cancel) { }
                                    } message: {
                                        Text("Please sign in to follow zines and receive notifications")
                                    }
                                    .sheet(isPresented: $showingAuthSheet) {
                                        NavigationView {
                                            AuthenticationView()
                                        }
                                    }
                                }
                            }
