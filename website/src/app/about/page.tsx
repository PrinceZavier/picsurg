import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";

export const metadata: Metadata = {
  title: "About — PicSurg",
  description: "Meet the team behind PicSurg.",
};

export default function AboutPage() {
  return (
    <div className="px-6 pt-32 pb-24">
      <div className="mx-auto max-w-4xl">
        {/* Header */}
        <div className="mb-16 text-center">
          <h1 className="mb-4 text-4xl font-bold text-white md:text-5xl">
            About PicSurg
          </h1>
          <p className="mx-auto max-w-2xl text-lg text-gray-400">
            Built at the intersection of design, engineering, and medicine.
          </p>
        </div>

        {/* Mission */}
        <div className="mb-16 rounded-2xl border border-white/10 bg-navy-light/50 p-8 md:p-10">
          <h2 className="mb-4 text-2xl font-bold text-white">Our Mission</h2>
          <p className="text-gray-300 leading-relaxed">
            PicSurg was born from a simple problem: surgical photos and personal photos
            shouldn&apos;t live in the same camera roll. Healthcare providers take operative
            photos daily for documentation, education, and patient care — but these
            sensitive images sit alongside personal memories with no separation or
            protection. PicSurg uses machine learning to automatically detect surgical
            photos and secure them in a HIPAA-compliant encrypted vault, giving
            healthcare professionals peace of mind.
          </p>
        </div>

        {/* Team */}
        <div>
          <h2 className="mb-8 text-center text-2xl font-bold text-white">The Team</h2>

          <div className="space-y-8">
            {/* Isabella */}
            <div className="rounded-2xl border border-white/10 bg-navy-light/50 p-8 md:p-10">
              <div className="flex flex-col gap-8 md:flex-row md:items-start">
                <Image
                  src="/headshot-isabella.jpg"
                  alt="Isabella Zorra"
                  width={200}
                  height={200}
                  className="h-48 w-48 shrink-0 rounded-2xl object-cover object-top"
                />
                <div>
                  <h3 className="mb-1 text-xl font-bold text-white">Isabella Zorra</h3>
                  <p className="mb-4 text-sm font-medium text-teal-light">Founder & Developer</p>
                  <p className="text-gray-300 leading-relaxed">
                    Isabella brings a uniquely interdisciplinary background to PicSurg,
                    spanning design, architecture, engineering, and project management.
                    She studied interdisciplinary design at Parsons School of Design and
                    sculpture at The School of the Art Institute of Chicago, where she
                    explored innovative fabrication methods including leather molding,
                    plaster casting, and laser cutting. She holds a B.Arch in Architecture
                    and an M.Eng in Construction Engineering and Management from Illinois
                    Institute of Technology.
                  </p>
                  <p className="mt-3 text-gray-300 leading-relaxed">
                    Her professional experience spans real estate development at Fifield
                    Companies and project management in the energy sector for Indianapolis
                    Power &amp; Light, Duke Energy, and TC Energy. Isabella is currently
                    part of the Innovation Medicine (IMED) program at the University of
                    Illinois College of Medicine, where she collaborates on
                    interdisciplinary teams to develop innovative solutions to medical
                    challenges — including PicSurg.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* CTA */}
        <div className="mt-16 text-center">
          <p className="mb-6 text-gray-400">
            Interested in collaborating or joining the team?
          </p>
          <Link
            href="/contact"
            className="inline-block rounded-full bg-teal px-8 py-3 font-semibold text-white transition-colors hover:bg-teal-light"
          >
            Get in Touch
          </Link>
        </div>
      </div>
    </div>
  );
}
