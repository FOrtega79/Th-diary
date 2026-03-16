import SwiftUI

struct LatestEntryCard: View {
    let shift: Shift

    private var dateString: String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: shift.date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: shift.type.icon)
                        .foregroundColor(.soil)
                    Text(shift.type.rawValue)
                        .font(AppFont.rounded(15, weight: .semibold))
                        .foregroundColor(.pineDark)
                }
                Spacer()
                Text(dateString)
                    .font(AppFont.rounded(13))
                    .foregroundColor(.pineDark.opacity(0.45))
            }

            // Intensity bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Intensity")
                        .font(AppFont.rounded(12, weight: .medium))
                        .foregroundColor(.pineDark.opacity(0.5))
                    Spacer()
                    Text("\(shift.intensity)/10")
                        .font(AppFont.rounded(12, weight: .semibold))
                        .foregroundColor(.pineMedium)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pineDark.opacity(0.08))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.soilAccent)
                            .frame(width: geo.size.width * CGFloat(shift.intensity) / 10)
                    }
                }
                .frame(height: 6)
            }

            // Notes preview
            if !shift.notes.isEmpty {
                Text(shift.notes)
                    .font(AppFont.rounded(14))
                    .foregroundColor(.pineDark.opacity(0.7))
                    .lineLimit(2)
            }

            // Tags
            if !shift.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(shift.tags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(AppFont.rounded(12, weight: .medium))
                                .foregroundColor(.pineMedium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.pineMedium.opacity(0.12))
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .glassmorphic()
    }
}
