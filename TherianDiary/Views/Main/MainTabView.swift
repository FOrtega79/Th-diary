import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var revenueCat: RevenueCatService

    @StateObject private var homeVM   = HomeViewModel()
    @StateObject private var packVM   = PackViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var statsVM  = StatsViewModel()

    @State private var selectedTab: Tab = .home
    @State private var showLogShift = false

    enum Tab: Int, CaseIterable {
        case home, pack, stats, profile

        var icon: String {
            switch self {
            case .home:    return "house.fill"
            case .pack:    return "person.3.fill"
            case .stats:   return "chart.bar.fill"
            case .profile: return "person.crop.circle.fill"
            }
        }
        var label: String {
            switch self {
            case .home:    return "Home"
            case .pack:    return "Pack"
            case .stats:   return "Stats"
            case .profile: return "Profile"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(homeVM: homeVM, showLogShift: $showLogShift)
                case .pack:
                    PackView(packVM: packVM)
                case .stats:
                    StatsView(statsVM: statsVM)
                case .profile:
                    ProfileView(profileVM: profileVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showLogShift) {
            LogShiftView()
                .onDisappear {
                    // Reload home on dismiss
                    if let uid = authVM.currentTherianUser?.uid {
                        Task { await homeVM.loadDashboard(userId: uid) }
                    }
                }
        }
        .task {
            guard let uid = authVM.currentTherianUser?.uid else { return }
            await homeVM.loadDashboard(userId: uid)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    HapticsManager.shared.lightTap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: selectedTab == tab ? 22 : 20, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .soil : .pineDark.opacity(0.4))
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)

                        Text(tab.label)
                            .font(AppFont.rounded(10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .soil : .pineDark.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .pressScaleStyle(scale: 0.9)
            }
        }
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.pineDark.opacity(0.08))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(RevenueCatService.shared)
}
