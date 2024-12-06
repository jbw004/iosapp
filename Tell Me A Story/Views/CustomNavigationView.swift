import SwiftUI

struct CustomNavigationView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    @Environment(\.presentationMode) var presentationMode
    let isDetailView: Bool
    let unreadCount: Int
    
    init(selectedTab: Binding<Int>, isDetailView: Bool = false, unreadCount: Int = 0) {
        self._selectedTab = selectedTab
        self.isDetailView = isDetailView
        self.unreadCount = unreadCount
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Safe area spacer
            Color(.systemBackground)
                .opacity(0.60)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
                .frame(height: 0)
            
            // Top row with logo/back button and sign in button
            ZStack {
                // Left-aligned back button (if detail view)
                HStack {
                    if isDetailView {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Zines")
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                }
                
                // Centered logo
                Image("app-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                
                // Right-aligned auth button
                HStack {
                    Spacer()
                    AuthenticationButtonView()
                }
            }
            .frame(height: 44)  // Fixed height for top row
            .padding(.horizontal)
            
            // Tab buttons
            if !isDetailView {
                            HStack(spacing: 24) {
                                ForEach(["Zines", "Following"].indices, id: \.self) { index in
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = index
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            HStack(spacing: 4) {
                                                Text(["Zines", "Following"][index])
                                                    .fontWeight(selectedTab == index ? .semibold : .regular)
                                                    .foregroundColor(selectedTab == index ? .primary : .gray)
                                                
                                                // Show unread count for Following tab
                                                if index == 1 && unreadCount > 0 {
                                                    Text("\(unreadCount)")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.red)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            
                                            Rectangle()
                                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                                .frame(height: 2)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .frame(height: 40)
                            .padding(.horizontal)
                        }
                    }
                    .frame(height: isDetailView ? 44 : 84)
                    .background {
                        Color(.systemBackground)
                            .opacity(0.60)
                            .background(.ultraThinMaterial)
                    }
                }
            }
