import type { Metadata } from "next";
import { cookies } from "next/headers";
import LoginForm from "./LoginForm";
import DemoContent from "./DemoContent";

export const metadata: Metadata = {
  title: "PicSurg Demo",
  robots: {
    index: false,
    follow: false,
  },
};

export default async function DemoPage() {
  const cookieStore = await cookies();
  const auth = cookieStore.get("picsurg_demo_auth");
  const isAuthenticated = auth?.value === "picsurg_demo_v1";

  if (!isAuthenticated) {
    return <LoginForm />;
  }

  return <DemoContent />;
}
