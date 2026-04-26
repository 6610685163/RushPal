const express = require('express');
const router = express.Router();
const friendController = require('../controllers/friendController');

// กำหนดเส้นทาง POST /api/friends/search
router.post('/search', friendController.searchFriend);
router.post('/list', friendController.getFriendsList);

// 🌟 เส้นทางใหม่สำหรับระบบ Request
router.post('/request/send', friendController.sendRequest);
router.post('/request/accept', friendController.acceptRequest);
router.post('/request/decline', friendController.declineRequest);
router.post('/request/list', friendController.getPendingRequests);
router.post('/remove', friendController.removeFriend);

module.exports = router;