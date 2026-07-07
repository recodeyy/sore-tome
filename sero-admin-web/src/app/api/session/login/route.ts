import { NextRequest, NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { setSession, type SessionUser } from "@/lib/session";

// POST /api/session/login  { phone, password, portal, workspaceId? }
// Proxies to backend /auth/login, stores tokens in httpOnly cookies.
export async function POST(req: NextRequest) {
  let payload: { phone?: string; password?: string; portal?: string };
  try {
    payload = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
  }

  const { phone, password, portal } = payload;
  if (!phone || !password || !portal) {
    return NextResponse.json(
      { error: "phone, password and portal are required" },
      { status: 400 }
    );
  }

  const result = await backendFetch("/auth/login", {
    method: "POST",
    body: JSON.stringify({ phone, password, portal }),
  });

  const body = result.body as any;
  if (!result.ok) {
    return NextResponse.json(
      { error: body?.error?.message || body?.error || "Login failed", details: body },
      { status: result.status }
    );
  }

  const data = body?.data ?? body;
  const token: string = data?.token;
  const refreshToken: string = data?.refreshToken;
  const user = data?.user ?? {};

  if (!token) {
    return NextResponse.json(
      { error: "Login response missing token", details: body },
      { status: 502 }
    );
  }

  const sessionUser: SessionUser = {
    uid: user.uid || user.id || "",
    name: user.name || "SERO User",
    role: data?.activeWorkspace?.role || user.role || "",
    society_id: data?.activeWorkspace?.societyId ?? user.society_id ?? null,
    portal,
    phone: user.phone,
  };

  setSession(token, refreshToken, sessionUser);

  return NextResponse.json({
    user: sessionUser,
    requiresWorkspaceSelection: data?.requiresWorkspaceSelection ?? false,
    destinations: data?.destinations ?? [],
  });
}
