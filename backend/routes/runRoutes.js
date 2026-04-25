const express = require('express');
const router = express.Router();
const runController = require('../controllers/runController');

router.post('/', runController.saveRunResult);
router.get('/stats/:user_id', runController.getUserStats);

module.exports = router;