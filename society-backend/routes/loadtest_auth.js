// LOAD-TEST ONLY auth. Mounted by server.js ONLY when LOADTEST_MODE=true.
// Issues a real, society-scoped JWT for a seeded Postgres member/staff by phone —
// NO Firebase/Firestore involved, so the backend can run without a Firebase key.
// Never enable this in production.
const express = require("express");
const jwt = require("jsonwebtoken");
const { db } = require("../src/shared/Database");

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET;

router.post("/loadtest-login", async (req, res) => {
  try {
    const phone = String((req.body && req.body.phone) || "").trim();
    if (!phone) return res.status(400).json({ error: "phone required" });

    let r = await db.query(
      "SELECT user_id, name, phone, role, society_id FROM members WHERE phone=$1 AND status='approved' LIMIT 1",
      [phone]
    );
    if (r.rows.length === 0) {
      r = await db.query(
        "SELECT user_id, name, phone, role, society_id FROM staff WHERE phone=$1 AND status='active' LIMIT 1",
        [phone]
      );
    }
    if (r.rows.length === 0) return res.status(401).json({ error: "No such load-test user" });

    const u = r.rows[0];
    const token = jwt.sign(
      { uid: u.user_id || phone, phone: u.phone, name: u.name, role: u.role, society_id: u.society_id },
      JWT_SECRET,
      { expiresIn: "3h" }
    );
    res.json({ success: true, data: { token, society_id: u.society_id, role: u.role } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
