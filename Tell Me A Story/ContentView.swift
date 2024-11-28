import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var selectedTab = 0
    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
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
                        // Add zine/issue action
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
        }
        .environmentObject(authService)
    }
}
