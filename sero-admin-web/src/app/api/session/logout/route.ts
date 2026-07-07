import { NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { clearSession, getRefreshToken, getToken } from "@/lib/session";

export async function POST() {
  const refreshToken = getRefreshToken();
  const token = getToken();
  // Best-effort backend revocation; never block logout on it.
  if (refreshToken) {
    try {
      await backendFetch("/auth/logout", {
        method: "POST",
        token,
        body: JSON.stringify({ refreshToken }),
      });
    } catch {
      /* ignore */
    }
  }
  clearSession();
  return NextResponse.json({ ok: true });
}
