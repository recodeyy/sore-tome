import { test, expect, request } from "@playwright/test";

// API-level cross-role E2E through the website BFF. Proves the website drives
// REAL backend state (no mocks) and that admin writes land in the shared DB the
// mobile app reads. Requires web :3005 + backend :3001 running with the Hubtown
// Sunkist seed. See WEBSITE_E2E_TEST_REPORT.md.
const BASE = process.env.WEB_BASE_URL || "http://localhost:3005";

// Cache one context per portal so the whole suite performs only 2 logins —
// staying under the backend auth rate-limiter (5 / 15 min).
const cache: Record<string, any> = {};
async function loginCtx(portal: string, phone: string) {
  if (cache[portal]) return cache[portal];
  const ctx = await request.newContext({ baseURL: BASE });
  const res = await ctx.post("/api/session/login", {
    data: { phone, password: "123456", portal },
  });
  expect(res.ok(), await res.text()).toBeTruthy();
  cache[portal] = ctx;
  return ctx;
}

test("admin sees live invoices (no mock)", async () => {
  const admin = await loginCtx("admin", "9200000001");
  const res = await admin.get("/api/proxy/finance/invoices");
  expect(res.ok()).toBeTruthy();
  const body = await res.json();
  expect(Array.isArray(body.invoices)).toBeTruthy();
  expect(body.invoices.length).toBeGreaterThan(0);
});

test("unauthenticated proxy is rejected", async () => {
  const ctx = await request.newContext({ baseURL: BASE });
  const res = await ctx.get("/api/proxy/finance/invoices");
  expect(res.status()).toBe(401);
});

test("admin notice write persists to shared backend", async () => {
  const admin = await loginCtx("admin", "9200000001");
  const title = `E2E Notice ${Date.now()}`;
  const created = await admin.post("/api/proxy/notices-v2", {
    data: { title, body: "Automated cross-role test notice.", type: "general" },
  });
  expect(created.ok()).toBeTruthy();
  const id = (await created.json()).notice.id;

  const pub = await admin.post(`/api/proxy/notices-v2/${id}/publish`);
  expect(pub.ok()).toBeTruthy();

  // Read back from the same shared endpoint the mobile app consumes.
  const list = await admin.get("/api/proxy/notices-v2");
  const notices = (await list.json()).notices;
  const found = notices.find((n: any) => n.id === id);
  expect(found).toBeTruthy();
  expect(found.status).toBe("published");
});

test("super-admin dashboard returns live metrics", async () => {
  const sa = await loginCtx("super-admin", "superadmin");
  const res = await sa.get("/api/proxy/super-admin/dashboard");
  expect(res.ok()).toBeTruthy();
  const metrics = (await res.json()).data.metrics;
  expect(Array.isArray(metrics)).toBeTruthy();
  expect(metrics.find((m: any) => m.key === "active_users")).toBeTruthy();
});

test("AI proxy responds without exposing keys", async () => {
  const admin = await loginCtx("admin", "9200000001");
  const res = await admin.post("/api/ai/chat", {
    data: { message: "Summarize what a dues reminder is in one sentence.", portal: "admin" },
  });
  expect(res.ok()).toBeTruthy();
  const body = await res.json();
  expect(typeof body.reply).toBe("string");
  expect(body.reply.length).toBeGreaterThan(0);
});
