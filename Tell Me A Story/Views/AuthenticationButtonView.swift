import SwiftUI

struct AuthenticationButtonView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    var body: some View {
        Button {
            if authService.isAuthenticated {
                authService.signOut()
            } else {
                showingAuthSheet = true
            }
        } label: {
            Text(authService.isAuthenticated ? "Logout" : "Login")
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
    }
}
