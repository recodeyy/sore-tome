const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");
const { validate } = require("../src/middleware/validate");
const { CreateNoticeSchema } = require("../src/shared/schemas");
const rateLimit = require("express-rate-limit");

const aiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 5, // Limit each IP to 5 AI requests per minute
  message: { error: "AI request limit reached. Please wait a moment." },
  standardHeaders: true,
  legacyHeaders: false,
});

// Middleware specifically for notice management
const canManageContent = (req, res, next) => {
  const role = req.user?.role;
  if (["main_admin", "secretary"].includes(role)) {
    return next();
  }
  return res.status(403).json({ error: "Forbidden: You don't have permission to manage notices" });
};

// GET /notices — all residents can see notices (newest first)
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const societyId = req.societyId;
    
    const snap = await db.collection("notices")
      .where("society_id", "==", societyId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();

    const notices = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ notices });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /notices/ai-generate — admin only: generate a formal notice using AI
router.post("/ai-generate", authMiddleware, tenantMiddleware, canManageContent, aiLimiter, async (req, res) => {
  try {
    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt is required" });

    const anthropicKey = process.env.ANTHROPIC_API_KEY;
    if (!anthropicKey) throw new Error("AI is not configured on this server.");

    // System prompt engineered to produce exactly what a Society Secretary needs
    const systemPrompt = `You are an expert Society Secretary for a luxury residential apartment in India.
Your job is to take a short, informal prompt from the user and convert it into a highly professional, polite, and formal society notice.
The output MUST be a JSON object with two fields: 'title' (a professional subject line) and 'body' (the full formal notice, translated into English, Hindi, and Marathi within the same body text, separated clearly).
Do NOT return anything outside of the JSON object. Do not use markdown blocks around the JSON.`;

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01"
      },
      body: JSON.stringify({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1500,
        temperature: 0.2,
        system: systemPrompt,
        messages: [{ role: "user", content: `Draft a notice for: ${prompt}` }]
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Anthropic Error:", errText);
      throw new Error("AI generation failed");
    }

    const data = await response.json();
    const rawText = data.content[0].text.trim();
    
    // Parse the JSON output from Claude
    let noticeData;
    try {
      noticeData = JSON.parse(rawText);
    } catch (parseErr) {
      // Fallback if Claude adds markdown formatting
      const cleanJson = rawText.replace(/```json/g, "").replace(/```/g, "").trim();
      noticeData = JSON.parse(cleanJson);
    }

    res.json(noticeData); // { title: "...", body: "..." }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /notices — admin only: create a new notice
router.post("/", authMiddleware, tenantMiddleware, canManageContent, validate(CreateNoticeSchema), async (req, res) => {
  try {
    const { title, body, type } = req.body;
    const societyId = req.societyId;

    const db = getDb();
    const docRef = await db.collection("notices").add({
      title,
      body,
      type,
      society_id: societyId, // Partition ID
      postedBy: req.user.uid,
      postedByName: req.user.name || req.user.phone || "Unknown",
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Notice Posted",
      `Posted notice: "${title}"`
    );

    // AI V2.4: Send push notification to all residents in the society
    const NotificationService = require("../services/notificationService");
    await NotificationService.sendToSociety(societyId, {
      title: `New Notice: ${title}`,
      body: body.length > 100 ? body.substring(0, 97) + "..." : body,
      data: { type: "notice", id: docRef.id }
    });

    res.status(201).json({ id: docRef.id, message: "Notice posted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /notices/:id — admin only
router.delete("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("notices").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Notice not found" });
    }

    await docRef.delete();
    
    // Log the action
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Notice Deleted",
      `Deleted notice ID: ${req.params.id}`
    );

    res.json({ message: "Notice deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
