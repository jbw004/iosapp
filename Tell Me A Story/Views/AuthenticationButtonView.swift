import SwiftUI

struct AuthenticationButtonView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        if authService.isAuthenticated {
            Menu {
                Button(action: { showingDeleteConfirmation = true }) {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                }
                
                Button(role: .destructive, action: authService.signOut) {
                    Label("Logout", systemImage: "arrow.right.square")
                }
            } label: {
                Text("Account")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showingDeleteConfirmation,
                actions: {
                    Button("Delete Account", role: .destructive) {
                        Task {
                            try? await authService.deleteAccount()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("This action cannot be undone. All your data will be permanently deleted.")
                }
            )
        } else {
            Button {
                showingAuthSheet = true
            } label: {
                Text("Login")
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
}
