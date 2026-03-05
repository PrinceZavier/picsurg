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
      role: (form.elements.namedItem("role") as HTMLSelectElement).value,
      practice: (form.elements.namedItem("practice") as HTMLSelectElement).value,
      specialty: (form.elements.namedItem("specialty") as HTMLSelectElement).value,
      message: (form.elements.namedItem("message") as HTMLTextAreaElement).value,
      focusGroupConsent: "Yes",
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

  const selectClasses =
    "w-full appearance-none rounded-xl border border-white/10 bg-navy px-4 py-3 text-white outline-none transition-colors focus:border-teal";

  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-16 text-center">
          <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">
            Join the PicSurg Beta
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-gray-400">
            Get free early access to PicSurg in exchange for your feedback.
            Beta users participate in a short focus group survey after using the
            app to help us build a better product for surgeons.
          </p>
        </div>

        <div className="grid gap-12 md:grid-cols-2">
          {/* Beta signup form — shows second on mobile, first (left) on desktop */}
          <div className="order-2 rounded-2xl border border-white/10 bg-navy-light/50 p-8 md:order-1">
            <h2 className="mb-6 text-2xl font-bold text-white">Request Beta Access</h2>

            {status === "success" ? (
              <div className="rounded-xl border border-teal/30 bg-teal/10 p-6 text-center">
                <svg className="mx-auto mb-3 h-10 w-10 text-teal" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
                <h3 className="mb-2 text-lg font-semibold text-white">You&apos;re on the list!</h3>
                <p className="text-gray-400">
                  Thanks for joining the PicSurg beta. We&apos;ll send you a
                  TestFlight invite soon. After you&apos;ve had time to use the
                  app, we&apos;ll follow up with a short feedback survey.
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
                    Current Role
                  </label>
                  <select id="role" name="role" required className={selectClasses}>
                    <option value="" disabled selected hidden>Select your role</option>
                    <option value="Medical Student">Medical Student</option>
                    <option value="Resident">Resident</option>
                    <option value="Fellow">Fellow</option>
                    <option value="Attending">Attending</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
                <div>
                  <label htmlFor="practice" className="mb-2 block text-sm font-medium text-gray-300">
                    Practice Setting
                  </label>
                  <select id="practice" name="practice" required className={selectClasses}>
                    <option value="" disabled selected hidden>Select practice setting</option>
                    <option value="Private">Private Practice</option>
                    <option value="Academic">Academic</option>
                    <option value="Mixed">Mixed</option>
                  </select>
                </div>
                <div>
                  <label htmlFor="specialty" className="mb-2 block text-sm font-medium text-gray-300">
                    Specialty / Subspecialty
                  </label>
                  <select id="specialty" name="specialty" className={selectClasses}>
                    <option value="" disabled selected hidden>Select your specialty</option>
                    <option value="Aesthetic / Cosmetic">Aesthetic / Cosmetic</option>
                    <option value="Breast">Breast</option>
                    <option value="Burn">Burn</option>
                    <option value="Craniofacial">Craniofacial</option>
                    <option value="Facial Plastics">Facial Plastics</option>
                    <option value="Hand">Hand</option>
                    <option value="Microsurgery">Microsurgery</option>
                    <option value="Oculoplastics">Oculoplastics</option>
                    <option value="Pediatric">Pediatric</option>
                    <option value="Reconstructive">Reconstructive</option>
                    <option value="Wound Care">Wound Care</option>
                    <option value="General Plastic Surgery">General Plastic Surgery</option>
                    <option value="Other">Other</option>
                  </select>
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

                {/* Focus group consent */}
                <div className="rounded-xl border border-white/10 bg-navy/50 p-4">
                  <label className="flex items-start gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      name="focusGroupConsent"
                      required
                      className="mt-1 h-4 w-4 shrink-0 accent-teal"
                    />
                    <span className="text-sm text-gray-300">
                      I understand that beta access includes participation in a
                      short feedback survey after using PicSurg. This helps us
                      improve the app for surgeons like me.{" "}
                      <span className="text-gray-500">Required</span>
                    </span>
                  </label>
                </div>

                <button
                  type="submit"
                  disabled={status === "submitting"}
                  className="w-full rounded-xl bg-teal py-3 font-semibold text-white transition-colors hover:bg-teal-light disabled:opacity-50"
                >
                  {status === "submitting" ? "Submitting..." : "Join Beta & Focus Group"}
                </button>
                {status === "error" && (
                  <p className="text-center text-sm text-red-400">
                    Something went wrong. Please try again or email us directly.
                  </p>
                )}
              </form>
            )}
          </div>

          {/* Sidebar info — shows first on mobile, second (right) on desktop */}
          <div className="order-1 space-y-8 md:order-2">
            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
              <h2 className="mb-4 text-2xl font-bold text-white">How It Works</h2>
              <ol className="space-y-4 text-gray-400">
                <li className="flex items-start gap-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-teal/20 text-xs font-bold text-teal">1</span>
                  <span><span className="font-medium text-white">Sign up</span> — fill out this form to request access</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-teal/20 text-xs font-bold text-teal">2</span>
                  <span><span className="font-medium text-white">Get the app</span> — receive a TestFlight invite via email</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-teal/20 text-xs font-bold text-teal">3</span>
                  <span><span className="font-medium text-white">Use PicSurg</span> — try it in your workflow for a few weeks</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-teal/20 text-xs font-bold text-teal">4</span>
                  <span><span className="font-medium text-white">Give feedback</span> — complete a short survey about your experience</span>
                </li>
              </ol>
            </div>

            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
              <h2 className="mb-4 text-xl font-bold text-white">What You Get</h2>
              <ul className="space-y-3 text-gray-400">
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Free access to PicSurg during beta
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Direct influence on the product roadmap
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Priority access when the app launches publicly
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-0.5 inline-block h-2 w-2 shrink-0 rounded-full bg-teal" />
                  Requires iOS 16+ on iPhone
                </li>
              </ul>
            </div>

            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8">
              <h2 className="mb-4 text-xl font-bold text-white">Get in Touch</h2>
              <p className="mb-4 text-gray-400">
                Have questions? Reach out directly.
              </p>
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
        </div>
      </div>
    </div>
  );
}
