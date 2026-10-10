
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const RESTAURANT_ID = "default_bistro_01";
const TEST_FIELD = { isTestData: true };

initializeApp({
  credential: applicationDefault(),
});

const db = getFirestore();

const staff = [
  {
    id: "staff_01",
    name: "Elena Rostova",
    phone: "+1 555 234 5678",
    email: "elena.r@example.test",
    role: "Manager",
    department: "Front Desk",
    availableFrom: "08:00",
    availableTo: "18:00",
    availableHours: "08:00 - 18:00",
    maxDailyHours: 9,
  },
  {
    id: "staff_02",
    name: "Marcus Vance",
    phone: "+1 555 345 6789",
    email: "marcus.v@example.test",
    role: "Host",
    department: "Front Desk",
    availableFrom: "10:00",
    availableTo: "22:00",
    availableHours: "10:00 - 22:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_03",
    name: "Sophia Chen",
    phone: "+1 555 456 7890",
    email: "sophia.c@example.test",
    role: "Waiter",
    department: "Dining Hall",
    availableFrom: "11:00",
    availableTo: "22:00",
    availableHours: "11:00 - 22:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_04",
    name: "David Miller",
    phone: "+1 555 567 8901",
    email: "david.m@example.test",
    role: "Waiter",
    department: "Dining Hall",
    availableFrom: "11:00",
    availableTo: "21:00",
    availableHours: "11:00 - 21:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_05",
    name: "Carlos Ruiz",
    phone: "+1 555 678 9012",
    email: "carlos.r@example.test",
    role: "Kitchen Staff",
    department: "Kitchen",
    availableFrom: "09:00",
    availableTo: "21:00",
    availableHours: "09:00 - 21:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_06",
    name: "Aisha Patel",
    phone: "+1 555 789 0123",
    email: "aisha.p@example.test",
    role: "Cashier",
    department: "Counter",
    availableFrom: "10:00",
    availableTo: "20:00",
    availableHours: "10:00 - 20:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_07",
    name: "Liam O'Connor",
    phone: "+1 555 890 1234",
    email: "liam.o@example.test",
    role: "Kitchen Staff",
    department: "Kitchen",
    availableFrom: "12:00",
    availableTo: "23:00",
    availableHours: "12:00 - 23:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_08",
    name: "Grace Hopper",
    phone: "+1 555 901 2345",
    email: "grace.h@example.test",
    role: "Cleaner",
    department: "Sanitation",
    availableFrom: "08:00",
    availableTo: "17:00",
    availableHours: "08:00 - 17:00",
    maxDailyHours: 8,
  },
  {
    id: "staff_09",
    name: "Noah Bennett",
    phone: "+1 555 012 3456",
    email: "noah.b@example.test",
    role: "Waiter",
    department: "Dining Hall",
    status: "Inactive",
    availableFrom: "14:00",
    availableTo: "22:00",
    availableHours: "14:00 - 22:00",
    maxDailyHours: 6,
  },
];

const peakHours = [
  ["peak_01", "Monday", "18:00", "21:00", "High", 6, 8],
  ["peak_02", "Tuesday", "18:00", "20:00", "High", 5, 7],
  ["peak_03", "Wednesday", "18:00", "21:00", "Normal", 4, 6],
  ["peak_04", "Thursday", "18:30", "21:30", "High", 6, 8],
  ["peak_05", "Friday", "18:00", "22:00", "Very High", 7, 9],
  ["peak_06", "Saturday", "18:00", "22:00", "Very High", 8, 10],
  ["peak_07", "Sunday", "12:00", "15:30", "High", 6, 8],
].map(([id, dayOfWeek, startTime, endTime, demandLevel, minStaff, recommendedStaff]) => ({
  id,
  restaurantId: RESTAURANT_ID,
  dayOfWeek,
  startTime,
  endTime,
  demandLevel,
  minStaff,
  recommendedStaff,
  status: "Enabled",
  ...TEST_FIELD,
}));

