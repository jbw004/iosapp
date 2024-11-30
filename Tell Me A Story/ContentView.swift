import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var zineService = ZineService()
    @State private var selectedTab = 0
    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var showingSubmissionSheet = false
    @Binding var deepLinkZineId: String?
    @State private var selectedZine: Zine?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Custom Header
                    if showHeader {
                        CustomNavigationView(selectedTab: $selectedTab, isDetailView: false)
                            .transition(.move(edge: .top))
                    }
                    
                    // Content
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
                            DiscussionView()
                        }
                    }
                }
                
                // Footer with + button
                HStack {
                    Spacer()
                    Button(action: {
                        showingSubmissionSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
                }
                .padding(.trailing)
                .padding(.bottom, 20)
            }
            .navigationDestination(for: Zine.self) { zine in
                ZineDetailView(zine: zine)
            }
        }
        .sheet(isPresented: $showingSubmissionSheet) {
            SubmissionTypeSelectionView()
        }
        .environmentObject(authService)
        .environmentObject(zineService)
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
