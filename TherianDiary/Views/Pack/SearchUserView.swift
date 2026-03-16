import SwiftUI
import SDWebImageSwiftUI

struct SearchUserView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var packVM: PackViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.pineDark.opacity(0.4))

                        TextField("Search by username...", text: $packVM.searchQuery)
                            .font(AppFont.rounded(16))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                Task { await packVM.searchUser() }
                            }

                        if !packVM.searchQuery.isEmpty {
                            Button {
                                packVM.searchQuery = ""
                                packVM.searchResults = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.pineDark.opacity(0.3))
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.moonlitCard)
                    .cornerRadius(AppDesign.smallCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                            .strokeBorder(Color.pineDark.opacity(0.1), lineWidth: 1)
                    )

                    // Search button
                    Button {
                        HapticsManager.shared.lightTap()
                        Task { await packVM.searchUser() }
                    } label: {
                        Text("Search")
                            .font(AppFont.rounded(16, weight: .semibold))
                            .foregroundColor(.moonlit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LinearGradient.pinePrimary)
                            .cornerRadius(AppDesign.cornerRadius)
                    }
                    .pressScaleStyle()
                    .disabled(packVM.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(packVM.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                    // Results
                    if packVM.isSearching {
                        Spacer()
                        ProgressView().tint(.pineMedium)
                        Spacer()
                    } else if let result = packVM.searchResults {
                        searchResultCard(result)
                    } else if !packVM.searchQuery.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(.pineDark.opacity(0.2))
                            Text("No therian found with that username.")
                                .font(AppFont.rounded(15))
                                .foregroundColor(.pineDark.opacity(0.4))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.top, 12)
            }
            .navigationTitle("Find a Packmate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.pineMedium)
                }
            }
        }
        .onDisappear {
            packVM.searchQuery = ""
            packVM.searchResults = nil
        }
    }

    // MARK: - Result Card

    @ViewBuilder
    private func searchResultCard(_ user: TherianUser) -> some View {
        let currentUID = authVM.currentTherianUser?.uid ?? ""
        let alreadyInPack = authVM.currentTherianUser?.packMembers.contains(user.uid) ?? false
        let isSelf = user.uid == currentUID

        VStack(spacing: 0) {
            HStack(spacing: 14) {
                AsyncPackAvatar(urlString: user.profileImageUrl, username: user.username)

                VStack(alignment: .leading, spacing: 4) {
                    Text("@\(user.username)")
                        .font(AppFont.rounded(16, weight: .bold))
                        .foregroundColor(.pineDark)

                    HStack(spacing: 6) {
                        if let theriotype = Theriotype(rawValue: user.primaryTheriotype) {
                            Text(theriotype.emoji)
                        }
                        Text(user.primaryTheriotype)
                            .font(AppFont.rounded(13))
                            .foregroundColor(.pineDark.opacity(0.5))
                    }
                }

                Spacer()

                if user.isPremium {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.soil)
                }
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            // Action button
            Button {
                guard !alreadyInPack, !isSelf else { return }
                HapticsManager.shared.mediumTap()
                Task {
                    await packVM.sendHowl(from: currentUID, to: user)
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: alreadyInPack ? "checkmark.circle.fill" : "waveform")
                    Text(isSelf ? "That's you!" : alreadyInPack ? "Already in Pack" : "Send Howl 🐾")
                }
                .font(AppFont.rounded(15, weight: .semibold))
                .foregroundColor(alreadyInPack || isSelf ? .pineDark.opacity(0.4) : .moonlit)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(alreadyInPack || isSelf ? Color.pineDark.opacity(0.06) : Color.pineMedium)
                .cornerRadius(0)
                .cornerRadius(AppDesign.cornerRadius, corners: [.bottomLeft, .bottomRight])
            }
            .disabled(alreadyInPack || isSelf)
        }
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .shadow(color: Color.pineDark.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Rounded Corners Utility

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
