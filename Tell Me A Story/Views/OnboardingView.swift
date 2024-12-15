import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let backgroundImage: String
}

struct OnboardingView: View {
    @State private var currentStep = 0
    @Binding var isShowingOnboarding: Bool
    @Binding var selectedFooterTab: TabItem
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    // Use just one definition of steps
    let steps = [
        OnboardingStep(backgroundImage: "onboarding-discover"),
        OnboardingStep(backgroundImage: "onboarding-collection"),
        OnboardingStep(backgroundImage: "onboarding-notifications")
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background TabView for full-screen images
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Image(steps[index].backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Overlay content
            VStack {
                Spacer()
                
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? Color.black : Color.black.opacity(0.3))
                            .frame(width: currentStep == index ? 10 : 8, height: 8)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.bottom, 40)
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showingAuthSheet = true
                    }) {
                        HStack {
                            Text("Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("Guest button tapped")
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        selectedFooterTab = .home
                        isShowingOnboarding = false
                    }) {
                        Text("Continue as Guest")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            NavigationView {
                AuthenticationView()
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                selectedFooterTab = .home
                isShowingOnboarding = false
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentStep = (currentStep + 1) % steps.count
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}
