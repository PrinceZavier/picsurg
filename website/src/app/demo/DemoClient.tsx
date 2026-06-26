"use client";

import { useState, useEffect } from "react";
import Image from "next/image";

const PASSWORD = "PICSURGGRANT2026!";
const SESSION_KEY = "picsurg_demo_auth";

export default function DemoClient() {
  const [authenticated, setAuthenticated] = useState(false);
  const [input, setInput] = useState("");
  const [error, setError] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    if (sessionStorage.getItem(SESSION_KEY) === "true") {
      setAuthenticated(true);
    }
    setChecking(false);
  }, []);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (input === PASSWORD) {
      sessionStorage.setItem(SESSION_KEY, "true");
      setAuthenticated(true);
      setError(false);
    } else {
      setError(true);
      setInput("");
    }
  }

  if (checking) return null;

  if (!authenticated) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-white px-6">
        <div className="w-full max-w-sm">
          <div className="mb-8 flex justify-center">
            <Image src="/logo.png" alt="PicSurg" width={64} height={64} className="rounded-2xl" />
          </div>
          <h1 className="mb-2 text-center text-2xl font-bold text-foreground">PicSurg Demo</h1>
          <p className="mb-8 text-center text-sm text-slate-500">Enter the access password to continue.</p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <input
              type="password"
              value={input}
              onChange={(e) => { setInput(e.target.value); setError(false); }}
              placeholder="Password"
              autoFocus
              className="w-full rounded-xl border border-foreground/10 bg-white px-4 py-3 text-foreground placeholder-slate-400 outline-none transition-colors focus:border-teal"
            />
            {error && (
              <p className="text-center text-sm text-red-500">Incorrect password. Please try again.</p>
            )}
            <button
              type="submit"
              className="w-full rounded-xl bg-teal py-3 font-semibold text-white transition-colors hover:bg-teal-light"
            >
              Enter
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white px-6 py-12">
      <div className="mx-auto max-w-2xl">
        {/* Header */}
        <div className="mb-10 flex items-center gap-3">
          <Image src="/logo.png" alt="PicSurg" width={40} height={40} className="rounded-xl" />
          <span className="text-lg font-bold text-foreground">PicSurg</span>
        </div>

        {/* Confidential notice */}
        <div className="mb-8 rounded-2xl border border-foreground/10 bg-navy p-6">
          <p className="text-sm leading-relaxed text-slate-600">
            <span className="font-semibold text-foreground">PicSurg — Confidential Demo for Grant Review.</span>{" "}
            This demonstration shows PicSurg&apos;s core functionality: ML-powered detection of surgical
            photos and secure vaulting. Intended for grant evaluation purposes only.
          </p>
        </div>

        {/* Video */}
        <div className="overflow-hidden rounded-2xl border border-foreground/10 bg-black">
          <video
            controls
            className="w-full"
            preload="metadata"
          >
            <source src="/picsurg_demo_final.mp4" type="video/mp4" />
            Your browser does not support the video tag.
          </video>
        </div>

        {/* Footer note */}
        <p className="mt-8 text-center text-sm text-slate-400">
          PicSurg is currently in beta. Learn more at{" "}
          <a href="https://picsurg.com" className="text-teal hover:underline">
            picsurg.com
          </a>
        </p>
      </div>
    </div>
  );
}
