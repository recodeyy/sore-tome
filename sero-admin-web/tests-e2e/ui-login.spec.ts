import { test, expect } from "@playwright/test";

// Browser UI smoke: login form -> dashboard renders live stat cards.
test("admin can log in and see the live dashboard", async ({ page }) => {
  await page.goto("/login");
  await page.getByPlaceholder("9200000001").fill("9200000001");
  await page.getByLabel("Password").fill("123456");
  await page.getByRole("button", { name: "Sign in" }).click();

  await page.waitForURL("**/dashboard", { timeout: 20_000 });
  await expect(page.getByText("Dashboard")).toBeVisible();
  // Live stat card label from the backend summary contract.
  await expect(page.getByText("Open Complaints")).toBeVisible();
});
