import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var revenueCat: RevenueCatService
    @Environment(\.dismiss) var dismiss

    @State private var selectedPackage: Package?
    @State private var showError = false
    @State private var errorMessage = ""

    private let features: [(String, String)] = [
        ("person.3.fill",          "Up to 20 Pack Members"),
        ("photo.fill",             "Custom Profile Picture"),
        ("pencil.line",            "Custom Bio & Username"),
        ("chart.pie.fill",         "Advanced Shift Analytics"),
        ("star.fill",              "Secondary Theriotype"),
        ("eye.slash.fill",         "Ad-Free Experience")
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.pinePrimary
                .ignoresSafeArea()

            // Decorative orb
            Circle()
                .fill(Color.soil.opacity(0.25))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 100, y: -100)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        featuresSection
                        pricingSection
                        legalSection
                    }
                    .padding(.horizontal, AppDesign.screenPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .task { await revenueCat.fetchOfferings() }
        .onAppear {
            if let yearly = revenueCat.annualPackage {
                selectedPackage = yearly
            } else {
                selectedPackage = revenueCat.monthlyPackage
            }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.soil.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.soil, Color(hex: "#E07040")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Text("Therian Pro")
                .font(AppFont.serif(34, weight: .bold))
                .foregroundColor(.moonlit)

            Text("Unlock your full wild self.")
                .font(AppFont.rounded(17))
                .foregroundColor(.moonlit.opacity(0.65))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.soil)
                        .frame(width: 28)
                    Text(text)
                        .font(AppFont.rounded(15, weight: .medium))
                        .foregroundColor(.moonlit)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.soil)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(AppDesign.smallCornerRadius)
            }
        }
    }

    // MARK: - Pricing

    @ViewBuilder
    private var pricingSection: some View {
        if revenueCat.isLoading {
            ProgressView().tint(.moonlit)
        } else {
            VStack(spacing: 12) {
                // Annual (recommended)
                if let annual = revenueCat.annualPackage {
                    packageButton(package: annual, isRecommended: true)
                }

                // Monthly
                if let monthly = revenueCat.monthlyPackage {
                    packageButton(package: monthly, isRecommended: false)
                }

                // CTA
                Button {
                    guard let pkg = selectedPackage else { return }
                    HapticsManager.shared.lightTap()
                    Task {
                        do {
                            try await revenueCat.purchase(package: pkg)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    HStack {
                        if revenueCat.isLoading {
                            ProgressView().tint(.pineDark)
                        } else {
                            Text("Start Free Trial")
                                .font(AppFont.rounded(18, weight: .bold))
                        }
                    }
                    .foregroundColor(.pineDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.moonlit)
                    .cornerRadius(AppDesign.cornerRadius)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .pressScaleStyle()
                .disabled(selectedPackage == nil || revenueCat.isLoading)

                // Restore
                Button {
                    Task {
                        do {
                            try await revenueCat.restorePurchases()
                            if revenueCat.isPremium { dismiss() }
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(AppFont.rounded(13))
                        .foregroundColor(.moonlit.opacity(0.5))
                }
            }
        }
    }

    private func packageButton(package: Package, isRecommended: Bool) -> some View {
        Button {
            HapticsManager.shared.lightTap()
            withAnimation(.spring()) { selectedPackage = package }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(package.storeProduct.localizedTitle)
                            .font(AppFont.rounded(15, weight: .semibold))
                            .foregroundColor(.moonlit)
                        if isRecommended {
                            Text("Best Value")
                                .font(AppFont.rounded(10, weight: .bold))
                                .foregroundColor(.pineDark)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.soil)
                                .cornerRadius(8)
                        }
                    }
                    if isRecommended {
                        Text("3-day free trial, then billed yearly")
                            .font(AppFont.rounded(12))
                            .foregroundColor(.moonlit.opacity(0.55))
                    }
                }
                Spacer()
                Text(package.storeProduct.localizedPriceString)
                    .font(AppFont.rounded(16, weight: .bold))
                    .foregroundColor(.moonlit)
            }
            .padding(16)
            .background(
                selectedPackage?.identifier == package.identifier
                    ? Color.white.opacity(0.18)
                    : Color.white.opacity(0.07)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .strokeBorder(
                        selectedPackage?.identifier == package.identifier ? Color.soil : Color.clear,
                        lineWidth: 2
                    )
            )
            .cornerRadius(AppDesign.smallCornerRadius)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Text("Subscriptions auto-renew. Cancel anytime in Settings. By subscribing you agree to our Terms of Service and Privacy Policy.")
            .font(AppFont.rounded(11))
            .foregroundColor(.moonlit.opacity(0.35))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    PaywallView()
        .environmentObject(RevenueCatService.shared)
}
