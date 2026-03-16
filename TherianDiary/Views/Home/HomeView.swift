import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var revenueCat: RevenueCatService
    @ObservedObject var homeVM: HomeViewModel
    @Binding var showLogShift: Bool

    @State private var showPaywall = false
    @State private var appear = false

    private var user: TherianUser? { authVM.currentTherianUser }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        logShiftSection
                        statsSection
                        latestEntrySection
                        if !revenueCat.isPremium { proBannerSection }
                        Color.clear.frame(height: 90) // tab bar clearance
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.top, 8)
                }
                .refreshable {
                    if let uid = user?.uid {
                        await homeVM.loadDashboard(userId: uid)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { appear = true }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(AppFont.rounded(13, weight: .medium))
                    .foregroundColor(.pineDark.opacity(0.45))

                Text(homeVM.greetingText(for: user?.username ?? "Traveller"))
                    .font(AppFont.serif(24, weight: .bold))
                    .foregroundColor(.pineDark)
            }

            Spacer()

            // Profile avatar
            NavigationLink {
                // Navigate to profile — handled in MainTabView but also accessible here
                EmptyView()
            } label: {
                avatarView
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let urlString = user?.profileImageUrl, let url = URL(string: urlString), !urlString.isEmpty {
            WebImage(url: url)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.pineMedium.opacity(0.4), lineWidth: 2))
        } else {
            Circle()
                .fill(LinearGradient.pinePrimary)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user?.username.prefix(1).uppercased() ?? "T"))
                        .font(AppFont.serif(18, weight: .bold))
                        .foregroundColor(.moonlit)
                )
        }
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date())
    }

    // MARK: - Log Shift

    private var logShiftSection: some View {
        LogShiftButton {
            showLogShift = true
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatsCard(
                title: "Day Streak",
                value: "\(homeVM.streak)",
                icon: "flame.fill",
                accent: .soil
            )
            StatsCard(
                title: "Total Shifts",
                value: "\(homeVM.totalShifts)",
                icon: "pawprint.fill",
                accent: .pineMedium
            )
        }
    }

    // MARK: - Latest Entry

    @ViewBuilder
    private var latestEntrySection: some View {
        if let shift = homeVM.latestShift {
            VStack(alignment: .leading, spacing: 10) {
                Text("Latest Entry")
                    .font(AppFont.rounded(13, weight: .semibold))
                    .foregroundColor(.pineDark.opacity(0.45))
                    .textCase(.uppercase)
                    .kerning(0.8)

                LatestEntryCard(shift: shift)
            }
        }
    }

    // MARK: - Pro Banner

    private var proBannerSection: some View {
        ProBanner(action: { showPaywall = true })
    }
}
