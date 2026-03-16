import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var revenueCat: RevenueCatService
    @ObservedObject var profileVM: ProfileViewModel

    @State private var showPaywall = false
    @State private var showAdPrompt = false
    @State private var showSignOutAlert = false
    @State private var photoItem: PhotosPickerItem?

    private var user: TherianUser? { authVM.currentTherianUser }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        avatarSection
                        infoSection
                        packSection
                        settingsSection
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        guard let u = user else { return }
                        if revenueCat.isPremium {
                            profileVM.beginEditing(user: u)
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Text("Edit")
                            .font(AppFont.rounded(15, weight: .semibold))
                            .foregroundColor(.pineMedium)
                    }
                }
            }
            .sheet(isPresented: $profileVM.isEditing) {
                editProfileSheet
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog("Edit Bio", isPresented: $showAdPrompt) {
                Button("Watch Ad to Edit Today") {
                    showRewardedAd(trigger: .bioEdit)
                }
                Button("Upgrade to Pro") { showPaywall = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(AdTrigger.bioEdit.message)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { authVM.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                if let urlString = user?.profileImageUrl,
                   let url = URL(string: urlString), !urlString.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(LinearGradient.pinePrimary, lineWidth: 3))
                } else {
                    Circle()
                        .fill(LinearGradient.pinePrimary)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(user?.username.prefix(1).uppercased() ?? "T"))
                                .font(AppFont.serif(40, weight: .bold))
                                .foregroundColor(.moonlit)
                        )
                }

                // Premium badge
                if revenueCat.isPremium {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.soil)
                        .background(Color.white.clipShape(Circle()).padding(2))
                }
            }

            Text("@\(user?.username ?? "")")
                .font(AppFont.rounded(20, weight: .bold))
                .foregroundColor(.pineDark)

            if let theriotype = user?.primaryTheriotype,
               let t = Theriotype(rawValue: theriotype) {
                Text("\(t.emoji) \(t.rawValue)")
                    .font(AppFont.rounded(14))
                    .foregroundColor(.pineDark.opacity(0.55))
            }

            if revenueCat.isPremium {
                Label("Therian Pro", systemImage: "star.fill")
                    .font(AppFont.rounded(12, weight: .semibold))
                    .foregroundColor(.soil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.soil.opacity(0.12))
                    .cornerRadius(20)
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let bio = user?.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("About")
                        .font(AppFont.rounded(13, weight: .semibold))
                        .foregroundColor(.pineDark.opacity(0.45))
                        .textCase(.uppercase)
                        .kerning(0.8)

                    Text(bio)
                        .font(AppFont.rounded(15))
                        .foregroundColor(.pineDark.opacity(0.75))
                }
                .glassmorphic()
            }

            if let secondary = user?.secondaryTheriotype, revenueCat.isPremium,
               let t = Theriotype(rawValue: secondary) {
                HStack(spacing: 10) {
                    Text("Secondary Theriotype")
                        .font(AppFont.rounded(14))
                        .foregroundColor(.pineDark.opacity(0.5))
                    Spacer()
                    Text("\(t.emoji) \(t.rawValue)")
                        .font(AppFont.rounded(14, weight: .semibold))
                        .foregroundColor(.pineDark)
                }
                .glassmorphic(padding: 14)
            }
        }
    }

    // MARK: - Pack preview

    private var packSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pack")
                .font(AppFont.rounded(13, weight: .semibold))
                .foregroundColor(.pineDark.opacity(0.45))
                .textCase(.uppercase)
                .kerning(0.8)

            let count = user?.packMembers.count ?? 0
            let limit = revenueCat.isPremium ? 20 : 5
            Text("\(count) of \(limit) members")
                .font(AppFont.rounded(15))
                .foregroundColor(.pineDark.opacity(0.6))
                .glassmorphic(padding: 14)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            if !revenueCat.isPremium {
                Button { showPaywall = true } label: {
                    settingsRow(icon: "star.fill", label: "Upgrade to Therian Pro", color: .soil)
                }
                Divider().padding(.horizontal, 16)
            }

            Button { showSignOutAlert = true } label: {
                settingsRow(icon: "arrow.right.square", label: "Sign Out", color: .pineDark.opacity(0.5))
            }
        }
        .background(Color.white)
        .cornerRadius(AppDesign.cornerRadius)
        .shadow(color: Color.pineDark.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    private func settingsRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .font(AppFont.rounded(15, weight: .medium))
                .foregroundColor(.pineDark)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.pineDark.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Edit Sheet

    private var editProfileSheet: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Photo picker (premium only)
                        if revenueCat.isPremium {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                avatarEditButton
                            }
                            .onChange(of: photoItem) { item in
                                Task {
                                    if let data = try? await item?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        profileVM.selectedImage = image
                                    }
                                }
                            }
                        }

                        // Username
                        editField(label: "Username", text: $profileVM.editUsername)

                        // Bio
                        VStack(alignment: .leading, spacing: 8) {
                            fieldLabel("Bio")
                            if revenueCat.isPremium || profileVM.isBioUnlocked {
                                TextEditor(text: $profileVM.editBio)
                                    .font(AppFont.rounded(15))
                                    .frame(minHeight: 90)
                                    .padding(12)
                                    .background(Color.moonlitCard)
                                    .cornerRadius(AppDesign.smallCornerRadius)
                                    .scrollContentBackground(.hidden)
                            } else {
                                Button {
                                    showAdPrompt = true
                                    profileVM.isEditing = false
                                } label: {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                        Text("Watch an ad to edit your bio today")
                                    }
                                    .font(AppFont.rounded(14))
                                    .foregroundColor(.pineDark.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.moonlitCard)
                                    .cornerRadius(AppDesign.smallCornerRadius)
                                }
                            }
                        }

                        // Secondary theriotype (premium)
                        if revenueCat.isPremium {
                            VStack(alignment: .leading, spacing: 8) {
                                fieldLabel("Secondary Theriotype")
                                Menu {
                                    Button("None") { profileVM.editSecondaryTheriotype = nil }
                                    ForEach(Theriotype.allCases) { t in
                                        Button("\(t.emoji) \(t.rawValue)") {
                                            profileVM.editSecondaryTheriotype = t
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if let t = profileVM.editSecondaryTheriotype {
                                            Text("\(t.emoji) \(t.rawValue)")
                                        } else {
                                            Text("Select (optional)")
                                                .foregroundColor(.pineDark.opacity(0.4))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.pineDark.opacity(0.35))
                                    }
                                    .font(AppFont.rounded(15))
                                    .foregroundColor(.pineDark)
                                    .padding(14)
                                    .background(Color.moonlitCard)
                                    .cornerRadius(AppDesign.smallCornerRadius)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        profileVM.isEditing = false
                    }
                    .foregroundColor(.pineMedium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard var u = authVM.currentTherianUser else { return }
                        Task {
                            await profileVM.saveProfile(user: &u)
                            authVM.currentTherianUser = u
                        }
                    }
                    .font(AppFont.rounded(15, weight: .semibold))
                    .foregroundColor(.pineMedium)
                    .disabled(profileVM.isLoading)
                }
            }
        }
    }

    private var avatarEditButton: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = profileVM.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient.pinePrimary)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Text(String(user?.username.prefix(1).uppercased() ?? "T"))
                            .font(AppFont.serif(34, weight: .bold))
                            .foregroundColor(.moonlit)
                    )
            }

            Circle()
                .fill(Color.soil)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
        }
    }

    private func editField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            TextField(label, text: text)
                .font(AppFont.rounded(15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color.moonlitCard)
                .cornerRadius(AppDesign.smallCornerRadius)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.rounded(13, weight: .semibold))
            .foregroundColor(.pineDark.opacity(0.45))
            .textCase(.uppercase)
            .kerning(0.8)
    }

    // MARK: - Rewarded Ad

    private func showRewardedAd(trigger: AdTrigger) {
        guard let vc = UIApplication.shared.rootViewController else { return }
        AdMobService.shared.showRewardedAd(from: vc) { earned in
            if earned {
                profileVM.unlockBioForDay()
                if let u = authVM.currentTherianUser {
                    profileVM.beginEditing(user: u)
                }
            }
        }
    }
}
