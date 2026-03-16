import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.pinePrimary
                .ignoresSafeArea()

            // Decorative blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color.soil.opacity(0.18))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -50, y: geo.size.height * 0.1)

                Circle()
                    .fill(Color.pineMedium.opacity(0.35))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 120, y: geo.size.height * 0.6)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Branding
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.moonlit, Color.soil],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Therian Diary")
                        .font(AppFont.serif(34, weight: .bold))
                        .foregroundColor(.moonlit)

                    Text("Log your shifts. Know yourself.")
                        .font(AppFont.rounded(16, weight: .regular))
                        .foregroundColor(.moonlit.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 14) {
                    // Apple Sign-In
                    SignInWithAppleButton(.signIn) { request in
                        let appleRequest = AuthService.shared.startAppleSignIn()
                        request.requestedScopes = appleRequest.requestedScopes
                        request.nonce = appleRequest.nonce
                    } onCompletion: { result in
                        Task { await authVM.handleAppleSignIn(result: result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .cornerRadius(AppDesign.cornerRadius)

                    // Google Sign-In
                    Button {
                        HapticsManager.shared.lightTap()
                        guard let vc = UIApplication.shared.rootViewController else { return }
                        Task { await authVM.signInWithGoogle(presenting: vc) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(AppFont.rounded(17, weight: .semibold))
                        }
                        .foregroundColor(.pineDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(AppDesign.cornerRadius)
                    }
                    .pressScaleStyle()
                }
                .padding(.horizontal, AppDesign.screenPadding)
                .padding(.bottom, 48)
            }
        }
        .overlay {
            if authVM.isLoading {
                ProgressView()
                    .tint(.moonlit)
                    .scaleEffect(1.5)
            }
        }
        .alert("Sign-In Error", isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button("OK") { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }
}

// MARK: - UIApplication helper
extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
