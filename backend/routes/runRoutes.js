const express = require('express');
const router = express.Router();
const runController = require('../controllers/runController');

// POST: บันทึกวิ่ง
router.post('/', runController.saveRunResult);

// GET: ดึงข้อมูลสถิติ (👇 เพิ่มบรรทัดนี้)
router.get('/stats/:user_id', runController.getUserStats);

module.exports = router;