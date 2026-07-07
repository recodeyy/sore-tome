// Server-only session helpers. The access + refresh tokens live in httpOnly
// cookies so they are never readable from client JavaScript (XSS-resistant).
import "server-only";
import { cookies } from "next/headers";

export const TOKEN_COOKIE = "sero_token";
export const REFRESH_COOKIE = "sero_refresh";
export const USER_COOKIE = "sero_user"; // non-httpOnly: safe display fields only

export type SessionUser = {
  uid: string;
  name: string;
  role: string;
  society_id: string | null;
  portal: string;
  phone?: string;
};

const secureCookie = process.env.NODE_ENV === "production";

export function setSession(
  token: string,
  refreshToken: string,
  user: SessionUser
) {
  const jar = cookies();
  const base = {
    httpOnly: true,
    secure: secureCookie,
    sameSite: "lax" as const,
    path: "/",
  };
  jar.set(TOKEN_COOKIE, token, { ...base, maxAge: 60 * 60 });
  jar.set(REFRESH_COOKIE, refreshToken, { ...base, maxAge: 60 * 60 * 24 * 7 });
  // Display-only user context readable by the client for the shell/nav.
  jar.set(USER_COOKIE, JSON.stringify(user), {
    httpOnly: false,
    secure: secureCookie,
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 7,
  });
}

export function clearSession() {
  const jar = cookies();
  jar.delete(TOKEN_COOKIE);
  jar.delete(REFRESH_COOKIE);
  jar.delete(USER_COOKIE);
}

export function getToken(): string | null {
  return cookies().get(TOKEN_COOKIE)?.value ?? null;
}

export function getRefreshToken(): string | null {
  return cookies().get(REFRESH_COOKIE)?.value ?? null;
}

export function getSessionUser(): SessionUser | null {
  const raw = cookies().get(USER_COOKIE)?.value;
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionUser;
  } catch {
    return null;
  }
}
