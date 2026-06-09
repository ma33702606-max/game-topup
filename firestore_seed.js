/**
 * GameTopup — Firestore Seed Script
 *
 * Usage:
 *   npm install firebase-admin
 *   node firestore_seed.js
 *
 * Prerequisites:
 *   1. Download Service Account key from Firebase Console →
 *      Project Settings → Service Accounts → Generate new private key
 *   2. Save as "serviceAccountKey.json" in the same folder as this script
 *   3. Update PROJECT_ID below
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

const PROJECT_ID = 'YOUR_PROJECT_ID'; // ← replace

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: PROJECT_ID,
});

const db = admin.firestore();

// ─── Data ─────────────────────────────────────────────────────────────────────

const GAMES = [
  {
    id: 'pubg',
    name: 'PUBG Mobile',
    shortName: 'PUBG',
    currency: 'UC',
    gradientKey: 'pubg',
    sortOrder: 1,
    isActive: true,
    packages: [
      { name: '60 UC',    price: 30,  amount: 60,  isPopular: false, isActive: true },
      { name: '325 UC',   price: 100, amount: 325, isPopular: false, isActive: true },
      { name: '660 UC',   price: 200, amount: 660, isPopular: true,  isActive: true },
      { name: '1800 UC',  price: 500, amount: 1800, isPopular: false, isActive: true },
      { name: '3850 UC',  price: 1000, amount: 3850, isPopular: false, isActive: true },
      { name: '8100 UC',  price: 2000, amount: 8100, isPopular: false, isActive: true },
    ],
  },
  {
    id: 'freefire',
    name: 'Free Fire',
    shortName: 'FF',
    currency: 'Diamonds',
    gradientKey: 'freeFire',
    sortOrder: 2,
    isActive: true,
    packages: [
      { name: '100 الماس',  price: 25,  amount: 100,  isPopular: false, isActive: true },
      { name: '310 الماس',  price: 75,  amount: 310,  isPopular: false, isActive: true },
      { name: '520 الماس',  price: 120, amount: 520,  isPopular: true,  isActive: true },
      { name: '1060 الماس', price: 240, amount: 1060, isPopular: false, isActive: true },
      { name: '2180 الماس', price: 480, amount: 2180, isPopular: false, isActive: true },
      { name: '5600 الماس', price: 1200, amount: 5600, isPopular: false, isActive: true },
    ],
  },
  {
    id: 'efootball',
    name: 'eFootball',
    shortName: 'eFB',
    currency: 'eFootball Coins',
    gradientKey: 'efootball',
    sortOrder: 3,
    isActive: true,
    packages: [
      { name: '80 Coins',   price: 30,  amount: 80,  isPopular: false, isActive: true },
      { name: '200 Coins',  price: 70,  amount: 200, isPopular: false, isActive: true },
      { name: '500 Coins',  price: 160, amount: 500, isPopular: true,  isActive: true },
      { name: '1200 Coins', price: 380, amount: 1200, isPopular: false, isActive: true },
      { name: '2500 Coins', price: 780, amount: 2500, isPopular: false, isActive: true },
    ],
  },
  {
    id: 'eafc',
    name: 'EA FC Mobile',
    shortName: 'EAFC',
    currency: 'FC Points',
    gradientKey: 'eafc',
    sortOrder: 4,
    isActive: true,
    packages: [
      { name: '100 FC Points',  price: 40,  amount: 100, isPopular: false, isActive: true },
      { name: '250 FC Points',  price: 90,  amount: 250, isPopular: false, isActive: true },
      { name: '500 FC Points',  price: 180, amount: 500, isPopular: true,  isActive: true },
      { name: '1050 FC Points', price: 360, amount: 1050, isPopular: false, isActive: true },
      { name: '2800 FC Points', price: 900, amount: 2800, isPopular: false, isActive: true },
    ],
  },
];

const BANNERS = [
  {
    title: 'عروض PUBG الحصرية',
    subtitle: 'أسعار لا تُفوَّت على UC',
    gradientKey: 'pubg',
    sortOrder: 1,
    isActive: true,
  },
  {
    title: 'Free Fire — احترف اللعبة',
    subtitle: 'اشحن الماس بأفضل الأسعار',
    gradientKey: 'freeFire',
    sortOrder: 2,
    isActive: true,
  },
  {
    title: 'EA FC Mobile',
    subtitle: 'شحن FC Points فوري',
    gradientKey: 'eafc',
    sortOrder: 3,
    isActive: true,
  },
];

const PAYMENT_SETTINGS = {
  bankily: {
    accountNumber: '22XXXXXXXX',
    accountName: 'اسم صاحب الحساب',
  },
  masrivi: {
    accountNumber: '22XXXXXXXX',
    accountName: 'اسم صاحب الحساب',
  },
  sedad: {
    accountNumber: '22XXXXXXXX',
    accountName: 'اسم صاحب الحساب',
  },
};

// ─── Seed Functions ───────────────────────────────────────────────────────────

async function seedGames() {
  console.log('🎮 Seeding games...');
  for (const game of GAMES) {
    const { packages, ...gameData } = game;
    const gameRef = db.collection('games').doc(game.id);
    await gameRef.set({
      ...gameData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✓ Game: ${game.name}`);

    for (const pkg of packages) {
      await gameRef.collection('packages').add({
        ...pkg,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    console.log(`    → Added ${packages.length} packages`);
  }
}

async function seedBanners() {
  console.log('🖼️  Seeding banners...');
  for (const banner of BANNERS) {
    await db.collection('banners').add({
      ...banner,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✓ Banner: ${banner.title}`);
  }
}

async function seedPaymentSettings() {
  console.log('💳 Seeding payment settings...');
  await db.collection('settings').doc('payment').set(PAYMENT_SETTINGS);
  console.log('  ✓ Payment settings saved');
}

async function main() {
  try {
    console.log('\n🚀 Starting GameTopup seed...\n');
    await seedGames();
    await seedBanners();
    await seedPaymentSettings();
    console.log('\n✅ Seed complete!\n');
    console.log('⚠️  Remember to:');
    console.log('   1. Set a user as admin in Firestore Console:');
    console.log('      users/{uid} → role: "admin"');
    console.log('   2. Update payment account numbers in the app settings');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seed failed:', err);
    process.exit(1);
  }
}

main();
