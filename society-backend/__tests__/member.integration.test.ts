import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { MemberService } from "../src/services/members/MemberService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-mem-${Date.now()}`;
const SOC_B = `test-mem-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM members WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("MemberService (integration)", () => {
  it("runs the register -> approve -> suspend lifecycle", async () => {
    const member = await MemberService.register(SOC, { name: "Asha", phone: "9990001111" });
    expect(member.status).toBe("pending");

    const approved = await MemberService.transition(SOC, member.id, "approved");
    expect(approved.status).toBe("approved");

    const suspended = await MemberService.transition(SOC, member.id, "suspended");
    expect(suspended.status).toBe("suspended");

    const reapproved = await MemberService.transition(SOC, member.id, "approved");
    expect(reapproved.status).toBe("approved");
  });

  it("rejects an illegal transition", async () => {
    const member = await MemberService.register(SOC, { name: "Ben" });
    // pending -> suspended is not allowed
    await expect(MemberService.transition(SOC, member.id, "suspended"))
      .rejects.toMatchObject({ code: "INVALID_TRANSITION" });
    // reject is terminal-ish
    await MemberService.transition(SOC, member.id, "rejected");
    await expect(MemberService.transition(SOC, member.id, "approved"))
      .rejects.toMatchObject({ code: "INVALID_TRANSITION" });
  });

  it("adds family + committee and exposes them via getMember", async () => {
    const member = await MemberService.register(SOC, { name: "Chitra" });
    await MemberService.addFamilyMember(SOC, member.id, { name: "Dev", relation: "son", isEmergencyContact: true });
    await MemberService.addCommitteeRole(SOC, member.id, { designation: "Treasurer", termStart: "2026-01-01" });
    const full = await MemberService.getMember(SOC, member.id);
    expect(full.family.length).toBe(1);
    expect(full.committee[0].designation).toBe("Treasurer");
  });

  it("reviews KYC documents (approve and reject)", async () => {
    const member = await MemberService.register(SOC, { name: "Esha" });
    const doc = await MemberService.addKyc(SOC, member.id, { docType: "aadhaar", fileUrl: "s3://x" });
    expect(doc.status).toBe("pending");

    const approved = await MemberService.reviewKyc(SOC, doc.id, "approved", undefined, "admin-1");
    expect(approved.status).toBe("approved");

    const doc2 = await MemberService.addKyc(SOC, member.id, { docType: "pan" });
    const rejected = await MemberService.reviewKyc(SOC, doc2.id, "rejected", "blurry", "admin-1");
    expect(rejected.status).toBe("rejected");
    expect(rejected.reject_reason).toBe("blurry");
  });

  it("does not leak members across tenants", async () => {
    const member = await MemberService.register(SOC, { name: "Iso" });
    const listB = await MemberService.listMembers(SOC_B);
    expect(listB.find((m: any) => m.id === member.id)).toBeUndefined();
    await expect(MemberService.getMember(SOC_B, member.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
    await expect(MemberService.transition(SOC_B, member.id, "approved")).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
