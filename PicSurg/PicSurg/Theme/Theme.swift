import SwiftUI
import UIKit

// MARK: - App Theme

/// Centralized theme configuration for PicSurg
/// Provides consistent colors, typography, and styling across the app
enum Theme {

    // MARK: - Colors

    enum Colors {
        /// Primary brand color - medical teal (matches logo)
        static let primary = Color("AccentColor")
        static let primaryUIColor = UIColor(red: 0.031, green: 0.569, blue: 0.698, alpha: 1)

        /// Secondary - darker teal for contrast
        static let secondary = Color(red: 0.051, green: 0.431, blue: 0.529)

        /// Gradient colors (from logo)
        static let gradientStart = Color(red: 0.031, green: 0.569, blue: 0.698)  // Teal
        static let gradientEnd = Color(red: 0.133, green: 0.827, blue: 0.933)    // Cyan
        static let gradientGlow = Color(red: 0.4, green: 0.9, blue: 0.95)        // Light cyan glow

        /// Logo center - dark navy
        static let logoCenter = Color(red: 0.1, green: 0.15, blue: 0.25)

        /// Success states
        static let success = Color.green

        /// Warning states
        static let warning = Color.orange

        /// Error states
        static let error = Color.red

        /// Vault/secure states
        static let secure = Color(red: 0.031, green: 0.569, blue: 0.698)

        /// Background colors that adapt to dark mode
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)

        /// Text colors
        static let primaryText = Color(UIColor.label)
        static let secondaryText = Color(UIColor.secondaryLabel)
        static let tertiaryText = Color(UIColor.tertiaryLabel)

        /// Card/surface colors
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let cardBorder = Color(UIColor.separator)

        /// Overlay for dimmed backgrounds
        static let overlay = Color.black.opacity(0.4)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows

    enum Shadow {
        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }

    // MARK: - Touch Targets

    /// Minimum touch target for accessibility (especially with gloves)
    static let minTouchTarget: CGFloat = 44

    /// Large touch target for primary actions
    static let largeTouchTarget: CGFloat = 56
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Haptics

/// Centralized haptic feedback manager
enum Haptics {

    /// Light impact for button taps
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact for significant actions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact for major actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Soft impact for subtle feedback
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid impact for firm feedback
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    /// Success notification
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning notification
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error notification
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection changed feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Radius.medium)
    }

    /// Apply shadow style
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// Apply standard button haptic on tap
    func hapticTap(_ style: HapticStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            switch style {
            case .light: Haptics.light()
            case .medium: Haptics.medium()
            case .heavy: Haptics.heavy()
            case .selection: Haptics.selection()
            }
            action()
        }
    }
}

enum HapticStyle {
    case light, medium, heavy, selection
}

// MARK: - Button Styles

/// Primary filled button style
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.largeTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(isEnabled ? Theme.Colors.primary : Color.gray)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

/// Secondary outlined button style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.largeTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Color.gray.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

/// Destructive button style
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.largeTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Color.red)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Custom Modifiers

/// Loading overlay modifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                VStack(spacing: Theme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)

                    if !message.isEmpty {
                        Text(message)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.Radius.medium)
                .shadow(Theme.Shadow.medium)
            }
        }
        .animation(Theme.Animation.standard, value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String = "") -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    enum Status {
        case success, warning, error, info

        var color: Color {
            switch self {
            case .success: return Theme.Colors.success
            case .warning: return Theme.Colors.warning
            case .error: return Theme.Colors.error
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    let status: Status
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: status.icon)
            Text(text)
        }
        .font(.callout)
        .foregroundColor(status.color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(status.color.opacity(0.15))
        .cornerRadius(Theme.Radius.small)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.md)
            }
        }
        .padding()
    }
}

// MARK: - Shimmer Effect for Loading States

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Loading View

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.small)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .shimmer()
    }
}
