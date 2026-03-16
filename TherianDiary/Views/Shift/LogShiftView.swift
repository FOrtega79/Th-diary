import SwiftUI

struct LogShiftView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = LogShiftViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Shift type
                        shiftTypeSection

                        // Intensity
                        intensitySection

                        // Tags
                        tagsSection

                        // Notes
                        notesSection

                        // Save button
                        saveButton

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Log a Shift")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticsManager.shared.lightTap()
                        dismiss()
                    }
                    .foregroundColor(.pineMedium)
                }
            }
        }
        .onChange(of: vm.didSave) { saved in
            if saved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }
        .overlay {
            if vm.showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Shift Type

    private var shiftTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Shift Type")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ShiftType.allCases) { type in
                        Button {
                            HapticsManager.shared.lightTap()
                            withAnimation(.spring()) { vm.selectedType = type }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(type.rawValue)
                                    .font(AppFont.rounded(14, weight: .semibold))
                            }
                            .foregroundColor(vm.selectedType == type ? .moonlit : .pineDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                vm.selectedType == type
                                    ? AnyView(LinearGradient.pinePrimary)
                                    : AnyView(Color.moonlitCard)
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.pineDark.opacity(vm.selectedType == type ? 0 : 0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Description
            Text(vm.selectedType.description)
                .font(AppFont.rounded(13))
                .foregroundColor(.pineDark.opacity(0.5))
                .padding(.leading, 2)
        }
    }

    // MARK: - Intensity

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Intensity")
                Spacer()
                Text("\(Int(vm.intensity)) / 10")
                    .font(AppFont.rounded(15, weight: .bold))
                    .foregroundColor(.pineMedium)
            }

            VStack(spacing: 6) {
                Slider(value: $vm.intensity, in: 1...10, step: 1)
                    .tint(Color.soil)
                    .onChange(of: vm.intensity) { _ in
                        HapticsManager.shared.lightTap()
                    }

                HStack {
                    Text("Mild")
                    Spacer()
                    Text("Moderate")
                    Spacer()
                    Text("Intense")
                }
                .font(AppFont.rounded(11))
                .foregroundColor(.pineDark.opacity(0.35))
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Triggers / Tags")

            FlowLayout(spacing: 8) {
                ForEach(Shift.commonTags, id: \.self) { tag in
                    Button {
                        vm.toggleTag(tag)
                    } label: {
                        Text(tag)
                            .font(AppFont.rounded(13, weight: .medium))
                            .foregroundColor(vm.selectedTags.contains(tag) ? .moonlit : .pineDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                vm.selectedTags.contains(tag)
                                    ? AnyView(Color.pineMedium)
                                    : AnyView(Color.moonlitCard)
                            )
                            .cornerRadius(16)
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Journal Entry")

            ZStack(alignment: .topLeading) {
                if vm.notes.isEmpty {
                    Text("Describe your experience...")
                        .font(AppFont.rounded(16))
                        .foregroundColor(.pineDark.opacity(0.3))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $vm.notes)
                    .font(AppFont.rounded(16))
                    .foregroundColor(.pineDark)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
            }
            .padding(14)
            .background(Color.moonlitCard)
            .cornerRadius(AppDesign.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .strokeBorder(Color.pineDark.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            guard let uid = authVM.currentTherianUser?.uid else { return }
            Task { await vm.saveShift(userId: uid) }
        } label: {
            HStack(spacing: 10) {
                if vm.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: vm.didSave ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                    Text(vm.didSave ? "Saved!" : "Save Entry")
                }
            }
            .font(AppFont.rounded(17, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(vm.didSave ? AnyView(Color.pineMedium) : AnyView(LinearGradient.logShiftButton))
            .cornerRadius(AppDesign.cornerRadius)
            .shadow(color: Color.pineDark.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .pressScaleStyle()
        .disabled(vm.isLoading || vm.didSave)
        .animation(.spring(), value: vm.didSave)
    }

    // MARK: - Helper

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.rounded(13, weight: .semibold))
            .foregroundColor(.pineDark.opacity(0.45))
            .textCase(.uppercase)
            .kerning(0.8)
    }
}

// MARK: - FlowLayout (wrapping tag chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(rows.count - 1) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for (index, subview) in row.subviews.enumerated() {
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += row.sizes[index].width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var subviews: [LayoutSubview] = []
        var sizes: [CGSize] = []
        var height: CGFloat { sizes.map(\.height).max() ?? 0 }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].subviews.isEmpty {
                rows.append(Row())
                x = 0
            }
            rows[rows.count - 1].subviews.append(subview)
            rows[rows.count - 1].sizes.append(size)
            x += size.width + spacing
        }
        return rows
    }
}

// MARK: - Confetti (particle burst)

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<40).map { _ in ConfettiParticle() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .position(p.position)
                    .opacity(p.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                for i in particles.indices {
                    particles[i].animate()
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color = [Color.soil, Color.pineMedium, Color.moonlit, Color.yellow, Color.orange].randomElement()!
    let size: CGFloat = CGFloat.random(in: 6...14)
    var position: CGPoint = CGPoint(
        x: UIScreen.main.bounds.midX + CGFloat.random(in: -50...50),
        y: UIScreen.main.bounds.midY
    )
    var opacity: Double = 1.0

    mutating func animate() {
        position = CGPoint(
            x: CGFloat.random(in: 30...UIScreen.main.bounds.width - 30),
            y: CGFloat.random(in: -100...UIScreen.main.bounds.height * 0.5)
        )
        opacity = 0
    }
}

#Preview {
    LogShiftView()
        .environmentObject(AuthViewModel())
}
