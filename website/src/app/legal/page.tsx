import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Legal — PicSurg",
  description: "Privacy Policy and Terms of Service for PicSurg.",
};

export default function LegalPage() {
  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-3xl">
        <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">Legal</h1>
        <p className="mb-12 text-gray-400">
          Last updated: February 2026
        </p>

        {/* Quick nav */}
        <div className="mb-12 flex gap-4">
          <a href="#privacy" className="rounded-full border border-white/10 px-5 py-2 text-sm text-gray-300 transition-colors hover:border-teal hover:text-teal-light">
            Privacy Policy
          </a>
          <a href="#terms" className="rounded-full border border-white/10 px-5 py-2 text-sm text-gray-300 transition-colors hover:border-teal hover:text-teal-light">
            Terms of Service
          </a>
        </div>

        {/* Privacy Policy */}
        <section id="privacy" className="mb-20 scroll-mt-24">
          <h2 className="mb-8 text-3xl font-bold text-white">Privacy Policy</h2>

          <div className="space-y-8 text-gray-300 leading-relaxed">
            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">1. Introduction</h3>
              <p>
                PicSurg (&quot;we&quot;, &quot;our&quot;, or &quot;the App&quot;) is committed to protecting
                your privacy. This Privacy Policy explains how we handle information when
                you use our iOS application. PicSurg is designed with a privacy-first
                approach — all data processing occurs on your device.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">2. Information We Collect</h3>
              <p className="mb-3">
                <strong className="text-white">We do not collect, transmit, or store any personal data on external servers.</strong>
              </p>
              <p className="mb-3">The App processes the following data locally on your device:</p>
              <ul className="list-disc space-y-2 pl-6">
                <li><strong className="text-white">Photos:</strong> The App accesses your photo library (with your permission) to analyze images using an on-device machine learning model. Photos identified as surgical are encrypted and stored locally in an encrypted vault.</li>
                <li><strong className="text-white">Authentication data:</strong> Your PIN hash, biometric enrollment preferences, and optional recovery email are stored in the iOS Keychain on your device.</li>
                <li><strong className="text-white">App preferences:</strong> Settings such as scan history and onboarding status are stored locally using iOS UserDefaults.</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">3. How We Use Your Information</h3>
              <p>All data processing occurs on-device for the sole purpose of:</p>
              <ul className="mt-3 list-disc space-y-2 pl-6">
                <li>Classifying photos as surgical or non-surgical using the on-device ML model</li>
                <li>Encrypting and securely storing selected photos in your local vault</li>
                <li>Authenticating you via Face ID, Touch ID, or PIN</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">4. Data Sharing</h3>
              <p>
                We do not share, sell, or transmit any of your data to third parties.
                PicSurg has no servers, no analytics services, and no third-party SDKs.
                The App operates entirely offline.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">5. Data Security</h3>
              <p>Your photos are protected by:</p>
              <ul className="mt-3 list-disc space-y-2 pl-6">
                <li>AES-256-GCM encryption for all vault contents</li>
                <li>iOS Keychain storage for encryption keys (WhenUnlockedThisDeviceOnly)</li>
                <li>Biometric authentication (Face ID / Touch ID) with PIN fallback</li>
                <li>Automatic locking when the app is backgrounded</li>
                <li>Vault exclusion from iCloud and iTunes backups</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">6. HIPAA Considerations</h3>
              <p>
                PicSurg is designed to support HIPAA Security Rule requirements for
                handling Protected Health Information (PHI). Since all data remains on
                your device with no external transmission, the App minimizes the risk of
                unauthorized access or data breaches. Healthcare providers should consult
                their compliance officers regarding institutional policies.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">7. Your Rights</h3>
              <p>You have full control over your data:</p>
              <ul className="mt-3 list-disc space-y-2 pl-6">
                <li>You can restore any photo from the vault to your camera roll</li>
                <li>You can delete individual photos or all vault contents</li>
                <li>You can reset the entire app and delete all data in Settings</li>
                <li>Uninstalling the App removes all locally stored data</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">8. Children&apos;s Privacy</h3>
              <p>
                PicSurg is not intended for use by children under 17. We do not knowingly
                collect any information from children.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">9. Changes to This Policy</h3>
              <p>
                We may update this Privacy Policy from time to time. Changes will be
                reflected in the &quot;Last updated&quot; date at the top of this page. Continued use
                of the App after changes constitutes acceptance of the updated policy.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">10. Contact</h3>
              <p>
                If you have questions about this Privacy Policy, please contact us at{" "}
                <a href="mailto:contact@picsurg.com" className="text-teal-light hover:underline">
                  contact@picsurg.com
                </a>.
              </p>
            </div>
          </div>
        </section>

        {/* Divider */}
        <hr className="mb-20 border-white/10" />

        {/* Terms of Service */}
        <section id="terms" className="scroll-mt-24">
          <h2 className="mb-8 text-3xl font-bold text-white">Terms of Service</h2>

          <div className="space-y-8 text-gray-300 leading-relaxed">
            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">1. Acceptance of Terms</h3>
              <p>
                By downloading, installing, or using PicSurg (&quot;the App&quot;), you agree to
                be bound by these Terms of Service. If you do not agree to these terms,
                do not use the App.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">2. Description of Service</h3>
              <p>
                PicSurg is an iOS application that uses machine learning to identify
                surgical and operative photos in your camera roll and stores them in an
                encrypted vault on your device. The App is designed for healthcare
                professionals who need to separate surgical documentation from personal
                photos.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">3. Eligibility</h3>
              <p>
                You must be at least 17 years old to use PicSurg. By using the App, you
                represent that you meet this age requirement.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">4. User Responsibilities</h3>
              <ul className="list-disc space-y-2 pl-6">
                <li>You are responsible for maintaining the security of your PIN and device</li>
                <li>You are responsible for any photos you choose to secure or delete</li>
                <li>You should maintain your own backups of important photos before securing them</li>
                <li>You must comply with all applicable laws and institutional policies regarding medical images</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">5. ML Classification Accuracy</h3>
              <p>
                The machine learning model provides automated photo classification with
                confidence scores. While designed for high accuracy, the model may produce
                false positives or false negatives. You should always review the results
                before confirming actions. PicSurg is not responsible for incorrect
                classifications.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">6. Limitation of Liability</h3>
              <p>
                PicSurg is provided &quot;as is&quot; without warranties of any kind. To the
                maximum extent permitted by law, we shall not be liable for any indirect,
                incidental, special, consequential, or punitive damages, including but not
                limited to loss of data, loss of photos, or inability to access your vault.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">7. No Medical Advice</h3>
              <p>
                PicSurg is a photo management tool. It does not provide medical advice,
                diagnosis, or treatment. The App does not analyze the medical content of
                photos — it only classifies whether a photo appears to be surgical in nature.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">8. Intellectual Property</h3>
              <p>
                The App, including its design, code, ML model, and branding, is the
                intellectual property of PicSurg. You may not reverse-engineer, decompile,
                or create derivative works based on the App.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">9. Termination</h3>
              <p>
                You may stop using PicSurg at any time by uninstalling the App.
                Uninstallation removes all locally stored data, including your encrypted
                vault. We recommend exporting any photos you wish to keep before
                uninstalling.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">10. Changes to Terms</h3>
              <p>
                We reserve the right to modify these Terms of Service at any time. Changes
                will be effective upon posting. Your continued use of the App after changes
                constitutes acceptance of the updated terms.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">11. Contact</h3>
              <p>
                For questions about these Terms of Service, please contact us at{" "}
                <a href="mailto:contact@picsurg.com" className="text-teal-light hover:underline">
                  contact@picsurg.com
                </a>.
              </p>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
