import SwiftUI
import Photos

/// Settings screen
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @StateObject private var photoService = PhotoService.shared

    @State private var showingChangePIN = false
    @State private var showingClearVault = false
    @State private var showingResetApp = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // MARK: - Photo Access Helpers

    private var photoAccessStatus: String {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            return "Full Access"
        case .limited:
            return "Limited Access"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                securitySection
                photoAccessSection
                storageSection
                aboutSection
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingChangePIN) {
                ChangePINView()
            }
            .alert("Clear Vault", isPresented: $showingClearVault) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearVault()
                }
            } message: {
                Text("This will permanently delete all photos in your vault. This cannot be undone.")
            }
            .alert("Reset App", isPresented: $showingResetApp) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will delete all your data including secured photos, PIN, and settings. This cannot be undone.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    private var securitySection: some View {
        Section("Security") {
            if authService.isBiometricAvailable {
                Toggle(isOn: Binding(
                    get: { authService.isBiometricEnabled },
                    set: { authService.isBiometricEnabled = $0 }
                )) {
                    Label(authService.biometricName, systemImage: authService.biometricType == .faceID ? "faceid" : "touchid")
                }
            }

            Button {
                showingChangePIN = true
            } label: {
                Label("Change PIN", systemImage: "lock.rotation")
            }
        }
    }

    private var photoAccessSection: some View {
        Section {
            HStack {
                Label("Current Access", systemImage: "photo.on.rectangle")
                Spacer()
                Text(photoAccessStatus)
                    .foregroundColor(.secondary)
            }

            Button {
                openAppSettings()
            } label: {
                Label("Change Photo Access", systemImage: "gear")
            }
        } header: {
            Text("Photo Access")
        } footer: {
            Text("Opens Settings where you can change photo library access permissions.")
        }
    }

    private var storageSection: some View {
        Section("Storage") {
            let stats = VaultService.shared.statistics

            HStack {
                Label("Photos in Vault", systemImage: "photo.on.rectangle")
                Spacer()
                Text("\(stats.photoCount)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Storage Used", systemImage: "internaldrive")
                Spacer()
                Text(stats.formattedSize)
                    .foregroundColor(.secondary)
            }

            Button(role: .destructive) {
                showingClearVault = true
            } label: {
                Label("Clear Vault", systemImage: "trash")
            }
            .disabled(stats.photoCount == 0)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://example.com/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://example.com/help")!) {
                Label("Help & Support", systemImage: "questionmark.circle")
            }
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetApp = true
            } label: {
                Label("Reset App", systemImage: "exclamationmark.triangle")
            }
        } footer: {
            Text("This will delete all data including your vault and settings.")
        }
    }

    // MARK: - Actions

    private func clearVault() {
        do {
            try VaultService.shared.clearVault()
            Haptics.success()
        } catch {
            Haptics.error()
            errorMessage = "Failed to clear vault. Please try again."
            showingError = true
        }
    }

    private func resetApp() {
        var errors: [String] = []

        do {
            try VaultService.shared.clearVault()
        } catch {
            errors.append("vault")
        }

        do {
            try authService.deletePIN()
        } catch {
            errors.append("PIN")
        }

        do {
            try CryptoService.deleteKey()
        } catch {
            errors.append("encryption key")
        }

        appState.resetAllData()

        if !errors.isEmpty {
            Haptics.warning()
            errorMessage = "Reset completed with some issues. Failed to clear: \(errors.joined(separator: ", ")). The app has been reset."
            showingError = true
        } else {
            Haptics.success()
        }
    }
}

struct ChangePINView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var step = 0 // 0: current, 1: new, 2: confirm
    @State private var error = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(stepTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(stepSubtitle)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // PIN Dots
                HStack(spacing: 20) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < currentPINCount ? Color.blue : Color.gray.opacity(0.3))
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
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Enter Current PIN"
        case 1: return "Enter New PIN"
        case 2: return "Confirm New PIN"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 0: return "Enter your current PIN to continue"
        case 1: return "Choose a new 6-digit PIN"
        case 2: return "Enter your new PIN again"
        default: return ""
        }
    }

    private var currentPINCount: Int {
        switch step {
        case 0: return currentPIN.count
        case 1: return newPIN.count
        case 2: return confirmPIN.count
        default: return 0
        }
    }

    private func addDigit(_ digit: String) {
        error = ""

        switch step {
        case 0:
            guard currentPIN.count < 6 else { return }
            currentPIN += digit
            if currentPIN.count == 6 {
                verifyCurrent()
            }
        case 1:
            guard newPIN.count < 6 else { return }
            newPIN += digit
            if newPIN.count == 6 {
                step = 2
            }
        case 2:
            guard confirmPIN.count < 6 else { return }
            confirmPIN += digit
            if confirmPIN.count == 6 {
                saveNewPIN()
            }
        default:
            break
        }
    }

    private func deleteDigit() {
        switch step {
        case 0:
            guard !currentPIN.isEmpty else { return }
            currentPIN.removeLast()
        case 1:
            guard !newPIN.isEmpty else { return }
            newPIN.removeLast()
        case 2:
            if confirmPIN.isEmpty {
                step = 1
            } else {
                confirmPIN.removeLast()
            }
        default:
            break
        }
    }

    private func verifyCurrent() {
        if authService.verifyPIN(currentPIN) {
            Haptics.success()
            step = 1
        } else {
            Haptics.error()
            error = "Incorrect PIN"
            currentPIN = ""
        }
    }

    private func saveNewPIN() {
        guard newPIN == confirmPIN else {
            Haptics.error()
            error = "PINs don't match"
            confirmPIN = ""
            return
        }

        do {
            try authService.setPIN(newPIN)
            Haptics.success()
            dismiss()
        } catch {
            Haptics.error()
            self.error = "Failed to save PIN"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthService.shared)
}
