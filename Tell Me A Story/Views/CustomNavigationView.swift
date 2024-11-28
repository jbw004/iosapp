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
            // Top row with logo/back button and sign in button
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
                    Spacer()
                } else {
                    Spacer()
                    Image("app-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    Spacer()
                }
                
                Button {
                    showingAuthSheet = true
                } label: {
                    Image(systemName: authService.isAuthenticated ? "person.circle.fill" : "person.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tab buttons (only show in main view)
            if !isDetailView {
                HStack(spacing: 24) {
                    ForEach(["Zines", "Discussion"].indices, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(["Zines", "Discussion"][index])
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
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}
