// bulk_insert_firestore.js
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

// TODO: replace with your service account JSON path
const serviceAccount = require("./serviceAccountKey.json");

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// JSON file path
// const jsonFile = path.join(__dirname, "bulk_test_data.json");
const jsonFile = path.join(__dirname, "simple_test.json");

// Staff IDs to assign randomly
const staffIds = [
  "4NpJJodEwQX7PHAqNmivSoRTIPh2",
  "YklHCfUiJ0hekUhY1U0tvYiwtn73",
  "ub49u5CeERc2CYc5berUsdeRCq92",
];

// Helper: generate activitiesByDay
function generateActivitiesByDay(activityPool, duration) {
  const days = [];
  const perDay = Math.ceil(activityPool.length / duration);

  for (let i = 0; i < duration; i++) {
    const start = i * perDay;
    const end = start + perDay;
    const dayActivities = activityPool.slice(start, end).map((act) => ({
      ...act,
      duration: act.duration.toString(),
      // remove day here; we'll set day in parent object
    }));

    days.push({
      day: i + 1,
      activities: dayActivities,
    });
  }

  return days;
}

// Main
async function main() {
  const rawData = fs.readFileSync(jsonFile, "utf-8");
  const packages = JSON.parse(rawData);

  for (const pkg of packages) {
    const pkgId = pkg.id;
    const creatorId = staffIds[Math.floor(Math.random() * staffIds.length)];

    const activitiesByDay = generateActivitiesByDay(
      pkg.activityPool,
      pkg.duration
    );

    // Generate imageUrl placeholder if missing
    const imageUrl =
      pkg.imageUrl ||
      `https://firebasestorage.googleapis.com/v0/b/travel2u-856f2.appspot.com/o/travel_packages%2F${pkgId}.jpg?alt=media`;

    const docData = {
      id: pkgId,
      name: pkg.name,
      destination: pkg.destination,
      duration: pkg.duration,
      price: pkg.price,
      flightClass: pkg.flightClass || "Air Asia",
      flightDetail: pkg.flightDetail || pkg.flightClass || "Air Asia",
      hotelDetail: pkg.hotelDetail || "Default Hotel",
      hotelRating: pkg.hotelRating || "3 Star",
      tourGuide: pkg.tourGuide || "Tour Guide Name",
      tags: pkg.tags || [],
      activityPool: pkg.activityPool.map((a) => ({ ...a })),
      activitiesByDay: activitiesByDay,
      creatorId: creatorId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      imageUrl,
    };

    await db.collection("travel_packages").doc(pkgId).set(docData);
    console.log(`Inserted package: ${pkgId}`);
  }

  console.log("All packages inserted successfully!");
}

main().catch((err) => {
  console.error(err);
});
