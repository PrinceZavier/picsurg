"use client";

import { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";

export default function LoginForm() {
  const [password, setPassword] = useState("");
  const [agreed, setAgreed] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!agreed) {
      setError("Please agree to the confidentiality terms before proceeding.");
      return;
    }
    setLoading(true);
    setError("");

    const res = await fetch("/api/demo-auth", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });

    if (res.ok) {
      router.refresh();
    } else {
      setError("Incorrect password. Please try again.");
      setPassword("");
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-white px-6">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex justify-center">
          <Image src="/logo.png" alt="PicSurg" width={64} height={64} className="rounded-2xl" />
        </div>
        <h1 className="mb-2 text-center text-2xl font-bold text-foreground">PicSurg Demo</h1>
        <p className="mb-8 text-center text-sm text-slate-500">
          This page is restricted to authorized reviewers only.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="password"
            value={password}
            onChange={(e) => { setPassword(e.target.value); setError(""); }}
            placeholder="Access password"
            autoFocus
            required
            className="w-full rounded-xl border border-foreground/10 bg-white px-4 py-3 text-foreground placeholder-slate-400 outline-none transition-colors focus:border-teal"
          />

          <div className="rounded-xl border border-foreground/10 bg-navy p-4">
            <label className="flex cursor-pointer items-start gap-3">
              <input
                type="checkbox"
                checked={agreed}
                onChange={(e) => { setAgreed(e.target.checked); setError(""); }}
                className="mt-0.5 h-4 w-4 shrink-0 accent-teal"
              />
              <span className="text-xs leading-relaxed text-slate-600">
                I acknowledge that this demonstration is confidential and proprietary to PicSurg.
                I agree not to share, reproduce, or distribute this content or any information
                contained herein without prior written consent.
              </span>
            </label>
          </div>

          {error && (
            <p className="text-center text-sm text-red-500">{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-teal py-3 font-semibold text-white transition-colors hover:bg-teal-light disabled:opacity-50"
          >
            {loading ? "Verifying..." : "Enter"}
          </button>
        </form>
      </div>
    </div>
  );
}
