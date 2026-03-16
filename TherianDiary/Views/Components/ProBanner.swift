import SwiftUI

struct ProBanner: View {
    let action: () -> Void

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.soil, Color(hex: "#E07040")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Therian Pro")
                        .font(AppFont.rounded(15, weight: .bold))
                        .foregroundColor(.moonlit)
                    Text("Unlock the full wild experience — free trial")
                        .font(AppFont.rounded(12))
                        .foregroundColor(.moonlit.opacity(0.65))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.moonlit.opacity(0.5))
            }
            .padding(16)
            .background(LinearGradient.pinePrimary)
            .cornerRadius(AppDesign.cornerRadius)
            .overlay(
                // Shimmer effect
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.12), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .clipped()
            )
            .shadow(color: Color.pineDark.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .pressScaleStyle()
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

#Preview {
    ProBanner(action: {})
        .padding()
        .background(Color.moonlit)
}
