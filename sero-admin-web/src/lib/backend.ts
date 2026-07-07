// Server-only helper for talking to the canonical SERO backend.
// NEVER import this from a client component — it reads server env + cookies.
import "server-only";

export const BACKEND_URL =
  process.env.SERO_BACKEND_URL || "http://localhost:3001/api/v1";

export type BackendResult = {
  status: number;
  ok: boolean;
  body: unknown;
};

export async function backendFetch(
  path: string,
  init: RequestInit & { token?: string | null } = {}
): Promise<BackendResult> {
  const { token, headers, ...rest } = init;
  const url = `${BACKEND_URL}${path.startsWith("/") ? path : `/${path}`}`;
  const res = await fetch(url, {
    ...rest,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(headers || {}),
    },
    cache: "no-store",
  });

  let body: unknown = null;
  const text = await res.text();
  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      body = { raw: text };
    }
  }
  return { status: res.status, ok: res.ok, body };
}
