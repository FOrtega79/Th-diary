import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var username: String = ""
    @State private var selectedTheriotype: Theriotype = .wolf
    @State private var step: Int = 1
    @FocusState private var usernameFocused: Bool

    var body: some View {
        ZStack {
            Color.moonlit.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...2, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i <= step ? Color.pineMedium : Color.pineDark.opacity(0.2))
                            .frame(height: 4)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.top, 16)

                Spacer()

                if step == 1 {
                    theriotypePicker
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    usernameStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer()

                // CTA
                Button {
                    HapticsManager.shared.mediumTap()
                    withAnimation(.spring()) {
                        if step == 1 {
                            step = 2
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                usernameFocused = true
                            }
                        } else {
                            Task { await authVM.createProfile(username: username, primaryTheriotype: selectedTheriotype) }
                        }
                    }
                } label: {
                    Text(step == 1 ? "Next" : "Enter the Pack")
                        .font(AppFont.rounded(17, weight: .bold))
                        .foregroundColor(.moonlit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.pinePrimary)
                        .cornerRadius(AppDesign.cornerRadius)
                }
                .pressScaleStyle()
                .disabled(step == 2 && username.trimmingCharacters(in: .whitespaces).count < 3)
                .opacity(step == 2 && username.trimmingCharacters(in: .whitespaces).count < 3 ? 0.5 : 1)
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.bottom, 40)
            }
        }
        .overlay {
            if authVM.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.5)
            }
        }
        .alert("Oops", isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button("OK") { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }

    // MARK: - Step 1: Theriotype picker

    private var theriotypePicker: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome.")
                    .font(AppFont.serif(34, weight: .bold))
                    .foregroundColor(.pineDark)
                Text("What is your primary theriotype?")
                    .font(AppFont.rounded(17, weight: .regular))
                    .foregroundColor(.pineDark.opacity(0.65))
            }
            .padding(.horizontal, AppDesign.screenPadding)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Theriotype.allCases) { type in
                        Button {
                            HapticsManager.shared.lightTap()
                            withAnimation(.spring()) { selectedTheriotype = type }
                        } label: {
                            HStack(spacing: 10) {
                                Text(type.emoji)
                                    .font(.system(size: 22))
                                Text(type.rawValue)
                                    .font(AppFont.rounded(15, weight: .semibold))
                                    .foregroundColor(selectedTheriotype == type ? .moonlit : .pineDark)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedTheriotype == type
                                    ? AnyView(LinearGradient.pinePrimary)
                                    : AnyView(Color.moonlitCard)
                            )
                            .cornerRadius(AppDesign.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                                    .strokeBorder(selectedTheriotype == type ? Color.clear : Color.pineDark.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, AppDesign.screenPadding)
            }
        }
    }

    // MARK: - Step 2: Username

    private var usernameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Name.")
                    .font(AppFont.serif(34, weight: .bold))
                    .foregroundColor(.pineDark)
                Text("Choose a unique username for your Pack.")
                    .font(AppFont.rounded(17, weight: .regular))
                    .foregroundColor(.pineDark.opacity(0.65))
            }
            .padding(.horizontal, AppDesign.screenPadding)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.pineMedium)
                    TextField("username", text: $username)
                        .font(AppFont.rounded(17, weight: .regular))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($usernameFocused)
                }
                .padding(16)
                .background(Color.moonlitCard)
                .cornerRadius(AppDesign.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                        .strokeBorder(Color.pineMedium.opacity(0.3), lineWidth: 1)
                )

                Text("3–20 characters, letters and numbers only.")
                    .font(AppFont.rounded(13))
                    .foregroundColor(.pineDark.opacity(0.4))
            }
            .padding(.horizontal, AppDesign.screenPadding)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
