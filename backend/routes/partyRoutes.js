const express = require('express');
const router = express.Router();
const partyController = require('../controllers/partyController');

// เส้นทางสำหรับสร้างและเข้าร่วมห้อง
router.post('/create', partyController.createParty);
router.post('/invite', partyController.inviteFriend);
router.post('/accept', partyController.acceptInvite);
router.post('/join-by-code', partyController.joinPartyByCode);
router.post('/ready', partyController.toggleReady);
router.post('/leave', partyController.leaveParty);
router.post('/start', partyController.startParty);
router.get('/details/:partyCode', partyController.getPartyDetails); // เพิ่มบรรทัดนี้ เพื่อเปิดทางให้แอปดึงข้อมูลสมาชิกได้

module.exports = router;