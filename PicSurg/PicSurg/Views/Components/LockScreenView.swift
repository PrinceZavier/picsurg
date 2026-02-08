import SwiftUI
import MessageUI

/// Lock screen requiring authentication
struct LockScreenView: View {
    @EnvironmentObject var authService: AuthService
    @State private var pin = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    @State private var showingRecovery = false

    private let pinLength = 6

    var body: some View {
        ZStack {
            // Main lock screen
            VStack(spacing: 30) {
                Spacer()

                // Logo with glow effect (matching onboarding)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.gradientGlow.opacity(0.3),
                                    Theme.Colors.gradientEnd.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)

                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Text("PicSurg")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.primary)

                Text("Enter your PIN to unlock")
                    .foregroundColor(.secondary)

                // PIN Dots
                HStack(spacing: 20) {
                    ForEach(0..<pinLength, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Theme.Colors.primary : Color.gray.opacity(0.3))
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
                                    .foregroundColor(Theme.Colors.primary)
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

                // Forgot PIN button
                if authService.hasRecoveryEmail {
                    Button {
                        showingRecovery = true
                    } label: {
                        Text("Forgot PIN?")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                // Try biometric on appear
                if authService.isBiometricAvailable && authService.isBiometricEnabled && !authService.isLockedOut {
                    authenticateWithBiometric()
                }
            }

            // Recovery overlay
            if showingRecovery {
                PINRecoveryView(isPresented: $showingRecovery)
                    .environmentObject(authService)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showingRecovery)
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

// MARK: - PIN Recovery View

struct PINRecoveryView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool

    @State private var currentStep: RecoveryStep = .confirm
    @State private var recoveryCode = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var error = ""
    @State private var generatedCode = ""
    @State private var isConfirmingPIN = false

    enum RecoveryStep {
        case confirm
        case enterCode
        case newPIN
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("PIN Recovery")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal)

                Spacer()

                switch currentStep {
                case .confirm:
                    confirmStepView
                case .enterCode:
                    enterCodeView
                case .newPIN:
                    newPINView
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Step Views

    private var confirmStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)

            Text("Reset Your PIN")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if let maskedEmail = authService.maskedRecoveryEmail {
                Text("We'll show you a recovery code.\nNote it down and enter it to verify.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)

                Text("Recovery email: \(maskedEmail)")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.primary)
            }

            Button {
                // Generate code and show it
                generatedCode = authService.generateRecoveryCode()
                currentStep = .enterCode
            } label: {
                Text("Get Recovery Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    private var enterCodeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)

            Text("Your Recovery Code")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Display the code prominently
            Text(generatedCode)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.Colors.primary)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

            Text("Remember this code!\nNow enter it below to verify:")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .font(.subheadline)

            // Code input
            TextField("Enter 6-digit code", text: $recoveryCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
                .padding(.horizontal, 40)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }

            Button {
                verifyCode()
            } label: {
                Text("Verify Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(recoveryCode.count == 6 ? Theme.Colors.primary : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(recoveryCode.count != 6)
            .padding(.horizontal, 40)
        }
    }

    private var newPINView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)

            Text(isConfirmingPIN ? "Confirm New PIN" : "Create New PIN")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(isConfirmingPIN ? "Enter your new PIN again" : "Enter a new 6-digit PIN")
                .foregroundColor(.gray)

            // PIN Dots
            HStack(spacing: 20) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < (isConfirmingPIN ? confirmPIN.count : newPIN.count) ? Theme.Colors.primary : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }

            // Number Pad
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 30) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addPINDigit("\(number)")
                            }
                        }
                    }
                }

                HStack(spacing: 30) {
                    Color.clear.frame(width: 70, height: 70)

                    NumberButton(number: "0") {
                        addPINDigit("0")
                    }

                    Button {
                        deletePINDigit()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Actions

    private func verifyCode() {
        error = ""
        if authService.verifyRecoveryCode(recoveryCode) {
            currentStep = .newPIN
        } else {
            error = "Invalid or expired code"
            recoveryCode = ""
        }
    }

    private func addPINDigit(_ digit: String) {
        error = ""
        if isConfirmingPIN {
            guard confirmPIN.count < 6 else { return }
            confirmPIN += digit
            if confirmPIN.count == 6 {
                finishPINReset()
            }
        } else {
            guard newPIN.count < 6 else { return }
            newPIN += digit
            if newPIN.count == 6 {
                isConfirmingPIN = true
            }
        }
    }

    private func deletePINDigit() {
        if isConfirmingPIN {
            guard !confirmPIN.isEmpty else {
                isConfirmingPIN = false
                return
            }
            confirmPIN.removeLast()
        } else {
            guard !newPIN.isEmpty else { return }
            newPIN.removeLast()
        }
    }

    private func finishPINReset() {
        guard newPIN == confirmPIN else {
            error = "PINs don't match"
            confirmPIN = ""
            isConfirmingPIN = false
            newPIN = ""
            return
        }

        do {
            try authService.resetPINAfterRecovery(newPIN)
            isPresented = false
        } catch {
            self.error = "Failed to reset PIN"
        }
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
