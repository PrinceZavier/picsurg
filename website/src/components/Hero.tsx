import Link from "next/link";
import Image from "next/image";

export default function Hero() {
  return (
    <section className="relative flex min-h-screen items-center justify-center overflow-hidden px-6 pt-20">
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
