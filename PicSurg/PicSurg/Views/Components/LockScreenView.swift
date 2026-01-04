import SwiftUI

/// Lock screen requiring authentication
struct LockScreenView: View {
    @EnvironmentObject var authService: AuthService
    @State private var pin = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false

    private let pinLength = 6

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("PicSurg")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Enter your PIN to unlock")
                .foregroundColor(.secondary)

            // PIN Dots
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical)

            // Error message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.callout)
            }

            // Lockout message
            if authService.isLockedOut {
                Text("Too many attempts. Try again in \(formatTime(authService.lockoutRemainingSeconds))")
                    .foregroundColor(.orange)
                    .font(.callout)
            }

            Spacer()

            // Number Pad
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 30) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }

                HStack(spacing: 30) {
                    // Biometric button
                    if authService.isBiometricAvailable && authService.isBiometricEnabled {
                        Button {
                            authenticateWithBiometric()
                        } label: {
                            Image(systemName: authService.biometricType == .faceID ? "faceid" : "touchid")
                                .font(.title)
                                .frame(width: 70, height: 70)
                        }
                    } else {
                        Color.clear.frame(width: 70, height: 70)
                    }

                    NumberButton(number: "0") {
                        addDigit("0")
                    }

                    // Delete button
                    Button {
                        deleteDigit()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                    }
                    .foregroundColor(.primary)
                }
            }
            .disabled(authService.isLockedOut)

            Spacer()
        }
        .padding()
        .onAppear {
            // Try biometric on appear
            if authService.isBiometricAvailable && authService.isBiometricEnabled && !authService.isLockedOut {
                authenticateWithBiometric()
            }
        }
    }

    private func addDigit(_ digit: String) {
        guard pin.count < pinLength else { return }
        pin += digit
        showError = false

        if pin.count == pinLength {
            verifyPIN()
        }
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }

    private func verifyPIN() {
        if authService.verifyPIN(pin) {
            // Success - authService.unlock() is called in verifyPIN
            pin = ""
        } else {
            // Failure
            showError = true
            if authService.isLockedOut {
                errorMessage = "Account locked"
            } else {
                errorMessage = "Incorrect PIN. \(5 - authService.failedAttempts) attempts remaining."
            }
            pin = ""

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func authenticateWithBiometric() {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        Task {
            let success = await authService.authenticateWithBiometric()
            await MainActor.run {
                isAuthenticating = false
                if !success && !authService.isAuthenticated {
                    // Biometric failed, user can try PIN
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
        return "\(seconds) seconds"
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 70, height: 70)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    LockScreenView()
        .environmentObject(AuthService.shared)
}
