import { NextRequest, NextResponse } from "next/server";

// Exact-match public paths open to everyone: the marketing landing page ("/")
// and the login screen. Everything else requires a session. Matching "/" by
// prefix would make the whole site public, so the landing is matched exactly.
const PUBLIC_EXACT = ["/", "/login"];
const PUBLIC_PREFIXES = ["/login"];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const token = req.cookies.get("sero_token")?.value;

  const isPublic =
    PUBLIC_EXACT.includes(pathname) ||
    PUBLIC_PREFIXES.some((p) => pathname.startsWith(p));

  // Unauthenticated → force to login (except public + assets/api handled by matcher)
  if (!token && !isPublic) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  // Already authenticated hitting /login → send to dashboard. The landing page
  // at "/" is intentionally shown to everyone (its CTA routes signed-in users
  // to their dashboard), so it is NOT redirected here.
  if (token && pathname === "/login") {
    const url = req.nextUrl.clone();
    url.pathname = "/dashboard";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  // Protect everything except API routes, Next internals, and static files.
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