const rules = [
  ["rule_01", 0, 5, "Low", 2, 1],
  ["rule_02", 6, 15, "Normal", 4, 2],
  ["rule_03", 16, 30, "High", 6, 3],
  ["rule_04", 31, 999, "Very High", 8, 4],
].map(([id, minCustomers, maxCustomers, demandLevel, recommendedStaff, minimumStaff]) => ({
  id,
  restaurantId: RESTAURANT_ID,
  minCustomers,
  maxCustomers,
  demandLevel,
  recommendedStaff,
  minimumStaff,
  status: "Active",
  ...TEST_FIELD,
}));

function localDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

async function seed() {
  const collections = [
    "staff",
    "staff_allocations",
    "peak_hour_configs",
    "staff_allocation_rules",
  ];

  // Safety check: do not mix these test records into a restaurant
  // that already has records in any target collection.
  for (const name of collections) {
    const existing = await db.collection(name)
      .where("restaurantId", "==", RESTAURANT_ID)
      .limit(1)
      .get();

    if (!existing.empty) {
      throw new Error(
        `Stopped safely: ${name} already contains data for ${RESTAURANT_ID}. ` +
        "No records were added. Use a separate development Firebase project."
      );
    }
  }

  const today = localDateString();
  const allocations = [
    {
      id: "alloc_01",
      date: today,
      startTime: "10:00",
      endTime: "16:00",
      staffId: "staff_01",
      staffName: "Elena Rostova",
      staffRole: "Manager",
      assignedArea: "Front Desk & Floor",
      shiftType: "Normal",
      status: "Active",
      notes: "Opening shift supervisor",
    },
    {
      id: "alloc_02",
      date: today,
      startTime: "12:00",
      endTime: "18:00",
      staffId: "staff_03",
      staffName: "Sophia Chen",
      staffRole: "Waiter",
      assignedArea: "Main Dining Section A",
      shiftType: "Normal",
      status: "Active",
      notes: "Dining floor coverage",
    },
    {
      id: "alloc_03",
      date: today,
      startTime: "12:00",
      endTime: "18:00",
      staffId: "staff_04",
      staffName: "David Miller",
      staffRole: "Waiter",
      assignedArea: "Patio & Section B",
      shiftType: "Normal",
      status: "Scheduled",
      notes: "Outdoor area support",
    },
    {
      id: "alloc_04",
      date: today,
      startTime: "10:00",
      endTime: "18:00",
      staffId: "staff_06",
      staffName: "Aisha Patel",
      staffRole: "Cashier",
      assignedArea: "Billing Counter",
      shiftType: "Normal",
      status: "Active",
      notes: "Billing counter coverage",
    },
  ].map((item) => ({
    ...item,
    restaurantId: RESTAURANT_ID,
    createdAt: new Date().toISOString(),
    ...TEST_FIELD,
  }));

  const batch = db.batch();
  const now = new Date().toISOString();

  for (const member of staff) {
    batch.create(db.collection("staff").doc(member.id), {
      ...member,
      restaurantId: RESTAURANT_ID,
      status: member.status || "Active",
      createdAt: now,
      ...TEST_FIELD,
    });
  }

  for (const item of allocations) {
    batch.create(db.collection("staff_allocations").doc(item.id), item);
  }

  for (const item of peakHours) {
    batch.create(db.collection("peak_hour_configs").doc(item.id), item);
  }

  for (const item of rules) {
    batch.create(db.collection("staff_allocation_rules").doc(item.id), item);
  }

  await batch.commit();

  console.log("Test data added successfully.");
  console.log(`Restaurant: ${RESTAURANT_ID}`);
  console.log(`Staff: ${staff.length}`);
  console.log(`Allocations: ${allocations.length}`);
  console.log(`Peak-hour configurations: ${peakHours.length}`);
  console.log(`Allocation rules: ${rules.length}`);
  console.log(`Allocation date: ${today}`);
}

seed()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seed failed:", error.message);
    process.exit(1);
  });
