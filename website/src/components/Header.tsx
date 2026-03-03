"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 border-b border-white/10 bg-background/80 backdrop-blur-md">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-3">
          <Image src="/icon.png" alt="PicSurg" width={36} height={36} className="rounded-lg" />
          <span className="text-xl font-bold text-white">PicSurg</span>
        </Link>

        {/* Desktop nav */}
        <div className="hidden items-center gap-8 md:flex">
          <Link href="/" className="text-sm text-gray-300 transition-colors hover:text-teal-light">
            Home
          </Link>
          <Link href="/security" className="text-sm text-gray-300 transition-colors hover:text-teal-light">
            Security & Legal
          </Link>
          <Link
            href="/contact"
            className="rounded-full bg-teal px-5 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-light"
          >
            Join Beta
          </Link>
        </div>

        {/* Mobile hamburger */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="flex flex-col gap-1.5 md:hidden"
          aria-label="Toggle menu"
        >
          <span className={`h-0.5 w-6 bg-white transition-transform ${menuOpen ? "translate-y-2 rotate-45" : ""}`} />
          <span className={`h-0.5 w-6 bg-white transition-opacity ${menuOpen ? "opacity-0" : ""}`} />
          <span className={`h-0.5 w-6 bg-white transition-transform ${menuOpen ? "-translate-y-2 -rotate-45" : ""}`} />
        </button>
      </nav>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="border-t border-white/10 bg-background/95 backdrop-blur-md md:hidden">
          <div className="flex flex-col gap-4 px-6 py-6">
            <Link href="/" onClick={() => setMenuOpen(false)} className="text-gray-300 hover:text-teal-light">
              Home
            </Link>
            <Link href="/security" onClick={() => setMenuOpen(false)} className="text-gray-300 hover:text-teal-light">
              Security & Legal
            </Link>
            <Link
              href="/contact"
              onClick={() => setMenuOpen(false)}
              className="mt-2 rounded-full bg-teal px-5 py-2 text-center text-sm font-semibold text-white"
            >
              Join Beta
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
