const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
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
        userName: data.userName,
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
