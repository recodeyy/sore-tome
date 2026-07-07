const request = require("supertest");
const express = require("express");
const jwt = require("jsonwebtoken");
const { db, dbManager } = require("../src/shared/Database");

// Mock Firebase for Auth
jest.mock("../config/firebase", () => {
  const bcrypt = require("bcryptjs");
  const TEST_PASSWORD_HASH = bcrypt.hashSync("password", 10);

  const mockGet = jest.fn(() => Promise.resolve({
    empty: false,
    docs: [{
      id: "u-test-auth",
      ref: {
        update: jest.fn(() => Promise.resolve())
      },
      data: () => ({
        uid: "u-test-auth",
        name: "Test Auth User",
        phone: "+919999999999",
        password: TEST_PASSWORD_HASH,
        role: "resident",
        society_id: "soc-test",
        status: "approved"
      })
    }]
  }));

  return {
    initFirebase: jest.fn(),
    getDb: jest.fn(() => ({
      collection: jest.fn(() => ({
        where: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        get: mockGet,
        doc: jest.fn(() => ({
          set: jest.fn(() => Promise.resolve()),
          get: jest.fn(() => Promise.resolve({
            exists: true,
            data: () => ({
              uid: "u-test-auth",
              name: "Test Auth User",
              phone: "+919999999999",
              role: "resident",
              society_id: "soc-test"
            })
          }))
        }))
      }))
    })),
    getAdmin: jest.fn(() => ({
      firestore: {
        Timestamp: { fromDate: (d) => d },
        FieldValue: { serverTimestamp: jest.fn(() => new Date()) }
      },
      auth: jest.fn(() => ({
        createCustomToken: jest.fn(() => Promise.resolve("mock-firebase-token"))
      }))
    }))
  };
});

// Import router AFTER mocks
const authRouter = require("../routes/auth");

const app = express();
app.use(express.json());
app.use("/auth", authRouter);

beforeAll(async () => {
  // Clear any existing test data from membership tables
  await db.query("DELETE FROM members WHERE society_id = 'soc-test'");
  
  // Insert test memberships in PostgreSQL for workspace select testing
  await db.query(`
    INSERT INTO members (society_id, user_id, name, phone, email, status, role)
    VALUES ('soc-test', 'u-test-auth', 'Test Auth User', '+919999999999', 'test@sero.com', 'approved', 'resident_owner')
  `);
});

afterAll(async () => {
  await db.query("DELETE FROM members WHERE society_id = 'soc-test'");
  await dbManager.close();
});

describe("Separate Role Login & Workspace Selection API (JS Integration)", () => {
  it("rejects login if there is a portal mismatch", async () => {
    const res = await request(app)
      .post("/auth/login")
      .send({
        phone: "+919999999999",
        password: "password",
        portal: "super-admin"
      });

    expect(res.statusCode).toBe(403);
    expect(res.body.error.code).toBe("PORTAL_MISMATCH");
    expect(res.body.error.allowedPortals).toContain("resident");
  });

  it("succeeds login on correct portal", async () => {
    const res = await request(app)
      .post("/auth/login")
      .send({
        phone: "+919999999999",
        password: "password",
        portal: "resident"
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.requiresWorkspaceSelection).toBe(false);
    expect(res.body.activeWorkspace.societyId).toBe("soc-test");
  });

  it("resolves workspace selector endpoints correctly", async () => {
    // 1. Get temporary token by logging in
    const loginRes = await request(app)
      .post("/auth/login")
      .send({
        phone: "+919999999999",
        password: "password",
        portal: "resident"
      });

    const token = loginRes.body.token;

    // 2. Select workspace (assert invalid ID gets rejected)
    const rejectRes = await request(app)
      .post("/auth/workspace/select")
      .set("Authorization", `Bearer ${token}`)
      .send({
        workspaceId: "invalid-workspace"
      });

    expect(rejectRes.statusCode).toBe(403);
    expect(rejectRes.body.error).toBe("Unauthorized access to selected workspace");
  });
});
