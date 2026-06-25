import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { SuperAdminService } from "../src/services/platform/SuperAdminService";
import { db, dbManager } from "../src/shared/Database";

const ACTOR_ID = "test-super-admin-actor";
const SOC_ID = "test-super-admin-soc";
const USER_ID = "test-super-admin-user";

beforeAll(async () => {
  // Clear any existing test data from control plane tables
  await db.query(`DELETE FROM impersonation_sessions`);
  await db.query(`DELETE FROM support_ticket_comments`);
  await db.query(`DELETE FROM support_tickets`);
  await db.query(`DELETE FROM society_status_history`);
  await db.query(`DELETE FROM society_subscriptions`);
  await db.query(`DELETE FROM society_applications`);
  await db.query(`DELETE FROM subscription_plans`);
  await db.query(`DELETE FROM platform_features`);

  // Insert mock subscription plan and platform feature
  await db.query(`
    INSERT INTO subscription_plans (id, code, name, price_minor, currency, interval, is_active)
    VALUES ('e846067b-1175-47e1-b472-763462b53fba', 'standard', 'Standard Plan', 49900, 'INR', 'monthly', true)
  `);

  await db.query(`
    INSERT INTO platform_features (id, key, name, default_enabled)
    VALUES ('f846067b-1175-47e1-b472-763462b53fba', 'ai_chat', 'AI Chatbot Assistant', true)
  `);
});

afterAll(async () => {
  await db.query(`DELETE FROM impersonation_sessions`);
  await db.query(`DELETE FROM support_ticket_comments`);
  await db.query(`DELETE FROM support_tickets`);
  await db.query(`DELETE FROM society_status_history`);
  await db.query(`DELETE FROM society_subscriptions`);
  await db.query(`DELETE FROM society_applications`);
  await db.query(`DELETE FROM subscription_plans`);
  await db.query(`DELETE FROM platform_features`);
  await dbManager.close();
});

describe("Super Admin Platform Control Plane (Integration)", () => {
  let appId: string;
  let ticketId: string;

  it("handles society application review and approval", async () => {
    // 1. Insert application
    const appRes = await db.query(`
      INSERT INTO society_applications (society_name, contact_email, status, society_id)
      VALUES ('Marvel Society', 'tony@stark.com', 'pending', $1)
      RETURNING *
    `, [SOC_ID]);
    appId = appRes.rows[0].id;

    // 2. Approve via service
    await SuperAdminService.approveSociety(SOC_ID, ACTOR_ID, "Looks good!");

    // 3. Verify status
    const verifiedApp = await db.query(`SELECT * FROM society_applications WHERE id = $1`, [appId]);
    expect(verifiedApp.rows[0].status).toBe("approved");

    const verifiedSub = await db.query(`SELECT * FROM society_subscriptions WHERE society_id = $1`, [SOC_ID]);
    expect(verifiedSub.rows.length).toBe(1);
    expect(verifiedSub.rows[0].status).toBe("active");
  });

  it("handles society suspension and reactivation", async () => {
    // Suspend
    await SuperAdminService.suspendSociety(SOC_ID, ACTOR_ID, "Payment failure");
    const suspendedSub = await db.query(`SELECT * FROM society_subscriptions WHERE society_id = $1`, [SOC_ID]);
    expect(suspendedSub.rows[0].status).toBe("suspended");

    // Reactivate
    await SuperAdminService.reactivateSociety(SOC_ID, ACTOR_ID, "Payment received");
    const activeSub = await db.query(`SELECT * FROM society_subscriptions WHERE society_id = $1`, [SOC_ID]);
    expect(activeSub.rows[0].status).toBe("active");
  });

  it("manages features and overrides", async () => {
    const list = await SuperAdminService.getFeatures();
    expect(list.length).toBe(1);
    expect(list[0].key).toBe("ai_chat");

    await SuperAdminService.setFeatureOverride(SOC_ID, "ai_chat", false, ACTOR_ID);
    const detail = await SuperAdminService.societyDetail(SOC_ID);
    expect(detail).toBeDefined();
    expect(detail.features.find((f: any) => f.key === "ai_chat")?.enabled).toBe(false);
  });

  it("manages support tickets assign and resolution", async () => {
    const ticketRes = await db.query(`
      INSERT INTO support_tickets (society_id, subject, body, priority, status)
      VALUES ($1, 'Server Down', 'Backend database connection timeout.', 'urgent', 'open')
      RETURNING id
    `, [SOC_ID]);
    ticketId = ticketRes.rows[0].id;

    // Assign
    await SuperAdminService.assignTicket(ticketId, "operator-1", "Assigning to Sr. Dev", ACTOR_ID);
    const assignedTicket = await db.query(`SELECT * FROM support_tickets WHERE id = $1`, [ticketId]);
    expect(assignedTicket.rows[0].assignee_id).toBe("operator-1");
    expect(assignedTicket.rows[0].status).toBe("in_progress");

    // Add Internal Note
    await SuperAdminService.addInternalNote(ticketId, "Investigating AWS RDS metrics", ACTOR_ID);
    const comments = await db.query(`SELECT * FROM support_ticket_comments WHERE ticket_id = $1 ORDER BY created_at DESC`, [ticketId]);
    expect(comments.rows.length).toBe(2); // Assignment comment + note
    expect(comments.rows[0].body).toBe("Investigating AWS RDS metrics");
    expect(comments.rows[0].internal).toBe(true);

    // Resolve
    await SuperAdminService.resolveTicket(ticketId, "Rebooted instance", ACTOR_ID);
    const resolvedTicket = await db.query(`SELECT * FROM support_tickets WHERE id = $1`, [ticketId]);
    expect(resolvedTicket.rows[0].status).toBe("resolved");
  });

  it("starts and stops impersonation sessions", async () => {
    const session = await SuperAdminService.startImpersonation({
      actorId: ACTOR_ID,
      targetUserId: USER_ID,
      societyId: SOC_ID,
      reason: "Debugging financial logs",
      durationMinutes: 10
    });
    expect(session).toBeDefined();
    expect(session.status).toBe("active");

    await SuperAdminService.stopCurrentImpersonation(ACTOR_ID);
    const stopped = await db.query(`SELECT * FROM impersonation_sessions WHERE id = $1`, [session.id]);
    expect(stopped.rows[0].status).toBe("ended");
  });

  it("handles platform announcements", async () => {
    const announcement = await SuperAdminService.createAnnouncement("Scheduled Downtime", "Upgrade scheduled for Sunday 2 AM", "all", "in_app", ACTOR_ID);
    expect(announcement).toBeDefined();
    expect(announcement.title).toBe("Scheduled Downtime");
    expect(announcement.audience).toBe("all");
    expect(announcement.channel).toBe("in_app");

    // Announcements are platform-global (not test-scoped), so assert the row we
    // just created is present rather than an exact count across runs.
    const list = await SuperAdminService.getAnnouncements();
    expect(list.find((a: any) => a.id === announcement.id)).toBeDefined();
  });
});
