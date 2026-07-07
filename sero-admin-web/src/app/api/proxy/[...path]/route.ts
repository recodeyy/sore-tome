import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { backendFetch } from "@/lib/backend";
import {
  TOKEN_COOKIE,
  REFRESH_COOKIE,
  getToken,
  getRefreshToken,
} from "@/lib/session";

// Generic authenticated proxy: browser -> /api/proxy/<backend-path> -> backend.
// The access token lives in an httpOnly cookie and is attached server-side.
// On 401 it transparently rotates the refresh token once and retries.

async function tryRefresh(): Promise<string | null> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return null;
  const res = await backendFetch("/auth/refresh", {
    method: "POST",
    body: JSON.stringify({ refreshToken }),
  });
  if (!res.ok) return null;
  const body = res.body as any;
  const newToken = body?.token;
  const newRefresh = body?.refreshToken;
  if (!newToken) return null;
  const jar = cookies();
  const secure = process.env.NODE_ENV === "production";
  jar.set(TOKEN_COOKIE, newToken, {
    httpOnly: true,
    secure,
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60,
  });
  if (newRefresh) {
    jar.set(REFRESH_COOKIE, newRefresh, {
      httpOnly: true,
      secure,
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 7,
    });
  }
  return newToken;
}

async function handle(req: NextRequest, ctx: { params: { path: string[] } }) {
  const token = getToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const search = req.nextUrl.search || "";
  const path = "/" + ctx.params.path.join("/") + search;
  const method = req.method;
  const hasBody = !["GET", "HEAD"].includes(method);
  const rawBody = hasBody ? await req.text() : undefined;

  let result = await backendFetch(path, {
    method,
    token,
    body: rawBody,
    headers: hasBody ? { "Content-Type": "application/json" } : undefined,
  });

  if (result.status === 401) {
    const newToken = await tryRefresh();
    if (newToken) {
      result = await backendFetch(path, {
        method,
        token: newToken,
        body: rawBody,
        headers: hasBody ? { "Content-Type": "application/json" } : undefined,
      });
    }
  }

  return NextResponse.json(result.body ?? {}, { status: result.status });
}

export { handle as GET, handle as POST, handle as PUT, handle as PATCH, handle as DELETE };
