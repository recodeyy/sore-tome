import { defineConfig, devices } from "@playwright/test";

// E2E runs against a running web server on :3005 which itself proxies the
// canonical backend on :3001. Both must be up (see WEBSITE_DEPLOYMENT_RUNBOOK).
export default defineConfig({
  testDir: "./tests-e2e",
  timeout: 30_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: process.env.WEB_BASE_URL || "http://localhost:3005",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  ],
});
