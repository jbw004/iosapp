import SwiftUI

struct DiscussionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Discord Community")
                .font(.title)
                .padding()
            
            if authService.isAuthenticated {
                Button("Join Discord") {
                    // We'll replace this URL with your actual Discord invite
                    if let url = URL(string: "YOUR_DISCORD_INVITE_URL") {
                        UIApplication.shared.open(url)
                    }
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
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    DiscussionView()
        .environmentObject(AuthenticationService())
}
