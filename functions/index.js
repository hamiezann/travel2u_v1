const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
admin.initializeApp();

exports.createUserAccount = onCall(async (request) => {
  const data = request.data;

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: data.email,
      password: data.password,
      displayName: data.userName,
    });

    await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set({
        firstName: data.userName,
        email: data.email,
        phone: data.phone,
        role: data.role ?? "customer",
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { uid: userRecord.uid };
  } catch (err) {
    logger.error("CREATE USER ERROR", err);
    throw new HttpsError("unknown", err.message);
  }
});

// exports.pushNotifications = onDocumentCreated(
//   {
//     region: "asia-southeast1",
//     document: "push_queue/{id}",
//   },
//   async (event) => {
//     const snap = event.data;

//     if (!snap) {
//       logger.warn("Snapshot missing.");
//       return;
//     }

//     const data = snap.data();

//     if (!data) {
//       logger.warn("Empty document:", snap.id);
//       return snap.ref.delete();
//     }

//     // Extract fields
//     const userId = data.userId;
//     let token = data.token;

//     // If userId given, fetch fcmToken
//     if (userId) {
//       const userSnap = await admin
//         .firestore()
//         .collection("users")
//         .doc(userId)
//         .get();

//       token = userSnap.data()?.fcmToken;
//     }

//     if (!token) {
//       logger.warn("No FCM token for this task");
//       return snap.ref.delete();
//     }

//     try {
//       await admin.messaging().send({
//         token,
//         notification: {
//           title: data.title,
//           body: data.body,
//         },
//         data: data.data ?? {},
//       });

//       logger.info("Notification sent");
//     } catch (err) {
//       logger.error("FCM send error", err);
//     }

//     return snap.ref.delete();
//   }
// );

exports.pushNotifications = onDocumentCreated(
  {
    region: "asia-southeast1",
    document: "push_queue/{id}",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    if (!data) return snap.ref.delete();

    const {
      userId, // single user
      userIds, // array of users
      role, // send to all users with role: "admin", "staff"
      token, // direct FCM token (manual)
      title,
      body,
      data: extraData = {},
    } = data;

    let targetTokens = [];

    // Case 1 — direct token
    if (token) {
      targetTokens.push(token);
    }

    // Case 2 — single user
    if (userId) {
      const userSnap = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();
      const t = userSnap.data()?.fcmToken;
      if (t) targetTokens.push(t);
    }

    // Case 3 — multiple users
    if (Array.isArray(userIds) && userIds.length > 0) {
      const batch = await admin
        .firestore()
        .collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", userIds)
        .get();

      batch.forEach((doc) => {
        const t = doc.data()?.fcmToken;
        if (t) targetTokens.push(t);
      });
    }

    // Case 4 — send to all users with role (example: "staff")
    if (role) {
      const roleSnap = await admin
        .firestore()
        .collection("users")
        .where("role", "==", role)
        .get();

      roleSnap.forEach((doc) => {
        const t = doc.data()?.fcmToken;
        if (t) targetTokens.push(t);
      });
    }

    // Remove duplicates
    targetTokens = [...new Set(targetTokens)];

    if (targetTokens.length === 0) {
      logger.warn("⚠ No target tokens found");
      return snap.ref.delete();
    }

    // Send to all tokens
    const messages = targetTokens.map((t) => ({
      token: t,
      notification: {
        title,
        body,
      },
      android: {
        notification: {
          icon: "logo1bw",
        },
      },
      data: {
        ...extraData,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    }));

    try {
      await Promise.all(messages.map((m) => admin.messaging().send(m)));
      logger.info(`📨 Sent to ${targetTokens.length} device(s)`);
    } catch (err) {
      logger.error("🔥 FCM send error", err);
    }

    return snap.ref.delete();
  }
);
