# PicSurg - Product Requirements Document (PRD)

**Version:** 1.0
**Last Updated:** January 2026
**Status:** Draft

---

## 1. Executive Summary

PicSurg is an iOS application that uses machine learning to automatically identify surgical/operative photographs in a user's camera roll and securely transfers them to a HIPAA-compliant, password-protected storage area within the app.

### Problem Statement
Healthcare providers frequently capture surgical photos on personal devices for documentation, education, and patient records. These sensitive images containing Protected Health Information (PHI) remain mixed with personal photos, creating:
- HIPAA compliance risks
- Accidental exposure when sharing phone or showing photos
- Difficulty locating surgical images when needed
- No secure backup of medical documentation

### Solution
An intelligent iOS app that:
1. Scans the camera roll using ML to identify surgical photos
2. Presents identified photos for user review/approval
3. Moves approved photos to encrypted, biometric-protected storage
4. Removes sensitive images from the main photo library

---

## 2. Target Users

### Primary User: Healthcare Provider (Surgeon/Physician)
- Takes photos during surgical procedures for documentation
- Needs to keep medical images separate from personal photos
- Required to maintain HIPAA compliance
- Values quick, automated organization
- May not be technically sophisticated

### User Persona
**Dr. Sarah Chen, Orthopedic Surgeon**
- Takes 5-20 surgical photos per week
- Currently has hundreds of surgical images mixed in camera roll
- Has accidentally shown a surgical photo when sharing vacation pics
- Wants a "set it and forget it" solution
- Uses Face ID for everything

---

## 3. Feature Requirements

### 3.1 Core Features (MVP)

#### F1: Photo Library Scanning
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Scan device photo library to identify surgical/operative images |
| **ML Approach** | Existing trained model: `PicSurge V1 1.mlmodel` (Create ML Image Classifier) |
| **Trigger** | Background scanning at configurable intervals |
| **Scope** | All photos in camera roll, optionally filtered by date range |
| **Output** | List of photos classified as surgical with confidence scores |
| **Priority** | P0 - Critical |

#### F2: Review & Approval Interface
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Present identified surgical photos for user review before moving |
| **UI** | Grid view of identified photos with select/deselect capability |
| **Actions** | Approve (move to secure), Reject (leave in camera roll), Approve All |
| **Confidence Display** | Show ML confidence score for each photo |
| **Batch Operations** | Select multiple photos at once |
| **Priority** | P0 - Critical |

#### F3: Secure Storage Vault
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Encrypted storage area for surgical photos within the app |
| **Encryption** | AES-256 encryption at rest |
| **Access Control** | Face ID, Touch ID, or PIN required to view |
| **Organization** | Photos organized by date captured |
| **Viewing** | Full-screen photo viewer with zoom |
| **Priority** | P0 - Critical |

#### F4: Authentication System
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Secure access to the app and vault |
| **Methods** | Face ID, Touch ID, 6-digit PIN |
| **Fallback** | PIN required as backup for biometric |
| **Lock Timing** | Immediate lock when app backgrounds |
| **Failed Attempts** | Lock for increasing duration after failures |
| **Priority** | P0 - Critical |

#### F5: Photo Removal from Camera Roll
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Remove moved photos from main photo library |
| **Behavior** | Delete from camera roll after successful secure storage |
| **Confirmation** | Require user confirmation before deletion |
| **Recovery** | Photos remain in "Recently Deleted" per iOS behavior |
| **Priority** | P0 - Critical |

### 3.2 Future Features (Post-MVP)

#### F6: Background Automatic Scanning
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Scan for new photos automatically in background |
| **Notification** | Alert user when new surgical photos detected |
| **Frequency** | Configurable (hourly, daily, weekly) |
| **Priority** | P1 - High (complex, defer if needed for MVP) |

#### F7: Manual Photo Addition
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Allow users to manually add photos to vault |
| **Use Case** | Photos ML missed or non-surgical sensitive images |
| **Priority** | P1 - High |

#### F8: Export/Share Functionality
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Securely export photos from vault |
| **Methods** | AirDrop, secure email, save to Files app |
| **Audit** | Log all export actions |
| **Priority** | P2 - Medium |

#### F9: Search & Organization
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Search and organize vault photos |
| **Features** | Tags, folders, date filtering, text search |
| **Priority** | P2 - Medium |

#### F10: Cloud Backup
| Attribute | Requirement |
|-----------|-------------|
| **Description** | Encrypted backup to iCloud or secure server |
| **Encryption** | End-to-end encryption |
| **HIPAA** | Requires BAA with cloud provider |
| **Priority** | P3 - Future |

---

## 4. User Stories

### MVP User Stories

