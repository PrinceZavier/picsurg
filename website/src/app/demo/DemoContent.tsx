"use client";

import { useEffect, useRef } from "react";
import Image from "next/image";

export default function DemoContent() {
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    function handleVisibilityChange() {
      if (document.hidden && videoRef.current) {
        videoRef.current.pause();
      }
    }
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, []);

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

        {/* Video with watermark overlay */}
        <div className="flex justify-center">
        <div className="relative w-full max-w-xs overflow-hidden rounded-2xl border border-foreground/10 bg-black">
          <video
            ref={videoRef}
            controls
            controlsList="nodownload"
            className="w-full"
            preload="metadata"
            onContextMenu={(e) => e.preventDefault()}
          >
            <source src="/picsurg_demo_final.mp4" type="video/mp4" />
            Your browser does not support the video tag.
          </video>

          {/* Watermark overlay */}
          <div
            className="pointer-events-none absolute inset-0 flex justify-center select-none"
            style={{ paddingTop: "12%" }}
            aria-hidden
          >
            <p
              className="whitespace-nowrap text-[8px] font-semibold tracking-[0.15em] text-foreground"
              style={{ opacity: 0.18 }}
            >
              CONFIDENTIAL · GRANT REVIEW ONLY · PICSURG
            </p>
          </div>
        </div>
        </div>

        {/* Footer */}
        <p className="mt-6 text-center text-xs text-slate-400">
          PicSurg is currently in beta. Learn more at{" "}
          <a href="https://picsurg.com" className="text-teal hover:underline">picsurg.com</a>
        </p>
        <p className="mt-3 text-center text-xs text-slate-400">
          © {new Date().getFullYear()} PicSurg. All rights reserved. This technology and its implementation
          are proprietary and confidential. Unauthorized reproduction or distribution is prohibited.
        </p>
      </div>
    </div>
  );
}
