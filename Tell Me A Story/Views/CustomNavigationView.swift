import SwiftUI

struct CustomNavigationView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    @Environment(\.presentationMode) var presentationMode
    let isDetailView: Bool
    
    init(selectedTab: Binding<Int>, isDetailView: Bool = false) {
        self._selectedTab = selectedTab
        self.isDetailView = isDetailView
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
                                Text(["Zines", "Following"][index])
                                    .fontWeight(selectedTab == index ? .semibold : .regular)
                                    .foregroundColor(selectedTab == index ? .primary : .gray)
                                
                                Rectangle()
                                    .fill(selectedTab == index ? Color.blue : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(height: 40)  // Fixed height for tab row
                .padding(.horizontal)
            }
        }
        .frame(height: isDetailView ? 44 : 84)  // Fixed total height
        .background {
            Color(.systemBackground)
                .opacity(0.60)
                .background(.ultraThinMaterial)
        }
    }
}
