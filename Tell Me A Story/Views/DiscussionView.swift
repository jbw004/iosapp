import SwiftUI

struct DiscussionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    private let discordInviteUrl = "https://discord.gg/DX2WmK5Ny2"
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Discord Community")
                .font(.title)
            
            if authService.isAuthenticated {
                Button("Join Discord") {
                    if let url = URL(string: discordInviteUrl) {
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
