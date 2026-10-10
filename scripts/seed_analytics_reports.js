const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp({ credential: applicationDefault() });

const db = getFirestore();
const restaurantId = "default_bistro_01";
const today = new Date().toISOString().slice(0, 10);
const now = new Date().toISOString();

const analyticsData = {
  turnover: {
    Today: [
      { label: "Table Group A", value: 4.2, displayValue: "4.2x" },
      { label: "Table Group B", value: 3.8, displayValue: "3.8x" },
      { label: "Table Group C", value: 3.1, displayValue: "3.1x" },
    ],
    "This Week": [
      { label: "Mon", value: 2.8, displayValue: "2.8x" },
      { label: "Wed", value: 3.4, displayValue: "3.4x" },
      { label: "Sat", value: 4.6, displayValue: "4.6x" },
    ],
    "This Month": [
      { label: "W1", value: 3.2, displayValue: "3.2x" },
      { label: "W2", value: 3.5, displayValue: "3.5x" },
      { label: "W3", value: 3.8, displayValue: "3.8x" },
    ],
  },
  waiting_time: {
    Today: [
      { label: "12 PM", value: 12, displayValue: "12m" },
      { label: "6 PM", value: 18, displayValue: "18m" },
      { label: "8 PM", value: 29, displayValue: "29m" },
    ],
    "This Week": [
      { label: "Mon", value: 14, displayValue: "14m" },
      { label: "Wed", value: 18, displayValue: "18m" },
      { label: "Sat", value: 31, displayValue: "31m" },
    ],
    "This Month": [
      { label: "W1", value: 19, displayValue: "19m" },
      { label: "W2", value: 21, displayValue: "21m" },
      { label: "W3", value: 17, displayValue: "17m" },
    ],
  },
  no_show: {
    Today: [
      { label: "Lunch", value: 2, displayValue: "2" },
      { label: "Early Dinner", value: 1, displayValue: "1" },
      { label: "Late Dinner", value: 3, displayValue: "3" },
    ],
    "This Week": [
      { label: "Mon", value: 2, displayValue: "2" },
      { label: "Wed", value: 4, displayValue: "4" },
      { label: "Sat", value: 7, displayValue: "7" },
    ],
    "This Month": [
      { label: "W1", value: 3, displayValue: "3" },
      { label: "W2", value: 5, displayValue: "5" },
      { label: "W3", value: 2, displayValue: "2" },
    ],
  },
  peak_hours: {
    Today: [
      { label: "12 PM", value: 32, displayValue: "32" },
      { label: "6 PM", value: 54, displayValue: "54" },
      { label: "8 PM", value: 68, displayValue: "68" },
    ],
    "This Week": [
      { label: "Mon", value: 340, displayValue: "340" },
      { label: "Wed", value: 410, displayValue: "410" },
      { label: "Sat", value: 520, displayValue: "520" },
    ],
    "This Month": [
      { label: "W1", value: 340, displayValue: "340" },
      { label: "W2", value: 410, displayValue: "410" },
      { label: "W3", value: 460, displayValue: "460" },
    ],
  },
  walk_away: {
    Today: [
      { label: "12 PM", value: 2, displayValue: "2" },
      { label: "6 PM", value: 3, displayValue: "3" },
      { label: "8 PM", value: 8, displayValue: "8" },
    ],
    "This Week": [
      { label: "Mon", value: 3, displayValue: "3" },
      { label: "Wed", value: 4, displayValue: "4" },
      { label: "Sat", value: 8, displayValue: "8" },
    ],
    "This Month": [
      { label: "W1", value: 5, displayValue: "5" },
      { label: "W2", value: 7, displayValue: "7" },
      { label: "W3", value: 4, displayValue: "4" },
    ],
  },
};

async function createIfMissing(collection, id, data) {
  const ref = db.collection(collection).doc(id);
  const existing = await ref.get();

  if (existing.exists) {
    console.log(`Skipped existing: ${collection}/${id}`);
    return false;
  }

  await ref.create(data);
  return true;
}

async function main() {
  let analyticsCreated = 0;
  let reportsCreated = 0;

  for (const [type, periods] of Object.entries(analyticsData)) {
    for (const [period, records] of Object.entries(periods)) {
      for (let i = 0; i < records.length; i++) {
        const record = records[i];
        const id = `sample_${type}_${period
          .toLowerCase()
          .replace(/\s+/g, "_")}_${i + 1}`;

        const created = await createIfMissing("analytics", id, {
          restaurantId,
          date: today,
          type,
          period,
          label: record.label,
          value: record.value,
          displayValue: record.displayValue,
          isTestData: true,
        });

        if (created) analyticsCreated++;
      }
    }
  }

  const samples = [
    {
      id: "sample_sales_report",
      title: "Sample Daily Sales Report",
      type: "Sales Report",
      summary: "Sample report data for interface testing. Not actual sales.",
      details: [
        { metric: "Sample sales", value: "125000.00" },
        { metric: "Sample order count", value: "42" },
      ],
    },
    {
      id: "sample_orders_report",
      title: "Sample Orders Report",
      type: "Orders Report",
      summary: "Sample order summary for interface testing.",
      details: [
        { orderId: "SAMPLE-001", date: today, status: "Completed", total: 2500 },
        { orderId: "SAMPLE-002", date: today, status: "Completed", total: 3800 },
      ],
    },
    {
      id: "sample_staff_report",
      title: "Sample Staff Report",
      type: "Staff Report",
      summary: "Sample staff report for demonstration.",
      details: [
        { name: "Sample Staff A", role: "Server", status: "Active" },
        { name: "Sample Staff B", role: "Chef", status: "Active" },
      ],
    },
    {
      id: "sample_staff_allocation_report",
      title: "Sample Staff Allocation Report",
      type: "Staff Allocation Report",
      summary: "Sample allocation report for demonstration.",
      details: [
        {
          staffName: "Sample Staff A",
          staffId: "sample_staff_a",
          date: today,
          startTime: "12:00",
          endTime: "20:00",
        },
      ],
    },
    {
      id: "sample_inventory_report",
      title: "Sample Inventory Report",
      type: "Inventory Report",
      summary: "Sample inventory report for interface testing.",
      details: [
        { item: "Sample ingredient A", quantity: 25, unit: "kg" },
        { item: "Sample ingredient B", quantity: 40, unit: "units" },
      ],
    },
  ];

  for (const report of samples) {
    const created = await createIfMissing("reports", report.id, {
      restaurantId,
      title: report.title,
      type: report.type,
      date: today,
      dateRange: today,
      summary: report.summary,
      details: report.details,
      createdAt: now,
      isTestData: true,
    });

    if (created) reportsCreated++;
  }

  console.log("\nTest data seeding finished.");
  console.log(`Analytics records created: ${analyticsCreated}`);
  console.log(`Sample reports created: ${reportsCreated}`);
  console.log(`Restaurant: ${restaurantId}`);
  console.log("Existing documents were not overwritten.");
}

main().catch((error) => {
  console.error("Seeding failed:", error);
  process.exitCode = 1;
});