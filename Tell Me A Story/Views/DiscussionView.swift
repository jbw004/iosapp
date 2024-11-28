import SwiftUI

struct DiscussionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Discord Community")
                .font(.title)
            
            if authService.isAuthenticated {
                Button("Join Discord") {
                    // Discord invite link handling will go here
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 12) {
                    Text("Sign in to join our Discord community")
                        .foregroundColor(.secondary)
                    
                    Button("Sign In") {
                        showingAuthSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}
