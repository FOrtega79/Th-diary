import SwiftUI

struct LogShiftButton: View {
    let action: () -> Void

    @State private var glowOpacity: Double = 0.5
    @State private var glowRadius: CGFloat = 20

    var body: some View {
        Button(action: {
            HapticsManager.shared.mediumTap()
            action()
        }) {
            ZStack {
                // Pulsing background orb
                Circle()
                    .fill(Color.soil.opacity(glowOpacity))
                    .frame(width: 200, height: 200)
                    .blur(radius: glowRadius)

                // Button pill
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))

                    Text("Log a Shift")
                        .font(AppFont.rounded(20, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .background(LinearGradient.logShiftButton)
                .cornerRadius(AppDesign.cornerRadius)
                .shadow(color: Color.pineDark.opacity(0.35), radius: 16, x: 0, y: 8)
            }
        }
        .pressScaleStyle()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowOpacity = 0.25
                glowRadius  = 40
            }
        }
    }
}

#Preview {
    LogShiftButton(action: {})
        .padding()
        .background(Color.moonlit)
}
