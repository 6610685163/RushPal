const { db } = require('./config/firebase');

const items = [
  { name: 'Red Cap', price: 500, category: 'Head', model: 'assets/models/guy.glb' },
  { name: 'Blue Shirt', price: 1200, category: 'Body', model: 'assets/models/guy.glb' },
  { name: 'Running Shoes', price: 800, category: 'Shoes', model: 'assets/models/guy.glb' }
];

async function seedData() {
  for (const item of items) {
    await db.collection('shop_items').add(item);
    console.log(`เพิ่ม ${item.name} เรียบร้อย!`);
  }
  process.exit();
}

seedData();