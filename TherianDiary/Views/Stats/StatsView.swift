import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var revenueCat: RevenueCatService
    @ObservedObject var statsVM: StatsViewModel

    @State private var showPaywall = false
    @State private var showAdPrompt = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moonlit.ignoresSafeArea()

                if statsVM.isLoading {
                    ProgressView().tint(.pineMedium)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            summaryRow
                            weeklyBarChart
                            shiftTypeChart
                            topTriggersSection
                            Color.clear.frame(height: 90)
                        }
                        .padding(.horizontal, AppDesign.screenPadding)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        if let uid = authVM.currentTherianUser?.uid {
                            await statsVM.loadStats(userId: uid)
                        }
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .confirmationDialog("Reveal Stats Chart", isPresented: $showAdPrompt) {
                Button("Watch Ad to Reveal (24h)") { showRewardedAd() }
                Button("Upgrade to Pro") { showPaywall = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(AdTrigger.statsReveal.message)
            }
            .task {
                if let uid = authVM.currentTherianUser?.uid {
                    await statsVM.loadStats(userId: uid)
                }
            }
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statMiniCard(title: "Streak", value: "\(statsVM.streak)d", icon: "flame.fill", color: .soil)
            statMiniCard(title: "Total", value: "\(statsVM.totalShifts)", icon: "pawprint.fill", color: .pineMedium)
            statMiniCard(
                title: "Avg Intensity",
                value: String(format: "%.1f", statsVM.averageIntensity),
                icon: "waveform",
                color: .pineDark
            )
        }
    }

    private func statMiniCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(AppFont.serif(22, weight: .bold))
                .foregroundColor(.pineDark)
            Text(title)
                .font(AppFont.rounded(11, weight: .medium))
                .foregroundColor(.pineDark.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .glassmorphic(padding: 14)
    }

    // MARK: - Weekly Bar Chart

    private var weeklyBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Last 7 Days")

            Chart(statsVM.shiftsPerDay(), id: \.0) { date, count in
                BarMark(
                    x: .value("Day", date, unit: .day),
                    y: .value("Shifts", count)
                )
                .foregroundStyle(LinearGradient.pinePrimary)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .frame(height: 160)
        }
        .glassmorphic()
    }

    // MARK: - Shift Type Pie Chart (paywall gated)

    private var shiftTypeChart: some View {
        let unlocked = revenueCat.isPremium || statsVM.isChartUnlocked

        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Shift Type Breakdown")

            ZStack {
                // Chart content
                if !statsVM.typeBreakdown.isEmpty {
                    Chart(statsVM.typeBreakdown) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Type", item.type.rawValue))
                        .cornerRadius(4)
                    }
                    .frame(height: 220)
                } else {
                    Text("No shifts logged yet.")
                        .font(AppFont.rounded(14))
                        .foregroundColor(.pineDark.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                }

                // Paywall overlay
                if !unlocked {
                    RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.pineMedium)
                                Text("Unlock Shift Breakdown")
                                    .font(AppFont.rounded(15, weight: .semibold))
                                    .foregroundColor(.pineDark)
                                Button {
                                    HapticsManager.shared.lightTap()
                                    showAdPrompt = true
                                } label: {
                                    Text("Watch Ad to Reveal")
                                        .font(AppFont.rounded(14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.pineMedium)
                                        .cornerRadius(20)
                                }
                            }
                        }
                }
            }
        }
        .glassmorphic()
    }

    // MARK: - Top Triggers

    @ViewBuilder
    private var topTriggersSection: some View {
        if !statsVM.topTriggers.isEmpty && (revenueCat.isPremium || statsVM.isChartUnlocked) {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Top Triggers")

                ForEach(statsVM.topTriggers, id: \.0) { tag, count in
                    HStack {
                        Text(tag)
                            .font(AppFont.rounded(14, weight: .medium))
                            .foregroundColor(.pineDark)
                        Spacer()
                        Text("\(count)")
                            .font(AppFont.rounded(13, weight: .semibold))
                            .foregroundColor(.soil)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.moonlitCard)
                    .cornerRadius(AppDesign.smallCornerRadius)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.rounded(13, weight: .semibold))
            .foregroundColor(.pineDark.opacity(0.45))
            .textCase(.uppercase)
            .kerning(0.8)
    }

    // MARK: - Rewarded Ad

    private func showRewardedAd() {
        guard let vc = UIApplication.shared.rootViewController else { return }
        AdMobService.shared.showRewardedAd(from: vc) { earned in
            if earned {
                statsVM.unlockChartForDay()
            }
        }
    }
}
