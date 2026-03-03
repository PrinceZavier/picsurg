import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Security & Privacy — PicSurg",
  description: "How PicSurg protects your surgical photos with AES-256 encryption, biometric authentication, and HIPAA-compliant design.",
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
      "All photo analysis happens entirely on your device using Apple's Core ML framework",
      "No images are ever sent to external servers or cloud services",
      "The trained ML model runs locally — no internet connection required",
      "Photo classification takes approximately 50ms per image on modern iPhones",
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
      "Every photo is individually encrypted using AES-256-GCM — the same standard used by governments and financial institutions",
      "A unique random 96-bit nonce is generated for each encryption operation",
      "Encryption keys are generated on first launch and stored securely in the iOS Keychain",
      "Keys are protected with WhenUnlockedThisDeviceOnly access control — they never leave your device",
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
      "Face ID and Touch ID provide fast, secure biometric authentication",
      "6-digit PIN serves as a fallback when biometrics are unavailable",
      "The app automatically locks when backgrounded — every session requires fresh authentication",
      "Failed attempt protection with exponential lockout (1 min, 5 min, 15 min, 1 hour)",
      "PIN recovery available via verified email with time-limited codes",
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
      "All data stays on your device — PicSurg has no servers, no cloud storage, no analytics",
      "Vault directory is excluded from iCloud and iTunes backups by default",
      "Photos are only deleted from your camera roll after successful vault encryption",
      "You can restore photos to your camera roll or share via AirDrop at any time",
      "Full data deletion available in Settings — wipe everything with one tap",
    ],
  },
  {
    title: "HIPAA-Compliant Design",
    icon: (
      <svg className="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z" />
      </svg>
    ),
    items: [
      "Designed to support HIPAA Security Rule requirements for Protected Health Information (PHI)",
      "No data transmission eliminates network-based attack vectors entirely",
      "Access controls ensure only authenticated users can view secured photos",
      "Activity logging tracks scan, secure, delete, share, and restore operations",
      "Zero third-party dependencies — built entirely on Apple's first-party frameworks",
    ],
  },
];

export default function SecurityPage() {
  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-16 text-center">
          <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">
            Security & Privacy
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-gray-400">
            PicSurg was designed from the ground up with security as a core principle.
            Here&apos;s exactly how your photos are protected.
          </p>
        </div>

        {/* Security sections */}
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
