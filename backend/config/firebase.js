// config/firebase.js
const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json'); // ถอยกลับ 1 โฟลเดอร์เพื่อหาไฟล์

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ส่งออก db และ admin ไปให้ไฟล์อื่นใช้งาน
module.exports = { db, admin };