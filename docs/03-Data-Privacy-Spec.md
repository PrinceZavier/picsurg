# PicSurg - Data & Privacy Specification

**Version:** 1.0
**Last Updated:** January 2026
**Status:** Draft

---

## 1. Overview

This document specifies how PicSurg handles data, with particular focus on privacy and HIPAA compliance requirements. As a healthcare provider using this app for surgical photos, HIPAA regulations apply.

---

## 2. Data Classification

### 2.1 Data Types Handled

| Data Type | Classification | Storage Location | Encryption |
|-----------|---------------|------------------|------------|
| Surgical Photos | PHI (Protected Health Information) | Encrypted vault on device | AES-256-GCM |
| Photo Metadata | PHI (dates, location if present) | Encrypted with photo | AES-256-GCM |
| Vault Index | Sensitive | Encrypted file on device | AES-256-GCM |
| User PIN | Sensitive | iOS Keychain | Hardware-backed |
| Encryption Key | Critical | iOS Keychain | Hardware-backed |
| App Settings | Non-sensitive | UserDefaults | None |
| ML Model | Non-sensitive | App bundle | None |

### 2.2 What is NOT Stored

- Patient names or identifiers (app doesn't ask for this)
- Medical record numbers
- Cloud copies of photos
- Usage analytics or telemetry
- Location data (stripped from photos if present)

---

## 3. HIPAA Compliance

### 3.1 HIPAA Security Rule Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Access Control** | Face ID/Touch ID + PIN required to access vault |
| **Audit Controls** | Local log of vault access (future enhancement) |
| **Integrity Controls** | AES-GCM provides authenticated encryption |
| **Transmission Security** | N/A - no data transmitted (local only) |
| **Encryption** | AES-256-GCM for all PHI at rest |

### 3.2 HIPAA Technical Safeguards

#### Access Controls (§164.312(a)(1))
- **Unique User Identification**: Single user per device (personal app)
- **Emergency Access**: PIN recovery via device owner verification (future)
- **Automatic Logoff**: App locks immediately when backgrounded
- **Encryption/Decryption**: AES-256 for all vault contents

#### Audit Controls (§164.312(b))
- MVP: Basic access logging (when vault opened)
- Future: Full audit trail with timestamps

#### Integrity (§164.312(c)(1))
- AES-GCM includes authentication tag
- Tampered data fails decryption
- Corrupted files detected on access

#### Authentication (§164.312(d))
- Biometric verification (Face ID/Touch ID)
- Knowledge-based backup (6-digit PIN)
- Failed attempt lockout

### 3.3 HIPAA Limitations (MVP)

| HIPAA Requirement | MVP Status | Notes |
|-------------------|------------|-------|
| Business Associate Agreement | N/A | No third parties handle PHI |
| Backup & Recovery | Limited | Depends on device backup settings |
| Audit Log Retention | Basic | Enhanced in future version |
| Access Termination | Manual | User must delete app/vault |

### 3.4 HIPAA Disclaimer

> **Important**: While PicSurg implements security best practices and encryption, the app alone does not make you HIPAA compliant. HIPAA compliance requires organizational policies, training, and procedures beyond any single application. Consult with a HIPAA compliance expert for your specific situation.

---

## 4. Data Flow & Lifecycle

### 4.1 Photo Scanning (Read-Only)

```
Camera Roll ──────▶ PhotoKit API ──────▶ ML Classification
                   (read access)         (in memory only)
                         │
                         ▼
                   Thumbnails shown
                   in Review screen
                   (not persisted)
```

- Photos remain in camera roll during scanning
- Only thumbnails loaded into memory for display
- Full-resolution images not loaded until approval
- No data written during scan phase

### 4.2 Photo Securing (Write)

```
Approved Photo ──▶ Load Full Image ──▶ Encrypt ──▶ Write to Vault
                   (memory)           (CryptoKit)  (Documents/)
                         │                              │
                         ▼                              ▼
                   Clear from memory            Delete from
                   after encryption             Camera Roll
```

### 4.3 Vault Access (Read)

```
User Request ──▶ Authenticate ──▶ Load Encrypted ──▶ Decrypt ──▶ Display
                 (Face ID/PIN)    File               (memory)    (screen)
                                                         │
                                                         ▼
                                                   Clear from memory
                                                   on view dismiss
```

---

## 5. Encryption Specification

### 5.1 Algorithm Details

| Parameter | Value |
|-----------|-------|
| Algorithm | AES-256-GCM |
| Key Size | 256 bits |
| Nonce Size | 96 bits (random per encryption) |
| Tag Size | 128 bits |
| Framework | Apple CryptoKit |

### 5.2 Key Management

```
┌─────────────────────────────────────────────────────────┐
│                    iOS Keychain                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Vault Encryption Key                            │    │
│  │  - 256-bit symmetric key                         │    │
│  │  - Protection: WhenUnlockedThisDeviceOnly       │    │
│  │  - Not backed up to iCloud                       │    │
│  │  - Tied to device Secure Enclave                │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  PIN Hash                                        │    │
│  │  - SHA-256 hash of user PIN                     │    │
│  │  - Protection: WhenUnlockedThisDeviceOnly       │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Key Lifecycle

| Event | Action |
|-------|--------|
| First app launch | Generate new 256-bit key, store in Keychain |
| App uninstall | Key automatically removed by iOS |
| Device wipe | Key destroyed with device |
| Vault export | Key never leaves device |

---

## 6. Storage Security

### 6.1 File System Structure

```
App Sandbox/
├── Documents/
│   └── Vault/
│       ├── index.encrypted      # Encrypted metadata
│       └── photos/
│           ├── {uuid}.encrypted # Encrypted photo files
│           └── ...
├── Library/
│   └── Preferences/
│       └── settings.plist       # Non-sensitive settings only
└── tmp/
    └── (cleared on app launch)
```

### 6.2 File Protection

| Directory | iOS Protection Class | Description |
|-----------|---------------------|-------------|
| Vault/ | CompleteProtection | Inaccessible when device locked |
| photos/ | CompleteProtection | Inaccessible when device locked |
| tmp/ | CompleteProtection | Cleared frequently |

### 6.3 Backup Exclusion

```swift
// Vault directory excluded from iCloud/iTunes backup
var url = vaultDirectoryURL
var resourceValues = URLResourceValues()
resourceValues.isExcludedFromBackup = true
try url.setResourceValues(resourceValues)
```

---

## 7. Authentication Security

### 7.1 Biometric Authentication

| Aspect | Implementation |
|--------|----------------|
| Framework | LocalAuthentication (LAContext) |
| Fallback | Always require PIN as backup |
| Reuse | Fresh authentication each app open |
| Device Support | Face ID (iPhone X+), Touch ID (older) |

### 7.2 PIN Security

| Aspect | Implementation |
|--------|----------------|
| Length | 6 digits minimum |
| Storage | SHA-256 hash in Keychain |
| Attempts | Lock after 5 failures |
| Lockout | Progressive: 1min, 5min, 15min, 1hr |
| Reset | Requires vault data deletion |

### 7.3 Session Management

```
App Launch ──▶ Require Auth ──▶ Unlock ──▶ Active Session
                    │                           │
                    │                           ▼
                    │                    App Backgrounded
                    │                           │
                    │                           ▼
                    └────────────────────── Lock Immediately
```

---

## 8. Privacy Practices

### 8.1 Data Minimization

- Only store photos user explicitly approves
- Strip EXIF location data before storing
- No analytics or tracking
- No network requests (fully offline)

### 8.2 User Control

| Action | User Can... |
|--------|-------------|
| Delete single photo | Yes, from vault |
| Delete all vault data | Yes, from settings |
| Export photos | Yes, with authentication |
| Revoke photo access | Yes, via iOS Settings |

### 8.3 Transparency

- Clear explanation during onboarding
- No hidden data collection
- Open about what's stored and where

---

## 9. Network & Cloud Policy

### 9.1 MVP Network Usage

| Network Activity | Used? | Purpose |
|------------------|-------|---------|
| Internet connection | No | App is fully offline |
| iCloud sync | No | Vault excluded from backup |
| Analytics | No | No telemetry collected |
| Crash reporting | No | No third-party services |
| Remote ML model | No | Model bundled in app |

### 9.2 Future Considerations

If cloud backup is added in future versions:
- End-to-end encryption required
- BAA (Business Associate Agreement) with cloud provider
- User opt-in only
- Clear disclosure of data handling

---

## 10. Incident Response

### 10.1 Device Loss/Theft

**Protections in place:**
- Vault encrypted with AES-256
- Key protected by device passcode via Keychain
- iOS file protection prevents access when locked
- Remote wipe via Find My iPhone removes all data

**User action if device lost:**
1. Use Find My iPhone to lock/wipe device
2. Vault data is unrecoverable without device passcode

### 10.2 Forgotten PIN

**Current MVP behavior:**
- If biometrics fail and PIN forgotten, vault is inaccessible
- Only recovery: delete app (vault data lost)

**Future enhancement:**
- Recovery via iCloud Keychain (if enabled)
- Security questions (lower security)

### 10.3 App Vulnerabilities

If security vulnerability discovered:
1. App update pushed immediately
2. Users notified to update
3. Vulnerability details disclosed after patch adoption

---

## 11. Compliance Checklist

### Pre-Launch

- [ ] Encryption implementation reviewed
- [ ] Keychain usage verified
- [ ] File protection classes confirmed
- [ ] Backup exclusion tested
- [ ] No PHI in logs or crash reports
- [ ] Privacy policy drafted

### Ongoing

- [ ] Regular security review
- [ ] iOS security updates monitored
- [ ] User feedback on security concerns
- [ ] Compliance documentation maintained

---

## 12. Glossary

| Term | Definition |
|------|------------|
| **PHI** | Protected Health Information - individually identifiable health data |
| **HIPAA** | Health Insurance Portability and Accountability Act |
| **AES-256-GCM** | Advanced Encryption Standard, 256-bit key, Galois/Counter Mode |
| **Keychain** | iOS secure storage for sensitive data like keys and passwords |
| **Secure Enclave** | Hardware security module in iPhone for key protection |
| **BAA** | Business Associate Agreement - HIPAA contract with vendors |
