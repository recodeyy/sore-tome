const express = require("express");
const router = express.Router();
const multer = require("multer");
const { getDb, getAdmin, getStorage } = require("../config/firebase");
const { authMiddleware, mainAdminOnly, canManageContent } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { startMediaCleaner } = require("../utils/mediaCleaner");
const { getAdminBriefing, convertMessageToIssue } = require("../services/channelService");
const crypto = require("crypto");
const { validate } = require("../src/middleware/validate");
const { MediaUploadSchema } = require("../src/shared/schemas");

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } 
});

const rateLimit = require("express-rate-limit");

const messageRateLimiter = rateLimit({
  windowMs: 1000,
  max: 5,
  message: { error: "Slow down. Message rate limit exceeded." },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { default: false },
});

startMediaCleaner();

// Middleware to check if user has access to a specific channel within their society
async function checkChannelAccess(req, res, next) {
  try {
    const db = getDb();
    const channelId = req.params.id;
    const channelDoc = await db.collection("channels").doc(channelId).get();

    if (!channelDoc.exists || channelDoc.data().society_id !== req.societyId) {
      return res.status(404).json({ error: "Channel not found" });
    }

    const data = channelDoc.data();
    if (req.user.role !== "main_admin" && req.user.role !== "superadmin" && req.user.role !== "secretary") {
      if (!data.allowedRoles || !data.allowedRoles.includes(req.user.role)) {
        return res.status(403).json({ error: "Access denied to this channel" });
      }
    }
    next();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

// GET /channels (Filtered by societyId)
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    let query = db.collection("channels")
      .where("society_id", "==", req.societyId)
      .orderBy("createdAt", "desc");
    
    if (req.user.role !== "main_admin" && req.user.role !== "superadmin" && req.user.role !== "secretary") {
      query = query.where("allowedRoles", "array-contains", req.user.role);
    }

    const snap = await query.get();
    const channels = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ channels });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels (Admin only, Scoped to societyId)
