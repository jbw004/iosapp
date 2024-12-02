import SwiftUI
import AuthenticationServices

struct AuthenticationButton: View {
    @EnvironmentObject var authService: AuthenticationService
    let isSignUp: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(
                onRequest: { _ in
                    authService.signInWithApple()
                },
                onCompletion: { _ in }
            )
            .frame(height: 50)
            
            Text("or")
                .foregroundColor(.gray)
            
            NavigationLink(destination: EmailAuthView(isSignUp: isSignUp)) {
                Text("\(isSignUp ? "Sign Up" : "Sign In") with Email")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct EmailAuthView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    
    let isSignUp: Bool
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(isSignUp ? .newPassword : .password)
            
            Button(action: {
                if isSignUp {
                    authService.signUp(email: email, password: password)
                } else {
                    authService.signIn(email: email, password: password)
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if let error = authService.authError {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
        .onChange(of: authService.isAuthenticated) { wasAuthenticated, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    @State private var showingSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            if showingSignUp {
                AuthenticationButton(isSignUp: true)
            } else {
                AuthenticationButton(isSignUp: false)
            }
            
            Button(showingSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                showingSignUp.toggle()
            }
            .foregroundColor(.blue)
        }
        .navigationTitle(showingSignUp ? "Sign Up" : "Sign In")
        .onChange(of: authService.isAuthenticated) { wasAuthenticated, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}
