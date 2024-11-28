import SwiftUI
import AVFoundation

struct ConfettiView: View {
    @State private var isAnimating = false
    let onComplete: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50) { index in
                    ConfettiPiece(color: confettiColors.randomElement()!)
                        .frame(width: 8, height: 8)
                        .position(
                            x: isAnimating ? .random(in: 0...geometry.size.width) : geometry.size.width/2,
                            y: isAnimating ? geometry.size.height + 100 : -100
                        )
                        .animation(
                            Animation.interpolatingSpring(stiffness: 50, damping: 5)
                            .speed(0.5)
                            .delay(Double(index) * 0.02),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                playHapticSuccess()
                isAnimating = true
                
                // Dismiss after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete()
                }
            }
        }
    }
    
    private let confettiColors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    private func playHapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ConfettiPiece: View {
    let color: Color
    @State private var rotation = Double.random(in: 0...360)
    
    var body: some View {
        Rectangle()
            .fill(color)
            .rotationEffect(.degrees(rotation))
            .animation(
                Animation.linear(duration: 2)
                .repeatForever(autoreverses: false),
                value: rotation
            )
            .onAppear {
                rotation = Double.random(in: 0...360) + 720
            }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Submitting...")
                    .font(.headline)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}
