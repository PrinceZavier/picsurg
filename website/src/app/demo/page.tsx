import type { Metadata } from "next";
import DemoClient from "./DemoClient";

export const metadata: Metadata = {
  title: "PicSurg Demo",
  robots: {
    index: false,
    follow: false,
  },
};

export default function DemoPage() {
  return <DemoClient />;
}
