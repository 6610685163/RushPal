// server.js
const express = require('express');
const cors = require('cors');
const shopRoutes = require('./routes/shopRoutes'); // นำเข้า routes ร้านค้า

const app = express();

app.use(cors());
app.use(express.json());

// บอกให้แอปใช้งานเส้นทาง API ของร้านค้า โดยนำหน้าด้วย /api/shop
app.use('/api/shop', shopRoutes);

// ทดสอบเซิร์ฟเวอร์
app.get('/', (req, res) => {
  res.send('Running App Backend is Online! 🏃‍♂️');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});