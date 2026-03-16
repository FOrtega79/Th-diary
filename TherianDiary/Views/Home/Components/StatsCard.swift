import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
            }

            Text(value)
                .font(AppFont.serif(34, weight: .bold))
                .foregroundColor(.pineDark)
                .contentTransition(.numericText())

            Text(title)
                .font(AppFont.rounded(13, weight: .medium))
                .foregroundColor(.pineDark.opacity(0.55))
        }
        .glassmorphic(padding: 18)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
    }
}

#Preview {
    HStack {
        StatsCard(title: "Day Streak", value: "7", icon: "flame.fill", accent: .soil)
        StatsCard(title: "Total Shifts", value: "42", icon: "pawprint.fill", accent: .pineMedium)
    }
    .padding()
    .background(Color.moonlit)
}