| ID | As a... | I want to... | So that... | Acceptance Criteria |
|----|---------|--------------|------------|---------------------|
| US1 | Healthcare provider | Scan my camera roll for surgical photos | I can identify sensitive images | - Scan completes within 2 min for 1000 photos<br>- Shows progress indicator<br>- Identifies >80% of surgical photos |
| US2 | Healthcare provider | Review photos before they're moved | I can verify ML accuracy | - See grid of identified photos<br>- Can select/deselect individual photos<br>- Can approve or reject batch |
| US3 | Healthcare provider | Store surgical photos securely | They're protected from unauthorized access | - Photos encrypted at rest<br>- Cannot be accessed without auth<br>- Not visible in iOS Photos app |
| US4 | Healthcare provider | Use Face ID to access my vault | Access is quick but secure | - Face ID prompt on app open<br>- Falls back to PIN<br>- Locks immediately on background |
| US5 | Healthcare provider | Remove surgical photos from camera roll | Sensitive images aren't mixed with personal photos | - Photos deleted after secure storage confirmed<br>- Confirmation dialog shown<br>- Can recover from Recently Deleted |
| US6 | Healthcare provider | Set up a PIN backup | I can access photos if Face ID fails | - 6-digit PIN setup during onboarding<br>- PIN works when biometric fails<br>- Can reset PIN with verification |

### Post-MVP User Stories

| ID | As a... | I want to... | So that... |
|----|---------|--------------|------------|
| US7 | Healthcare provider | Have photos scanned automatically | I don't have to remember to scan |
| US8 | Healthcare provider | Manually add photos to vault | I can secure images ML missed |
| US9 | Healthcare provider | Export photos securely | I can share for consultations |
| US10 | Healthcare provider | Organize photos by case/patient | I can find images when needed |
| US11 | Healthcare provider | Back up vault to cloud | I don't lose photos if phone lost |

---

## 5. User Interface Requirements

### 5.1 Screens

#### Screen 1: Onboarding
- Welcome/intro explaining app purpose
- Request photo library permissions
- Set up PIN (required)
- Enable Face ID/Touch ID (optional but recommended)
- Initial scan prompt

#### Screen 2: Home/Dashboard
- "Scan Now" button
- Last scan date/time
- Count of photos in vault
- Quick access to vault
- Pending reviews badge

#### Screen 3: Scan Results / Review
- Grid of identified surgical photos
- Thumbnail with confidence percentage
- Checkboxes for selection
- "Approve Selected" button
- "Reject All" option
- Individual photo detail view on tap

#### Screen 4: Secure Vault
- Grid of secured photos
- Organized by date (sections)
- Full-screen viewer on tap
- Photo count and storage used

#### Screen 5: Settings
- Authentication settings (PIN change, biometric toggle)
- Scan settings (auto-scan frequency)
- About/Help
- Delete all data option

### 5.2 Design Principles
- Medical/professional aesthetic (clean, trustworthy)
- Dark mode support
- Large touch targets (use in sterile gloves)
- Clear visual hierarchy
- Minimal text, icon-driven

---

## 6. Technical Constraints

### Platform Requirements
- iOS 16.0 or later
- iPhone only (iPad support future)
- Requires Photo Library access
- Requires Face ID / Touch ID hardware (for biometric)

### Performance Requirements
- Scan 1000 photos in < 2 minutes
- App launch to vault access < 3 seconds
- Photo encryption < 1 second per photo
- Smooth scrolling in vault (60fps)

### Storage
- Photos stored locally only (MVP)
- Vault size limited only by device storage
- Efficient storage (no duplicate data)

---

## 7. Success Metrics

### MVP Success Criteria
- [ ] Successfully identifies >80% of surgical photos in test set
- [ ] <10% false positive rate (non-surgical marked as surgical)
- [ ] User can complete full flow: scan → review → secure → verify
- [ ] Photos in vault cannot be accessed without authentication
- [ ] Photos successfully removed from camera roll after securing

### Future KPIs
- User retention (daily/weekly active)
- Photos secured per user per week
- Scan frequency
- ML accuracy improvement over time

---

## 8. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| ML accuracy too low | Users lose trust, miss surgical photos | Medium | Review step catches errors; retrain with more data |
| Background scanning battery drain | Users uninstall app | Medium | Optimize scan; make background optional |
| iOS permission changes | Features break in future iOS | Low | Follow Apple guidelines; test on betas |
| Data loss (vault corruption) | Loss of important medical records | Medium | Implement backup; validate storage integrity |
| HIPAA audit | Legal liability | Medium | Document security measures; consult compliance expert |

---

## 9. Out of Scope (MVP)

- iPad support
- Cloud backup/sync
- Multi-device access
- Video support (photos only)
- Patient information tagging
- Integration with EHR systems
- Apple Watch companion
- Android version

---

## 10. Open Questions

1. ~~**Training Data**: How should user-provided training photos be labeled? Need clear categories.~~ **RESOLVED** - Model already trained (`PicSurge V1 1.mlmodel`)
2. **False Negatives**: What happens to surgical photos the ML misses? Manual add feature priority?
3. **Compliance Audit**: Should we consult HIPAA compliance expert before launch?
4. **Recovery**: If user forgets PIN and biometric fails, what's the recovery path?

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| PHI | Protected Health Information - any health info that can identify a patient |
| HIPAA | Health Insurance Portability and Accountability Act - US healthcare privacy law |
| Vault | The secure, encrypted storage area within the app |
| Create ML | Apple's framework for training machine learning models |
| Core ML | Apple's framework for running ML models on device |
