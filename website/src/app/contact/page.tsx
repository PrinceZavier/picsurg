"use client";

import { useState, FormEvent } from "react";

const GOOGLE_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbxm-n1gcIHSiM-zDrkd9RTiVtPrIYNJU-bYC2kz5S4pRz1tk40wnUKAmOMSSK-4uyuAMg/exec";

export default function ContactPage() {
  const [status, setStatus] = useState<"idle" | "submitting" | "success" | "error">("idle");

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("submitting");

    const form = e.currentTarget;
    const data = {
      name: (form.elements.namedItem("name") as HTMLInputElement).value,
      email: (form.elements.namedItem("email") as HTMLInputElement).value,
      role: (form.elements.namedItem("role") as HTMLInputElement).value,
      message: (form.elements.namedItem("message") as HTMLTextAreaElement).value,
    };

    try {
      await fetch(GOOGLE_SCRIPT_URL, {
        method: "POST",
        mode: "no-cors",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      setStatus("success");
      form.reset();
    } catch {
      setStatus("error");
    }
  }

  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-16 text-center">
          <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">
            Get Early Access
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-gray-400">
            PicSurg is currently in beta. Sign up to be notified when it launches
            on the App Store, or reach out with questions.
          </p>
        </div>

        <div className="grid gap-12 md:grid-cols-2">
          {/* Beta signup form */}
          <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
            <h2 className="mb-6 text-2xl font-bold text-white">Request Beta Access</h2>

            {status === "success" ? (
              <div className="rounded-xl border border-teal/30 bg-teal/10 p-6 text-center">
                <svg className="mx-auto mb-3 h-10 w-10 text-teal" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
                <h3 className="mb-2 text-lg font-semibold text-white">You&apos;re on the list!</h3>
                <p className="text-gray-400">
                  Thanks for your interest in PicSurg. We&apos;ll be in touch soon.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <div>
                  <label htmlFor="name" className="mb-2 block text-sm font-medium text-gray-300">
                    Full Name
                  </label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    required
                    className="w-full rounded-xl border border-white/10 bg-navy px-4 py-3 text-white placeholder-gray-500 outline-none transition-colors focus:border-teal"
                    placeholder="Dr. Jane Smith"
                  />
                </div>
                <div>
                  <label htmlFor="email" className="mb-2 block text-sm font-medium text-gray-300">
                    Email Address
                  </label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    required
                    className="w-full rounded-xl border border-white/10 bg-navy px-4 py-3 text-white placeholder-gray-500 outline-none transition-colors focus:border-teal"
                    placeholder="jane@hospital.org"
                  />
                </div>
                <div>
                  <label htmlFor="role" className="mb-2 block text-sm font-medium text-gray-300">
                    Role / Specialty
                  </label>
                  <input
                    type="text"
                    id="role"
                    name="role"
                    className="w-full rounded-xl border border-white/10 bg-navy px-4 py-3 text-white placeholder-gray-500 outline-none transition-colors focus:border-teal"
                    placeholder="Orthopedic Surgeon"
                  />
                </div>
                <div>
                  <label htmlFor="message" className="mb-2 block text-sm font-medium text-gray-300">
                    Message (optional)
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    rows={3}
                    className="w-full resize-none rounded-xl border border-white/10 bg-navy px-4 py-3 text-white placeholder-gray-500 outline-none transition-colors focus:border-teal"
                    placeholder="Tell us about your use case..."
                  />
                </div>
                <button
                  type="submit"
                  disabled={status === "submitting"}
                  className="w-full rounded-xl bg-teal py-3 font-semibold text-white transition-colors hover:bg-teal-light disabled:opacity-50"
                >
                  {status === "submitting" ? "Submitting..." : "Request Access"}
                </button>
                {status === "error" && (
                  <p className="text-center text-sm text-red-400">
                    Something went wrong. Please try again or email us directly.
                  </p>
                )}
              </form>
            )}
          </div>

          {/* Contact info */}
          <div className="space-y-8">
            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
              <h2 className="mb-4 text-2xl font-bold text-white">Get in Touch</h2>
              <p className="mb-6 text-gray-400">
                Have questions about PicSurg? We&apos;d love to hear from you.
              </p>
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <div className="inline-flex rounded-lg bg-teal/10 p-2 text-teal">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                    </svg>
                  </div>
                  <a href="mailto:contact@picsurg.com" className="text-gray-300 hover:text-teal-light">
                    contact@picsurg.com
                  </a>
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
              <h2 className="mb-4 text-xl font-bold text-white">What to Expect</h2>
              <ul className="space-y-3 text-gray-400">
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Beta invites are sent on a rolling basis
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Healthcare professionals get priority access
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Requires iOS 16+ on iPhone
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Free during beta, no credit card required
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
