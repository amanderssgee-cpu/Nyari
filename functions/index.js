// functions/index.js
// Firebase Functions v2 (Node 18)

const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const toNum = (v) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};

// Transactionally update ratingCount, ratingSum, ratingAvg on a business doc
async function updateAggregates(bizId, deltaCount, deltaSum) {
  const bizRef = db.collection("businesses").doc(bizId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(bizRef);
    const d = snap.exists ? snap.data() : {};
    const count = toNum(d.ratingCount) + deltaCount;
    const sum = toNum(d.ratingSum) + deltaSum;
    const avg = count > 0 ? sum / count : 0;
    tx.set(
      bizRef,
      { ratingCount: count, ratingSum: sum, ratingAvg: avg },
      { merge: true }
    );
  });
}

/**
 * One trigger for CREATE + UPDATE + DELETE:
 * Path: businesses/{bizId}/reviews/{uid}
 * (works whether {uid} is a userId or any other doc id)
 */
exports.onReviewWrite = onDocumentWritten(
  // set region if you want, e.g. { region: "us-central1" },
  "businesses/{bizId}/reviews/{uid}",
  async (event) => {
    const { bizId } = event.params;

    const before = event.data.before.exists
      ? event.data.before.data()
      : null;
    const after = event.data.after.exists
      ? event.data.after.data()
      : null;

    let deltaCount = 0;
    let deltaSum = 0;

    if (!before && after) {
      // CREATE
      deltaCount = +1;
      deltaSum = toNum(after.rating);
    } else if (before && after) {
      // UPDATE
      deltaCount = 0;
      deltaSum = toNum(after.rating) - toNum(before.rating);
    } else if (before && !after) {
      // DELETE
      deltaCount = -1;
      deltaSum = -toNum(before.rating);
    } else {
      return;
    }

    await updateAggregates(bizId, deltaCount, deltaSum);
  }
);

// One-time backfill to initialize existing data
exports.backfillRatings = onRequest(async (_req, res) => {
  const businesses = await db.collection("businesses").get();
  for (const biz of businesses.docs) {
    const revs = await biz.ref.collection("reviews").get();
    let count = 0,
      sum = 0;
    revs.forEach((r) => {
      const v = toNum(r.data()?.rating);
      if (v) {
        count++;
        sum += v;
      }
    });
    const avg = count > 0 ? sum / count : 0;
    await biz.ref.set(
      { ratingCount: count, ratingSum: sum, ratingAvg: avg },
      { merge: true }
    );
  }
  res.send("Backfill complete");
});
