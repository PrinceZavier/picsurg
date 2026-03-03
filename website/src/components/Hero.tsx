import Link from "next/link";
import Image from "next/image";

export default function Hero() {
  return (
    <section className="relative flex min-h-screen items-center justify-center overflow-hidden px-6 pt-20">
      {/* Abstract grid background */}
      <div className="absolute inset-0 opacity-[0.07]">
        <svg className="h-full w-full" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="grid" width="60" height="60" patternUnits="userSpaceOnUse">
              <path d="M 60 0 L 0 0 0 60" fill="none" stroke="currentColor" strokeWidth="0.5" className="text-teal" />
            </pattern>
            <radialGradient id="grid-fade" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="white" stopOpacity="1" />
              <stop offset="100%" stopColor="white" stopOpacity="0" />
            </radialGradient>
            <mask id="grid-mask">
              <rect width="100%" height="100%" fill="url(#grid-fade)" />
            </mask>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" mask="url(#grid-mask)" />
        </svg>
      </div>

      {/* Floating abstract shapes */}
      <div className="absolute top-[15%] left-[10%] h-72 w-72 rounded-full border border-teal/10 opacity-30" />
      <div className="absolute top-[20%] left-[12%] h-56 w-56 rounded-full border border-cyan/10 opacity-20" />
      <div className="absolute bottom-[20%] right-[8%] h-96 w-96 rounded-full border border-teal/10 opacity-20" />
      <div className="absolute bottom-[25%] right-[12%] h-64 w-64 rounded-full border border-cyan/10 opacity-15" />
      <div className="absolute top-[60%] left-[5%] h-40 w-40 rotate-45 rounded-2xl border border-teal/10 opacity-20" />
      <div className="absolute top-[10%] right-[15%] h-32 w-32 rotate-12 rounded-2xl border border-cyan/10 opacity-15" />

      {/* Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
        <div className="h-[500px] w-[500px] rounded-full bg-teal/20 blur-[120px]" />
      </div>

      <div className="relative z-10 mx-auto max-w-4xl text-center">
        {/* Logo */}
        <div className="mb-8 flex justify-center">
          <div className="relative">
            <div className="absolute inset-0 rounded-3xl bg-teal/30 blur-2xl" />
            <Image
              src="/logo.png"
              alt="PicSurg"
              width={100}
              height={100}
              className="relative rounded-3xl"
              priority
            />
          </div>
        </div>

        <h1 className="mb-6 text-5xl font-bold leading-tight tracking-tight text-white md:text-7xl">
          Your surgical photos,{" "}
          <span className="bg-gradient-to-r from-teal to-cyan bg-clip-text text-transparent">
            secured automatically
          </span>
        </h1>

        <p className="mx-auto mb-10 max-w-2xl text-lg text-gray-400 md:text-xl">
          PicSurg uses machine learning to detect operative photos in your camera roll
          and locks them in a HIPAA-compliant encrypted vault — so your personal and
          professional photos stay separate.
        </p>

        <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
          <Link
            href="/contact"
            className="rounded-full bg-teal px-8 py-3.5 text-lg font-semibold text-white transition-all hover:bg-teal-light hover:shadow-lg hover:shadow-teal/25"
          >
            Join the Beta
          </Link>
          <Link
            href="/security"
            className="rounded-full border border-white/20 px-8 py-3.5 text-lg font-semibold text-white transition-colors hover:border-teal hover:text-teal-light"
          >
            How It&apos;s Secured
          </Link>
        </div>

        <p className="mt-8 text-sm text-gray-500">
          Coming soon to the App Store &middot; iOS 16+
        </p>
      </div>
    </section>
  );
}
