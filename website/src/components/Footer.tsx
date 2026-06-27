import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-foreground/10 bg-navy">
      <div className="mx-auto max-w-6xl px-6 py-12">
        <div className="grid gap-8 md:grid-cols-3">
          <div>
            <h3 className="mb-3 text-lg font-bold text-foreground">PicSurg™</h3>
            <p className="text-sm text-slate-500">
              ML-powered surgical photo detection with privacy-aware encrypted storage.
            </p>
          </div>
          <div>
            <h4 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">Pages</h4>
            <div className="flex flex-col gap-2">
              <Link href="/" className="text-sm text-slate-600 hover:text-teal">Home</Link>
              <Link href="/security" className="text-sm text-slate-600 hover:text-teal">Security</Link>
              <Link href="/contact" className="text-sm text-slate-600 hover:text-teal">Contact & Beta</Link>
            </div>
          </div>
          <div>
            <h4 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">Legal</h4>
            <div className="flex flex-col gap-2">
              <Link href="/security#privacy" className="text-sm text-slate-600 hover:text-teal">Privacy Policy</Link>
              <Link href="/security#terms" className="text-sm text-slate-600 hover:text-teal">Terms of Service</Link>
            </div>
          </div>
        </div>
        <div className="mt-10 border-t border-foreground/10 pt-6 text-center text-sm text-slate-400">
          &copy; {new Date().getFullYear()} PicSurg™. All rights reserved.
        </div>
      </div>
    </footer>
  );
}
