import SwiftUI

struct CustomNavigationView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    @Environment(\.presentationMode) var presentationMode
    let isDetailView: Bool
    let unreadCount: Int
    let simplifiedHeader: Bool
    let headerTitle: String?
    let showLogo: Bool  // Add this new property
    
    var onDismiss: (() -> Void)?  // Add this
    
    init(selectedTab: Binding<Int>, isDetailView: Bool = false, unreadCount: Int = 0,
             simplifiedHeader: Bool = false, headerTitle: String? = nil, showLogo: Bool = true,
             onDismiss: (() -> Void)? = nil) {  // Add this
            self._selectedTab = selectedTab
            self.isDetailView = isDetailView
            self.unreadCount = unreadCount
            self.simplifiedHeader = simplifiedHeader
            self.headerTitle = headerTitle
            self.showLogo = showLogo
            self.onDismiss = onDismiss  // Add this
        }
    
    var body: some View {
            VStack(spacing: 0) {
                // Top row with logo/back button and sign in button
                ZStack {
                    // Left-aligned back button (if detail view)
                    HStack {
                        if isDetailView {
                                Button(action: {
                                    if let customDismiss = onDismiss {
                                        customDismiss()
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
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
                    
                    // Center content
                    if simplifiedHeader || !showLogo {
                        // Centered title
                        Text(headerTitle ?? "")
                            .font(.system(size: 17, weight: .semibold))
                    } else if showLogo {
                        // Centered logo
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                    }
                    
                    // Right-aligned auth button
                    HStack {
                        Spacer()
                        AuthenticationButtonView()
                    }
                }
                .frame(height: 44)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Tab buttons only shown in non-simplified, non-detail view
            if !isDetailView && !simplifiedHeader {
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
        .background {
            Color(.systemBackground)
                .opacity(0.85)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
    }
}
