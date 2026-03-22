import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-white/10 bg-navy">
      <div className="mx-auto max-w-6xl px-6 py-12">
        <div className="grid gap-8 md:grid-cols-3">
          <div>
            <h3 className="mb-3 text-lg font-bold text-white">PicSurg</h3>
            <p className="text-sm text-gray-400">
              ML-powered surgical photo detection with privacy-aware encrypted storage.
            </p>
          </div>
          <div>
            <h4 className="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-400">Pages</h4>
            <div className="flex flex-col gap-2">
              <Link href="/" className="text-sm text-gray-300 hover:text-teal-light">Home</Link>
              <Link href="/security" className="text-sm text-gray-300 hover:text-teal-light">Security</Link>
              <Link href="/contact" className="text-sm text-gray-300 hover:text-teal-light">Contact & Beta</Link>
            </div>
          </div>
          <div>
            <h4 className="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-400">Legal</h4>
            <div className="flex flex-col gap-2">
              <Link href="/security#privacy" className="text-sm text-gray-300 hover:text-teal-light">Privacy Policy</Link>
              <Link href="/security#terms" className="text-sm text-gray-300 hover:text-teal-light">Terms of Service</Link>
            </div>
          </div>
        </div>
        <div className="mt-10 border-t border-white/10 pt-6 text-center text-sm text-gray-500">
          &copy; {new Date().getFullYear()} PicSurg. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
