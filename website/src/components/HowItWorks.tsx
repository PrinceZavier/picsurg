const steps = [
  {
    number: "01",
    title: "Scan",
    description: "Tap the scan button and PicSurg analyzes your camera roll using an on-device ML model to detect surgical photos.",
  },
  {
    number: "02",
    title: "Review",
    description: "Review the identified photos with confidence scores. Select which ones you want to secure — you're always in control.",
  },
  {
    number: "03",
    title: "Secure",
    description: "Selected photos are encrypted with AES-256-GCM and moved to your vault. Originals are removed from your camera roll.",
  },
];

export default function HowItWorks() {
  return (
    <section className="px-6 py-24">
      <div className="mx-auto max-w-6xl">
        <div className="mb-16 text-center">
          <h2 className="mb-4 text-3xl font-bold text-white md:text-4xl">
            How it works
          </h2>
          <p className="mx-auto max-w-2xl text-gray-400">
            Three simple steps to separate your surgical photos from your personal library.
          </p>
        </div>

        <div className="grid gap-8 md:grid-cols-3">
          {steps.map((step, index) => (
            <div key={step.number} className="relative text-center">
              {/* Connector line */}
              {index < steps.length - 1 && (
                <div className="absolute top-10 left-[60%] hidden h-0.5 w-[80%] bg-gradient-to-r from-teal/50 to-transparent md:block" />
              )}
              <div className="mb-6 inline-flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-teal to-cyan text-2xl font-bold text-white">
                {step.number}
              </div>
              <h3 className="mb-3 text-xl font-semibold text-white">{step.title}</h3>
              <p className="text-gray-400">{step.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
