const express = require('express');
const router = express.Router();
const runController = require('../controllers/runController');

router.post('/', runController.saveRunResult);
router.get('/stats/:user_id', runController.getUserStats);

// 💡 2 บรรทัดที่เพิ่มใหม่สำหรับระบบ Daily Quest
router.get('/quest/:user_id', runController.getQuestStatus);
router.post('/claim', runController.claimQuest);

module.exports = router;