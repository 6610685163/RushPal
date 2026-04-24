// routes/shopRoutes.js
const express = require('express');
const router = express.Router();
const { buyItem, getMarketItems } = require('../controllers/shopController');

// เมื่อมีคนยิง POST มาที่ /buy ให้ไปทำงานที่ฟังก์ชัน buyItem
router.post('/buy', buyItem);
router.get('/items/:uid', getMarketItems);

module.exports = router;

