import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Security & Legal | PicSurg",
  description: "How PicSurg protects your surgical photos with AES-256 encryption, biometric authentication, and privacy-aware design. Plus our Privacy Policy and Terms of Service.",
};

const sections = [
  {
    title: "On-Device ML Processing",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 3v1.5M4.5 8.25H3m18 0h-1.5M4.5 12H3m18 0h-1.5m-15 3.75H3m18 0h-1.5M8.25 19.5V21M12 3v1.5m0 15V21m3.75-18v1.5m0 15V21m-9-1.5h10.5a2.25 2.25 0 0 0 2.25-2.25V6.75a2.25 2.25 0 0 0-2.25-2.25H6.75A2.25 2.25 0 0 0 4.5 6.75v10.5a2.25 2.25 0 0 0 2.25 2.25Z" />
      </svg>
    ),
    items: [
      "All photo analysis happens entirely on your device. No images are ever sent externally",
      "The ML model runs locally with no internet connection required",
      "Photo classification takes milliseconds per image on modern iPhones",
    ],
  },
  {
    title: "AES-256-GCM Encryption",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" />
      </svg>
    ),
    items: [
      "Every photo is individually encrypted using AES-256-GCM, the same standard used by governments and financial institutions",
      "Encryption keys are securely stored in the iOS Keychain and never leave your device",
      "Each encryption operation uses a unique random value, so no two encrypted files are alike",
    ],
  },
  {
    title: "Biometric & PIN Authentication",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M7.864 4.243A7.5 7.5 0 0 1 19.5 10.5c0 2.92-.556 5.709-1.568 8.268M5.742 6.364A7.465 7.465 0 0 0 4.5 10.5a48.667 48.667 0 0 0-1.26 8.303M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm-1.5 0a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Z" />
      </svg>
    ),
    items: [
      "Face ID and Touch ID with a 6-digit PIN fallback",
      "Auto-locks when backgrounded, requiring fresh authentication every session",
      "Built-in lockout and recovery features protect against unauthorized access",
    ],
  },
  {
    title: "Data Handling & Storage",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125" />
      </svg>
    ),
    items: [
      "Photos never leave your device. No servers, no cloud storage",
      "Vault excluded from iCloud and iTunes backups by default",
      "Anonymous usage analytics contain no photos or identifiable data",
    ],
  },
  {
    title: "Privacy-Aware Design",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" />
      </svg>
    ),
    items: [
      "Designed with healthcare data privacy as a core principle",
      "No PHI is ever transmitted. Patient photos and data stay on your device",
      "Built primarily on Apple first-party frameworks for security and reliability",
    ],
  },
];

