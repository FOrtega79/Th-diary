import SwiftUI
import SDWebImageSwiftUI

struct PackView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var revenueCat: RevenueCatService
    @ObservedObject var packVM: PackViewModel

    @State private var showSearch = false
    @State private var showPaywall = false
    @State private var showAdPrompt = false
    @State private var adTrigger: AdTrigger = .packSlot

    private var user: TherianUser? { authVM.currentTherianUser }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Incoming requests
                        if !packVM.incomingRequests.isEmpty {
                            incomingRequestsSection
                        }

                        // Pack members
                        packMembersSection

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.top, 8)
                }
                .refreshable {
                    if let u = user { await packVM.loadPack(for: u) }
                }
            }
            .navigationTitle("The Pack")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticsManager.shared.lightTap()
                        checkPackLimit()
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.pineMedium)
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchUserView(packVM: packVM)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog(adTrigger.title, isPresented: $showAdPrompt, titleVisibility: .visible) {
                Button(adTrigger.ctaLabel) { showRewardedAd() }
                Button("Upgrade to Pro") { showPaywall = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(adTrigger.message)
            }
            .task {
                if let u = user { await packVM.loadPack(for: u) }
            }
        }
    }

    // MARK: - Pack Limit Check

    private func checkPackLimit() {
        guard let u = user else { return }
        let limit = revenueCat.isPremium ? 20 : 5
        let canAdd = packVM.packMembers.count < limit || packVM.hasTemporarySlot

        if canAdd {
            showSearch = true
        } else if revenueCat.isPremium {
            showSearch = true   // premium already, show search
        } else {
            adTrigger = .packSlot
            showAdPrompt = true
        }
    }

    // MARK: - Rewarded Ad

    private func showRewardedAd() {
        guard let vc = UIApplication.shared.rootViewController else { return }
        AdMobService.shared.showRewardedAd(from: vc) { earned in
            if earned {
                packVM.unlockTemporarySlot()
                showSearch = true
            }
        }
    }

    // MARK: - Incoming Requests

    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Incoming Howls 🐾", count: packVM.incomingRequests.count)

            ForEach(packVM.incomingRequests) { request in
                PackRequestRow(request: request) {
                    Task { await packVM.accept(request: request) }
                } onDecline: {
                    Task { await packVM.decline(request: request) }
                }
            }
        }
    }

    // MARK: - Pack Members

    private var packMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let limit = revenueCat.isPremium ? 20 : 5
            sectionHeader("Pack Members", count: packVM.packMembers.count, limit: limit)

            if packVM.isLoading {
                HStack { Spacer(); ProgressView().tint(.pineMedium); Spacer() }
            } else if packVM.packMembers.isEmpty {
                emptyPackState
            } else {
                ForEach(packVM.packMembers) { member in
                    PackMemberRow(member: member) {
                        if let uid = user?.uid {
                            Task { await packVM.removeFromPack(userId: uid, memberId: member.uid) }
                        }
                    }
                }
            }
        }
    }

    private var emptyPackState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 44))
                .foregroundColor(.pineDark.opacity(0.25))

            Text("Your pack is empty.")
                .font(AppFont.serif(20, weight: .semibold))
                .foregroundColor(.pineDark.opacity(0.5))

            Text("Search for other therians by username and send them a Howl!")
                .font(AppFont.rounded(14))
                .foregroundColor(.pineDark.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, count: Int, limit: Int? = nil) -> some View {
        HStack {
            Text(title)
                .font(AppFont.rounded(13, weight: .semibold))
                .foregroundColor(.pineDark.opacity(0.45))
                .textCase(.uppercase)
                .kerning(0.8)
            Spacer()
            if let limit {
                Text("\(count)/\(limit)")
                    .font(AppFont.rounded(12, weight: .semibold))
                    .foregroundColor(.soil)
            } else {
                Text("\(count)")
                    .font(AppFont.rounded(12))
                    .foregroundColor(.pineDark.opacity(0.4))
            }
        }
    }
}

// MARK: - PackMemberRow

struct PackMemberRow: View {
    let member: TherianUser
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AsyncPackAvatar(urlString: member.profileImageUrl, username: member.username)

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(member.username)")
                    .font(AppFont.rounded(15, weight: .semibold))
                    .foregroundColor(.pineDark)

                Text(member.primaryTheriotype)
                    .font(AppFont.rounded(13))
                    .foregroundColor(.pineDark.opacity(0.45))
            }

            Spacer()

            if member.isPremium {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.soil)
                    .font(.system(size: 16))
            }
        }
        .glassmorphic(padding: 14)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "person.fill.xmark")
            }
        }
    }
}

// MARK: - PackRequestRow

struct PackRequestRow: View {
    let request: PackRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "waveform.and.person.filled")
                .font(.system(size: 22))
                .foregroundColor(.pineMedium)
                .frame(width: 40, height: 40)
                .background(Color.pineMedium.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("New Howl")
                    .font(AppFont.rounded(14, weight: .semibold))
                    .foregroundColor(.pineDark)
                Text("From: \(request.fromUserId.prefix(8))...")
                    .font(AppFont.rounded(12))
                    .foregroundColor(.pineDark.opacity(0.4))
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.pineDark.opacity(0.5))
                        .frame(width: 34, height: 34)
                        .background(Color.pineDark.opacity(0.08))
                        .clipShape(Circle())
                }

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.pineMedium)
                        .clipShape(Circle())
                }
            }
        }
        .glassmorphic(padding: 14)
    }
}

// MARK: - Async Avatar

struct AsyncPackAvatar: View {
    let urlString: String
    let username: String

    var body: some View {
        Group {
            if let url = URL(string: urlString), !urlString.isEmpty {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(LinearGradient.pinePrimary)
                    .overlay(
                        Text(String(username.prefix(1).uppercased()))
                            .font(AppFont.serif(16, weight: .bold))
                            .foregroundColor(.moonlit)
                    )
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}
