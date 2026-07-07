import { NextResponse } from "next/server";
import { getSessionUser, getToken } from "@/lib/session";

export async function GET() {
  const user = getSessionUser();
  const token = getToken();
  if (!user || !token) {
    return NextResponse.json({ user: null }, { status: 401 });
  }
  return NextResponse.json({ user });
}
