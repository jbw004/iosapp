import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var zineService = ZineService()
    @State private var selectedTab = 0 // Existing tab state for Zines/Following
    @State private var selectedFooterTab: TabItem = .home
    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showingSubmissionSheet = false
    @Binding var deepLinkZineId: String?
    @State private var selectedZine: Zine?
    @State private var navigationPath = NavigationPath()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isShowingOnboarding = false
    
    var body: some View {
        ZStack {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    if showHeader {
                        Group {
                            switch selectedFooterTab {
                            case .home:
                                CustomNavigationView(
                                    selectedTab: $selectedTab,
                                    isDetailView: false,
                                    unreadCount: NotificationService.shared.unreadCount
                                )
                            case .bookmarks:
                                CustomNavigationView(
                                    selectedTab: $selectedTab,
                                    simplifiedHeader: true,
                                    headerTitle: "Bookmarks"
                                )
                            case .history:
                                PassportView(selectedFooterTab: $selectedFooterTab
                                )
                            case .discussion:
                                EmptyView()
                            case .submit:
                                EmptyView()
                            }
                        }
                        .transition(.move(edge: .top))
                    }
                    
                    // Main Content Area
                    Group {
                        switch selectedFooterTab {
                        case .home:
                            ZStack {
                                if selectedTab == 0 {
                                    ScrollView {
                                        VStack {
                                            ZineListView()
                                        }
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
                                    .coordinateSpace(name: "scroll")
                                } else {
                                    FollowingView()
                                }
                            }
                        case .bookmarks:
                            BookmarksView()
                        case .submit:
                            EmptyView()
                        case .history:
                            EmptyView()
                        case .discussion:
                            FanMailView(selectedFooterTab: $selectedFooterTab)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                if selectedFooterTab != .history && selectedFooterTab != .discussion {
                    CustomTabBar(selectedTab: $selectedFooterTab,
                                showingSubmissionSheet: $showingSubmissionSheet)
                }
            }
            .navigationDestination(for: Zine.self) { zine in
                ZineDetailView(zine: zine)
            }
        }
            
            // In ContentView.swift, modify the fullScreenCover binding to:
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenOnboarding || isShowingOnboarding },  // Changed the logic here
                set: { newValue in
                    hasSeenOnboarding = !newValue
                    isShowingOnboarding = newValue
                }
            )) {
                OnboardingView(
                    isShowingOnboarding: $isShowingOnboarding,
                    selectedFooterTab: $selectedFooterTab
                )
                .environmentObject(authService)
            }
                }
        
        .sheet(isPresented: $showingSubmissionSheet) {
            SubmissionTypeSelectionView()
        }
        .environmentObject(authService)
        .environmentObject(zineService)
        .environmentObject(NotificationService.shared)
        .environmentObject(BookmarkService.shared)
        .environmentObject(ReadService.shared)
        .onChange(of: deepLinkZineId) { oldValue, newValue in
            if let zineId = newValue {
                Task {
                    await zineService.fetchZines()
                    if let zine = zineService.zines.first(where: { $0.id == zineId }) {
                        await MainActor.run {
                            navigationPath.append(zine)
                            selectedZine = zine
                            deepLinkZineId = nil
                        }
                    }
                }
            }
        }
    }
}