export default function SecurityPage() {
  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">
            Security & Legal
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-gray-400">
            PicSurg was designed from the ground up with security as a core principle.
            Here&apos;s exactly how your photos are protected.
          </p>
        </div>

        {/* Page nav */}
        <div className="mb-16 flex flex-wrap justify-center gap-3">
          <a href="#security" className="rounded-full border border-white/10 px-5 py-2 text-sm text-gray-300 transition-colors hover:border-teal hover:text-teal-light">
            Security
          </a>
          <a href="#privacy" className="rounded-full border border-white/10 px-5 py-2 text-sm text-gray-300 transition-colors hover:border-teal hover:text-teal-light">
            Privacy Policy
          </a>
          <a href="#terms" className="rounded-full border border-white/10 px-5 py-2 text-sm text-gray-300 transition-colors hover:border-teal hover:text-teal-light">
            Terms of Service
          </a>
        </div>

        {/* Security sections */}
        <section id="security" className="scroll-mt-24">
          <div className="space-y-12">
            {sections.map((section) => (
              <div
                key={section.title}
                className="rounded-2xl border border-white/10 bg-navy-light/50 p-8"
              >
                <div className="mb-4 flex items-center gap-3">
                  <div className="inline-flex rounded-xl bg-teal/10 p-2.5 text-teal">
                    {section.icon}
                  </div>
                  <h2 className="text-2xl font-bold text-white">{section.title}</h2>
                </div>
                <ul className="space-y-3">
                  {section.items.map((item, index) => (
                    <li key={index} className="flex items-start gap-3 text-gray-300">
                      <svg className="mt-1.5 h-4 w-4 shrink-0 text-teal" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z" clipRule="evenodd" />
                      </svg>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        {/* Divider */}
        <hr className="my-20 border-white/10" />

        {/* Privacy Policy */}
        <section id="privacy" className="mb-20 scroll-mt-24">
          <p className="mb-2 text-sm text-gray-500">Last updated: March 2026</p>
          <h2 className="mb-8 text-3xl font-bold text-white">Privacy Policy</h2>

          <div className="space-y-8 text-gray-300 leading-relaxed">
            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">1. Introduction</h3>
              <p>
                PicSurg (&quot;we&quot;, &quot;our&quot;, or &quot;the App&quot;) is committed to protecting
                your privacy. This Privacy Policy explains how we handle information when
                you use our iOS application. PicSurg is designed with a privacy-first
                approach where all data processing occurs on your device.
              </p>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">2. Information We Collect</h3>
              <p className="mb-3">
                <strong className="text-white">We do not collect, transmit, or store any photos or personal health data on external servers.</strong>
              </p>
              <p className="mb-3">The App processes the following data locally on your device:</p>
              <ul className="list-disc space-y-2 pl-6">
                <li><strong className="text-white">Photos:</strong> The App accesses your photo library (with your permission) to analyze images using an on-device machine learning model. Photos identified as surgical are encrypted and stored locally in an encrypted vault.</li>
                <li><strong className="text-white">Authentication data:</strong> Your PIN hash, biometric enrollment preferences, and optional recovery email are stored in the iOS Keychain on your device.</li>
                <li><strong className="text-white">App preferences:</strong> Settings such as scan history and onboarding status are stored locally using iOS UserDefaults.</li>
              </ul>
              <p className="mt-3">The App also sends anonymous usage analytics to help us improve the product:</p>
              <ul className="mt-3 list-disc space-y-2 pl-6">
                <li><strong className="text-white">Anonymous analytics:</strong> Feature usage counts (e.g. number of scans, photos secured), durations, and success/failure status. No photos, filenames, patient data, or personally identifiable information is ever included.</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">3. How We Use Your Information</h3>
              <p>All photo processing occurs on-device. Your data is used for:</p>
              <ul className="mt-3 list-disc space-y-2 pl-6">
                <li>Classifying photos as surgical or non-surgical using the on-device ML model</li>
                <li>Encrypting and securely storing selected photos in your local vault</li>
                <li>Authenticating you via Face ID, Touch ID, or PIN</li>
                <li>Sending anonymous usage analytics to improve the app (no photos or personal data included)</li>
              </ul>
            </div>

            <div>
              <h3 className="mb-3 text-xl font-semibold text-white">4. Data Sharing</h3>
              <p>
                We do not share, sell, or transmit any photos or personal health data to
                third parties. The App sends anonymous usage analytics (e.g. feature usage
                counts, scan durations) to help us improve the product. This data contains
                no photos, patient information, or personally identifiable information.
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
              <h3 className="mb-3 text-xl font-semibold text-white">6. Healthcare Privacy</h3>
              <p>
                PicSurg is a photo management tool designed with healthcare data privacy
                in mind. All photos and health-related data remain on your device and are
                never transmitted externally. The only network activity is anonymous usage
                analytics, which contains no patient data. PicSurg is not itself a
                regulatory compliance solution. Healthcare providers are responsible for
                ensuring their own compliance and should consult their compliance officers
                regarding institutional policies.
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
          <p className="mb-2 text-sm text-gray-500">Last updated: March 2026</p>
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
                photos. It only classifies whether a photo appears to be surgical in nature.
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

        {/* CTA */}
        <div className="mt-16 text-center">
          <p className="mb-6 text-gray-400">
            Have questions about our security approach?
          </p>
          <Link
            href="/contact"
            className="inline-block rounded-full bg-teal px-8 py-3 font-semibold text-white transition-colors hover:bg-teal-light"
          >
            Contact Us
          </Link>
        </div>
      </div>
    </div>
  );
}
