// functions/index.js
const { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Transactionally update ratingCount, ratingSum, ratingAvg on a business doc
async function updateAggregates(bizId, deltaCount, deltaSum) {
  const bizRef = db.collection("businesses").doc(bizId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(bizRef);
    const d = snap.exists ? snap.data() : {};
    const count = (d.ratingCount || 0) + deltaCount;
    const sum = (d.ratingSum || 0) + deltaSum;
    const avg = count > 0 ? sum / count : 0;
    tx.set(bizRef, { ratingCount: count, ratingSum: sum, ratingAvg: avg }, { merge: true });
  });
}

// New review -> increment count and sum
exports.onReviewCreated = onDocumentCreated(
  "businesses/{bizId}/reviews/{reviewId}",
  async (event) => {
    const bizId = event.params.bizId;
    const rating = Number(event.data.data()?.rating || 0);
    await updateAggregates(bizId, +1, +rating);
  }
);

// Review updated -> adjust sum if rating changed
exports.onReviewUpdated = onDocumentUpdated(
  "businesses/{bizId}/reviews/{reviewId}",
  async (event) => {
    const bizId = event.params.bizId;
    const before = Number(event.data.before.data()?.rating || 0);
    const after  = Number(event.data.after.data()?.rating || 0);
    if (before === after) return null;
    await updateAggregates(bizId, 0, after - before);
    return null;
  }
);

// Review deleted -> decrement count and sum
exports.onReviewDeleted = onDocumentDeleted(
  "businesses/{bizId}/reviews/{reviewId}",
  async (event) => {
    const bizId = event.params.bizId;
    const rating = Number(event.data.data()?.rating || 0);
    await updateAggregates(bizId, -1, -rating);
  }
);

// One-time backfill to initialize existing data
exports.backfillRatings = onRequest(async (_req, res) => {
  const businesses = await db.collection("businesses").get();
  for (const biz of businesses.docs) {
    const revs = await biz.ref.collection("reviews").get();
    let count = 0, sum = 0;
    revs.forEach(r => {
      const v = Number(r.data()?.rating || 0);
      if (!isNaN(v)) { count++; sum += v; }
    });
    const avg = count > 0 ? sum / count : 0;
    await biz.ref.set({ ratingCount: count, ratingSum: sum, ratingAvg: avg }, { merge: true });
  }
  res.send("Backfill complete");
});
