import { NextResponse } from "next/server";

const DEMO_PASSWORD = "PICSURGGRANT2026!";
const COOKIE_VALUE = "picsurg_demo_v1";
const ONE_YEAR = 60 * 60 * 24 * 365;

export async function POST(request: Request) {
  const { password } = await request.json();

  if (password !== DEMO_PASSWORD) {
    return NextResponse.json({ error: "Incorrect password" }, { status: 401 });
  }

  const response = NextResponse.json({ success: true });
  response.cookies.set("picsurg_demo_auth", COOKIE_VALUE, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: ONE_YEAR,
    path: "/",
  });

  return response;
}