router.post("/", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const { name, description, isReadOnly = false, allowedRoles = ["resident", "main_admin"] } = req.body;
    if (!name) return res.status(400).json({ error: "name is required" });

    const db = getDb();
    const docRef = await db.collection("channels").add({
      society_id: req.societyId, // MANDATORY partition
      name,
      description: description || "",
      isReadOnly,
      allowedRoles,
      createdBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Channel created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /channels/:id (Scoped by societyId)
router.delete("/:id", authMiddleware, tenantMiddleware, mainAdminOnly, async (req, res) => {
  try {
    const db = getDb();
    const docRef = db.collection("channels").doc(req.params.id);
    const doc = await docRef.get();
    
    if (!doc.exists || doc.data().society_id !== req.societyId) {
       return res.status(404).json({ error: "Channel not found" });
    }

    await docRef.delete();
    res.json({ message: "Channel deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mark Read (Messages are sub-collections, naturally scoped by channelId)
router.post("/:id/read", authMiddleware, tenantMiddleware, checkChannelAccess, async (req, res) => {
  try {
    const db = getDb();
    
    const recentMsgs = await db.collection("channels")
      .doc(req.params.id)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(50) 
      .get();

    const batch = db.batch();
    let count = 0;

    recentMsgs.forEach(doc => {
      const data = doc.data();
      const readBy = data.readBy || [];
      if (!readBy.includes(req.user.uid) && data.senderId !== req.user.uid) {
        batch.update(doc.ref, {
          readBy: getAdmin().firestore.FieldValue.arrayUnion(req.user.uid)
        });
        count++;
      }
    });

    if (count > 0) await batch.commit();

    res.json({ success: true, markedRead: count });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH /channels/:id (Scoped by societyId)
router.patch("/:id", authMiddleware, tenantMiddleware, canManageContent, async (req, res) => {
  try {
    const { name, description, isReadOnly, allowedRoles, quietHours, smartType, vaultEnabled, moderatorIds } = req.body;
    const db = getDb();
    const docRef = db.collection("channels").doc(req.params.id);
    const doc = await docRef.get();

    if (!doc.exists || doc.data().society_id !== req.societyId) {
       return res.status(404).json({ error: "Channel not found" });
    }
    
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (isReadOnly !== undefined) updateData.isReadOnly = isReadOnly;
    if (allowedRoles !== undefined) updateData.allowedRoles = allowedRoles;
    if (quietHours !== undefined) updateData.quietHours = quietHours;
    if (smartType !== undefined) updateData.smartType = smartType;
    if (vaultEnabled !== undefined) updateData.vaultEnabled = vaultEnabled;
    if (moderatorIds !== undefined) updateData.moderatorIds = moderatorIds;

    updateData.updatedAt = getAdmin().firestore.FieldValue.serverTimestamp();

    await docRef.update(updateData);
    res.json({ message: "Channel settings updated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /channels/:id/messages (Scoped by checkChannelAccess)
router.post("/:id/messages", authMiddleware, tenantMiddleware, checkChannelAccess, messageRateLimiter, async (req, res) => {
  try {
    const { text, clientId, senderName, senderFlat, mediaUrl, mediaType, fileName, smartType = "chat", metadata = {} } = req.body;
    
    const db = getDb();
    const channelRef = db.collection("channels").doc(req.params.id);
    const channelDoc = await channelRef.get();
    const channelData = channelDoc.data();

    const isModerator = channelData.moderatorIds && channelData.moderatorIds.includes(req.user.uid);
    if (channelData.isReadOnly && !["main_admin", "secretary"].includes(req.user.role) && !isModerator) {
       return res.status(403).json({ error: "Only admins and moderators can post in this channel" });
    }

    if (!text && !mediaUrl) {
      return res.status(400).json({ error: "Content is required" });
    }

    const msgRef = await channelRef.collection("messages").add({
      text: text || "",
      clientId: clientId || null, 
      senderId: req.user.uid,
      senderName: senderName || req.user.name || "Resident",
      senderFlat: senderFlat || "",
      mediaUrl: mediaUrl || null,
      mediaType: mediaType || null,
      fileName: fileName || null,
      smartType,
      metadata,
      deliveredBy: [], 
      deliveredCount: 0,
      readBy: [],
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    // AI V2.4: Notify the channel (simplified as topic notification)
    // Note: In a production app, you might want to skip notifications for the sender
    const NotificationService = require("../services/notificationService");
    await NotificationService.sendToSociety(req.societyId, {
      title: `${senderName || "New Message"} in ${channelData.name}`,
      body: text ? (text.length > 100 ? text.substring(0, 97) + "..." : text) : "Sent a media file",
      data: { type: "chat", channelId: req.params.id }
    });
    
    res.status(201).json({ id: msgRef.id, clientId, message: "Message sent" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /channels/:id/messages (Scoped by checkChannelAccess)
router.get("/:id/messages", authMiddleware, tenantMiddleware, checkChannelAccess, async (req, res) => {
  try {
    const db = getDb();
    const channelRef = db.collection("channels").doc(req.params.id);
    const snap = await channelRef.collection("messages")
      .orderBy("createdAt", "desc").limit(50).get();
    
    const messages = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    });
    res.json({ messages });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /channels/:id/messages/:msgId (Soft Delete)
router.delete("/:id/messages/:msgId", authMiddleware, tenantMiddleware, checkChannelAccess, async (req, res) => {
  try {
    const db = getDb();
    const msgRef = db.collection("channels").doc(req.params.id).collection("messages").doc(req.params.msgId);
    const msgSnap = await msgRef.get();

    if (!msgSnap.exists) return res.status(404).json({ error: "Message not found" });
    const msgData = msgSnap.data();

    if (msgData.senderId !== req.user.uid && req.user.role !== "main_admin") {
      return res.status(403).json({ error: "Permission denied" });
    }

    await msgRef.update({
      text: "🚫 This message was deleted",
      isDeleted: true,
      deletedAt: getAdmin().firestore.FieldValue.serverTimestamp()
    });

    res.json({ success: true, message: "Message deleted for everyone" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
