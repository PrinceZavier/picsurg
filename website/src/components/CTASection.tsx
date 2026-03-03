import Link from "next/link";

export default function CTASection() {
  return (
    <section className="px-6 py-24">
      <div className="relative mx-auto max-w-4xl overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-navy-light to-navy p-12 text-center md:p-16">
        {/* Background glow */}
        <div className="absolute top-0 right-0 h-64 w-64 rounded-full bg-teal/10 blur-[80px]" />
        <div className="absolute bottom-0 left-0 h-64 w-64 rounded-full bg-cyan/10 blur-[80px]" />

        <div className="relative z-10">
          <h2 className="mb-4 text-3xl font-bold text-white md:text-4xl">
            Ready to secure your surgical photos?
          </h2>
          <p className="mx-auto mb-8 max-w-xl text-gray-400">
            Join the beta to be among the first to try PicSurg. Available for
            iOS 16 and later.
          </p>
          <Link
            href="/contact"
            className="inline-block rounded-full bg-teal px-8 py-3.5 text-lg font-semibold text-white transition-all hover:bg-teal-light hover:shadow-lg hover:shadow-teal/25"
          >
            Request Beta Access
          </Link>
        </div>
      </div>
    </section>
  );
}
