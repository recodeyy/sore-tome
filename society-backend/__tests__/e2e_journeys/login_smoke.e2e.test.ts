import "dotenv/config";
import { describe, it, expect, jest } from "@jest/globals";

/**
 * One login smoke test per portal against the RUNNING backend (:3001).
 *
 * POST /auth/login is behind a strict rate limiter (5/15min per IP), so each
 * portal gets exactly one attempt and a 429 is tolerated (the limiter firing
 * proves the route is alive and guarded). Any other non-200 is a failure.
 *
 * Uses the demo logins seeded by scripts/seed_hubtown_sunkist_logins.js
 * (password 123456).
 */

jest.setTimeout(30000);

const BASE = process.env.E2E_BASE_URL || "http://localhost:3001";

const PORTALS: Array<{ portal: string; phone: string; expectedUid: string }> = [
  { portal: "resident", phone: "9200000002", expectedUid: "sunkist-res-001" },
  { portal: "admin", phone: "9200000001", expectedUid: "sunkist-admin-001" },
  { portal: "staff", phone: "9200000003", expectedUid: "sunkist-guard-001" },
];

describe("Login smoke (real server on :3001, tolerates 429)", () => {
  for (const { portal, phone, expectedUid } of PORTALS) {
    it(`logs into the ${portal} portal (or is rate-limited with 429)`, async () => {
      let res: any;
      try {
        res = await fetch(`${BASE}/api/v1/auth/login`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ phone, password: "123456", portal }),
        });
      } catch (e: any) {
        throw new Error(
          `Backend not reachable at ${BASE} (${e.message}). The e2e login smoke needs the dev server running.`
        );
      }

      expect([200, 429]).toContain(res.status);
      if (res.status === 429) {
        console.warn(`[login smoke] ${portal}: rate-limited (429) — tolerated`);
        return;
      }

      const body: any = await res.json();
      const token = body.token || body?.data?.token;
      expect(token).toBeTruthy();
      const user = body.user || body?.data?.user;
      expect(user?.uid).toBe(expectedUid);
      expect(user?.society_id).toBe("hubtown-sunkist");
    });
  }
});
