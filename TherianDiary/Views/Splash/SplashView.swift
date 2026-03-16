import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var glowRadius: CGFloat = 10

    var body: some View {
        ZStack {
            // Background
            LinearGradient.pinePrimary
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo orb
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.soil.opacity(0.35))
                        .frame(width: 140, height: 140)
                        .blur(radius: glowRadius)

                    // Icon circle
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.pineMedium, Color(hex: "#1A5C40")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.moonlit],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .shadow(color: Color.soil.opacity(0.4), radius: 20, x: 0, y: 8)
                }
                .scaleEffect(scale)

                // App name
                VStack(spacing: 4) {
                    Text("Therian")
                        .font(AppFont.serif(38, weight: .bold))
                        .foregroundColor(.moonlit)
                    Text("Diary")
                        .font(AppFont.serif(38, weight: .light))
                        .foregroundColor(.moonlit.opacity(0.85))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                opacity = 1.0
            }
            // Breathing glow
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.5)) {
                glowRadius = 30
            }
        }
    }
}

#Preview {
    SplashView()
}
