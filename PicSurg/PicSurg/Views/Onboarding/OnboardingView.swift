import SwiftUI
import Photos

/// Onboarding flow for new users
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @StateObject private var photoService = PhotoService.shared

    @State private var currentStep = 0
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var pinError = ""
    @State private var enableBiometric = true

    private let totalSteps = 4

    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Theme.Colors.primary : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            TabView(selection: $currentStep) {
                // Step 1: Welcome
                WelcomeStep(onContinue: { currentStep = 1 })
                    .tag(0)

                // Step 2: Photo Permission
                PermissionStep(photoService: photoService, onContinue: { currentStep = 2 })
                    .tag(1)

                // Step 3: PIN Setup
                PINSetupStep(
                    pin: $pin,
                    confirmPin: $confirmPin,
                    error: $pinError,
                    onContinue: { setupPIN() }
                )
                .tag(2)

                // Step 4: Biometric
                BiometricStep(
                    enableBiometric: $enableBiometric,
                    biometricName: authService.biometricName,
                    isAvailable: authService.isBiometricAvailable,
                    onComplete: { completeOnboarding() }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
    }

    private func setupPIN() {
        guard pin.count == 6 else {
            pinError = "PIN must be 6 digits"
            return
        }

        guard pin == confirmPin else {
            pinError = "PINs don't match"
            confirmPin = ""
            return
        }

        do {
            try authService.setPIN(pin)
            currentStep = 3
        } catch {
            pinError = "Failed to save PIN"
        }
    }

    private func completeOnboarding() {
        authService.isBiometricEnabled = enableBiometric && authService.isBiometricAvailable
        appState.setOnboardingComplete()
        authService.unlock()
    }
}

// MARK: - Step Views

struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo with glow effect
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

            // Centered teal title
            Text("PicSurg")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.primary)

            Text("Automatically identify and secure your surgical photos with military-grade encryption.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 15) {
                FeatureRow(icon: "brain", text: "ML-powered photo detection")
                FeatureRow(icon: "lock.shield", text: "AES-256 encryption")
                FeatureRow(icon: "faceid", text: "Biometric protection")
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 30)

            Text(text)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct PermissionStep: View {
    @ObservedObject var photoService: PhotoService
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)

            Text("Photo Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("PicSurg needs access to your photos to identify and secure surgical images.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Spacer()

            if photoService.canAccessPhotos {
                Label("Access Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(Theme.Colors.success)
                    .font(.headline)
            }

            Spacer()

            Button(action: {
                if photoService.canAccessPhotos {
                    onContinue()
                } else {
                    Task {
                        _ = await photoService.requestAuthorization()
                        if photoService.canAccessPhotos {
                            onContinue()
                        }
                    }
                }
            }) {
                Text(photoService.canAccessPhotos ? "Continue" : "Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct PINSetupStep: View {
    @Binding var pin: String
    @Binding var confirmPin: String
    @Binding var error: String
    let onContinue: () -> Void

    @State private var isConfirming = false
    @State private var showWarning = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 70))
                .foregroundColor(Theme.Colors.primary)

            Text(isConfirming ? "Confirm PIN" : "Create PIN")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(isConfirming ? "Enter your PIN again to confirm" : "Create a 6-digit PIN to protect your vault")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            // PIN Recovery Warning
            if !isConfirming {
                Button {
                    showWarning = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Important: No PIN recovery")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }

            // PIN Dots
            HStack(spacing: 20) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < (isConfirming ? confirmPin.count : pin.count) ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical)

            if !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
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
                    Color.clear.frame(width: 70, height: 70)

                    NumberButton(number: "0") {
                        addDigit("0")
                    }

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

            Spacer()
        }
        .padding()
        .alert("No PIN Recovery", isPresented: $showWarning) {
            Button("I Understand", role: .cancel) {}
        } message: {
            Text("If you forget your PIN, there is NO way to recover your secured photos. Your encrypted data will be permanently lost.\n\nPlease choose a PIN you will remember, or store it securely.")
        }
    }

    private func addDigit(_ digit: String) {
        error = ""

        if isConfirming {
            guard confirmPin.count < 6 else { return }
            confirmPin += digit
            if confirmPin.count == 6 {
                onContinue()
            }
        } else {
            guard pin.count < 6 else { return }
            pin += digit
            if pin.count == 6 {
                isConfirming = true
            }
        }
    }

    private func deleteDigit() {
        if isConfirming {
            guard !confirmPin.isEmpty else {
                isConfirming = false
                return
            }
            confirmPin.removeLast()
        } else {
            guard !pin.isEmpty else { return }
            pin.removeLast()
        }
    }
}

struct BiometricStep: View {
    @Binding var enableBiometric: Bool
    let biometricName: String
    let isAvailable: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: biometricName == "Face ID" ? "faceid" : "touchid")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)

            Text("Enable \(biometricName)")
                .font(.largeTitle)
                .fontWeight(.bold)

            if isAvailable {
                Text("Use \(biometricName) for quick and secure access to your vault.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)

                Toggle("Enable \(biometricName)", isOn: $enableBiometric)
                    .tint(Theme.Colors.primary)
                    .padding(.horizontal, 40)
                    .padding(.top)
            } else {
                Text("\(biometricName) is not available on this device. You'll use your PIN to unlock.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: onComplete) {
                Text("Complete Setup")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthService.shared)
}
