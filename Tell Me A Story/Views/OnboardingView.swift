import SwiftUI

// OnboardingStep.swift
struct OnboardingStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// OnboardingView.swift
struct OnboardingView: View {
    @State private var currentStep = 0
    @Binding var isShowingOnboarding: Bool
    @Binding var selectedFooterTab: TabItem
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingAuthSheet = false
    
    let backgroundColor = Color(red: 250/255, green: 249/255, blue: 246/255)
    
    let steps = [
        OnboardingStep(
            icon: "book.fill",
            title: "Discover DIY Magazines",
            description: "Find unique zines from indie creators"
        ),
        OnboardingStep(
            icon: "bookmark.fill",
            title: "Track Your Reading",
            description: "Build your personal zine collection"
        ),
        OnboardingStep(
            icon: "gift.fill",
            title: "Share Your Wrapped",
            description: "Show off your reading style"
        )
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // App Logo
            Image("app-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .padding(.top, 60)
                .padding(.bottom, 20)
            
            // Brand Name
            Text("Tell Me A Story")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)  // Changed to black
            
            // Animated steps
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: steps[index].icon)
                            .font(.system(size: 44))
                            .foregroundColor(.blue)
                        
                        Text(steps[index].title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)  // Changed to black
                        
                        Text(steps[index].description)
                            .font(.body)
                            .foregroundColor(.black.opacity(0.7))  // Changed to black with opacity
                            .multilineTextAlignment(.center)
                    }
                    .tag(index)
                    .padding(.horizontal, 32)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 250)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Progress indicators
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(currentStep == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: currentStep == index ? 10 : 8, height: 8)
                        .animation(.spring(), value: currentStep)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
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
                    // Set hasSeenOnboarding to true using UserDefaults directly
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
        .background(backgroundColor)
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
