// server.js
const express = require('express');
const cors = require('cors');
const shopRoutes = require('./routes/shopRoutes'); // นำเข้า routes ร้านค้า
const friendRoutes = require('./routes/friendRoutes');
const partyRoutes = require('./routes/partyRoutes');

const app = express();

app.use(cors());
app.use(express.json());

// บอกให้แอปใช้งานเส้นทาง API ของร้านค้า โดยนำหน้าด้วย /api/shop
app.use('/api/shop', shopRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/parties', partyRoutes);

// ทดสอบเซิร์ฟเวอร์
app.get('/', (req, res) => {
  res.send('Running App Backend is Online! 🏃‍♂️');
});

// Quest routes — mount ก่อน /api/runs เพื่อให้ Express จับได้แน่นอน
const runController = require('./controllers/runController');
app.get('/api/runs/quest/:user_id', runController.getQuestStatus);
app.post('/api/runs/claim', runController.claimQuest);

const runRoutes = require('./routes/runRoutes');
app.use('/api/runs', runRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});