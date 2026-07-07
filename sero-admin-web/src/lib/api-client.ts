// Client-side data access. Everything goes through the Next BFF proxy at
// /api/proxy/<backend-path> so the JWT (httpOnly cookie) is attached server-side
// and never touches client JS.
"use client";

export class ApiError extends Error {
  status: number;
  body: unknown;
  constructor(status: number, message: string, body: unknown) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown
): Promise<T> {
  const res = await fetch(`/api/proxy${path.startsWith("/") ? path : `/${path}`}`, {
    method,
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });

  let data: any = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = { raw: text };
    }
  }

  if (!res.ok) {
    const message =
      data?.error?.message || data?.error || data?.message || `Request failed (${res.status})`;
    throw new ApiError(res.status, message, data);
  }
  return data as T;
}

export const api = {
  get: <T>(path: string) => request<T>("GET", path),
  post: <T>(path: string, body?: unknown) => request<T>("POST", path, body),
  put: <T>(path: string, body?: unknown) => request<T>("PUT", path, body),
  patch: <T>(path: string, body?: unknown) => request<T>("PATCH", path, body),
  del: <T>(path: string, body?: unknown) => request<T>("DELETE", path, body),
};

// Unwraps the backend's { success, data } envelope OR returns the raw payload.
export function unwrap<T = any>(res: any): T {
  if (res && typeof res === "object" && "data" in res && "success" in res) {
    return res.data as T;
  }
  return res as T;
}
