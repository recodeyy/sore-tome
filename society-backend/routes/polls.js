const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { logger } = require("../src/shared/Logger");

// Middleware: Only admin or secretary can create polls
function canManagePolls(req, res, next) {
  if (req.user.role !== "main_admin" && req.user.role !== "secretary") {
    return res.status(403).json({ error: "Access denied. Admin or Secretary role required." });
  }
  next();
}

// GET /polls -> List all active and past polls for the society
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const snap = await db.collection("polls")
      .where("society_id", "==", req.societyId)
      .orderBy("createdAt", "desc")
      .get();
      
    const polls = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ polls });
  } catch (err) {
    logger.error({ error: err.message }, "Error fetching polls");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /polls -> Create a new poll
router.post("/", authMiddleware, tenantMiddleware, canManagePolls, async (req, res) => {
  try {
    const { question, options, expiresAt } = req.body; // options is an array of strings
    if (!question || !Array.isArray(options) || options.length < 2) {
      return res.status(400).json({ error: "Question and at least 2 options are required." });
    }

    const db = getDb();
    
    // Initialize vote counts to 0 for each option
    const optionsMap = {};
    options.forEach(opt => { optionsMap[opt] = 0; });

    const pollData = {
      question,
      options: optionsMap, // e.g., { "Yes": 0, "No": 0 }
      votedFlats: [], // Array of flat numbers that have already voted
      expiresAt: expiresAt ? new Date(expiresAt) : null,
      society_id: req.societyId,
      createdBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
      status: "active"
    };

    const docRef = await db.collection("polls").add(pollData);
    res.status(201).json({ message: "Poll created successfully", id: docRef.id });
  } catch (err) {
    logger.error({ error: err.message }, "Error creating poll");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /polls/:id/vote -> Resident casts a vote
router.post("/:id/vote", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const { option } = req.body;
    if (!option) return res.status(400).json({ error: "Option is required to vote" });

    const db = getDb();
    
    // Resident only logic to enforce 1 vote per flat
    if (req.user.role !== "resident") {
        return res.status(403).json({ error: "Only residents can vote in polls" });
    }

    const userDoc = await db.collection("users").doc(req.user.uid).get();
    if (!userDoc.exists) return res.status(404).json({ error: "User profile not found" });
    const flatNumber = userDoc.data().flatNumber;

    if (!flatNumber) return res.status(400).json({ error: "You must be assigned to a flat to vote" });

    // Use transaction to ensure safe vote increment and flat tracking
    await db.runTransaction(async (t) => {
      const pollRef = db.collection("polls").doc(req.params.id);
      const pollDoc = await t.get(pollRef);

      if (!pollDoc.exists || pollDoc.data().society_id !== req.societyId) {
        throw new Error("Poll not found");
      }

      const pollData = pollDoc.data();
      
      if (pollData.status !== "active") {
        throw new Error("This poll is closed");
      }

      if (pollData.expiresAt && pollData.expiresAt.toDate() < new Date()) {
        throw new Error("This poll has expired");
      }

      if (pollData.votedFlats.includes(flatNumber)) {
        throw new Error(`Flat ${flatNumber} has already voted on this poll. Only 1 vote allowed per flat.`);
      }

      if (pollData.options[option] === undefined) {
        throw new Error("Invalid option selected");
      }

      // Update vote count and add flat to voted list
      const updatedOptions = { ...pollData.options };
      updatedOptions[option] += 1;
      
      const updatedVotedFlats = [...pollData.votedFlats, flatNumber];

      t.update(pollRef, {
        options: updatedOptions,
        votedFlats: updatedVotedFlats
      });
      
      // Keep a hidden record of the exact user who voted for audit purposes
      const voteRecordRef = db.collection("polls").doc(req.params.id).collection("votes").doc(req.user.uid);
      t.set(voteRecordRef, {
          flatNumber: flatNumber,
          userId: req.user.uid,
          option: option,
          votedAt: getAdmin().firestore.FieldValue.serverTimestamp()
      });
    });

    res.json({ message: "Vote cast successfully!" });
  } catch (err) {
    logger.error({ error: err.message }, "Error casting vote");
    res.status(err.message.includes("already voted") ? 409 : 500).json({ error: err.message });
  }
});

module.exports = router;
