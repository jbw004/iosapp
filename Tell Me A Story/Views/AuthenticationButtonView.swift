import SwiftUI

struct AuthenticationButtonView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                Button {
                    authService.signOut()
                } label: {
                    Label("Sign Out", systemImage: "person.crop.circle.badge.minus")
                }
            } else {
                Button {
                    showingAuthSheet = true
                } label: {
                    Label("Sign In", systemImage: "person.crop.circle.badge.plus")
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
