const { getDb, getAdmin } = require("../config/firebase");

let briefingCache = { data: null, expiry: 0 };

async function getAdminBriefing() {
  const now = Date.now();
  if (briefingCache.data && now < briefingCache.expiry) {
    return briefingCache.data;
  }

  const db = getDb();
  const dayAgo = new Date(now - (24 * 60 * 60 * 1000));

  // Fetch counts in parallel for performance
  const [channels, pendingUsers, highPriorityIssues] = await Promise.all([
    db.collection("channels").get(),
    db.collection("users").where("status", "==", "pending").get(),
    db.collection("issues").where("status", "==", "open").where("priority", "==", "high").get(),
  ]);

  let totalMessages24h = 0;
  let officialNotices = 0;

  const msgPromises = channels.docs.map(chan => 
    chan.ref.collection("messages")
      .where("createdAt", ">", dayAgo)
      .get()
  );
  
  const results = await Promise.all(msgPromises);
  results.forEach(msgs => {
    totalMessages24h += msgs.size;
    officialNotices += msgs.docs.filter(d => d.data().isOfficial).length;
  });

  const insights = [];
  if (pendingUsers.size > 0) {
    insights.push(`${pendingUsers.size} residents are awaiting your approval.`);
  } else {
    insights.push("All resident applications are up to date.");
  }

  if (highPriorityIssues.size > 0) {
    insights.push(`${highPriorityIssues.size} high-priority issues require attention.`);
  }

  if (officialNotices > 0) {
    insights.push(`${officialNotices} official notices were broadcasted today.`);
  }

  const data = {
    summary: `In the last 24h, ${totalMessages24h} messages were shared across ${channels.size} hubs.`,
    insights: insights.length > 0 ? insights : ["Society activity is stable with no urgent matters."],
    timestamp: new Date().toISOString()
  };

  briefingCache = { data, expiry: now + (5 * 60 * 1000) }; // 5 min cache
  return data;
}

async function convertMessageToIssue(channelId, messageId, user) {
  const db = getDb();
  const msgRef = db.collection("channels").doc(channelId).collection("messages").doc(messageId);
  const msgSnap = await msgRef.get();

  if (!msgSnap.exists) throw new Error("Message not found");
  const msgData = msgSnap.data();

  // Create New Issue
  const issueRef = await db.collection("issues").add({
    title: `Chat Sync: Issue from ${msgData.senderName}`,
    description: msgData.text,
    status: "open",
    priority: "medium",
    postedBy: msgData.senderId,
    location: msgData.senderFlat || "Unknown",
    source: "chat_conversion",
    sourceChannelId: channelId,
    sourceMessageId: messageId,
    createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    updatedAt: getAdmin().firestore.FieldValue.serverTimestamp()
  });

  // Post "Closed Loop" update back to chat
  const shortId = issueRef.id.substring(0, 4).toUpperCase();
  await db.collection("channels").doc(channelId).collection("messages").add({
    text: `✅ Formal Record Established: #${shortId}`,
    senderId: "system",
    senderName: "System Agent",
    isSystemMessage: true,
    smartType: "ticket_conversion",
    metadata: {
      issueId: issueRef.id,
      shortId: shortId,
      description: msgData.text,
      status: "open",
    },
    createdAt: getAdmin().firestore.FieldValue.serverTimestamp()
  });

  return issueRef.id;
}

module.exports = {
  getAdminBriefing,
  convertMessageToIssue
};
