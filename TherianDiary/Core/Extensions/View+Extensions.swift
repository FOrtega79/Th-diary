import SwiftUI

// MARK: - Glassmorphic Card Modifier
struct GlassmorphicModifier: ViewModifier {
    var cornerRadius: CGFloat = AppDesign.cornerRadius
    var padding: CGFloat = AppDesign.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.glassBorder, lineWidth: 1)
                }
            )
            .shadow(color: Color.pineDark.opacity(0.12), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func glassmorphic(
        cornerRadius: CGFloat = AppDesign.cornerRadius,
        padding: CGFloat = AppDesign.cardPadding
    ) -> some View {
        modifier(GlassmorphicModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Press Scale Effect
struct PressScaleEffect: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    /// Adds a spring scale-down on press, matching PRD spec.
    func pressScaleStyle(scale: CGFloat = 0.95) -> some View {
        self.buttonStyle(PressScaleEffect(scale: scale))
    }
}

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Blur Overlay (Stats paywall)
struct BlurOverlay: ViewModifier {
    var isBlurred: Bool
    var cornerRadius: CGFloat = AppDesign.cornerRadius

    func body(content: Content) -> some View {
        content
            .blur(radius: isBlurred ? 10 : 0)
            .overlay {
                if isBlurred {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(0.15))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isBlurred)
    }
}

extension View {
    func paywallBlur(_ isBlurred: Bool, cornerRadius: CGFloat = AppDesign.cornerRadius) -> some View {
        modifier(BlurOverlay(isBlurred: isBlurred, cornerRadius: cornerRadius))
    }
}
