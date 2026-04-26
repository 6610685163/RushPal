const { db, admin } = require('../config/firebase');

// ฟังก์ชันซื้อไอเทม
const buyItem = async (req, res) => {
  const { uid, itemId } = req.body;
  if (!uid || !itemId) return res.status(400).json({ error: 'Missing uid or itemId' });

  const userRef = db.collection('users').doc(uid);
  const itemRef = db.collection('shop_items').doc(itemId);

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const itemDoc = await transaction.get(itemRef);

      if (!userDoc.exists) throw new Error('User not found');
      if (!itemDoc.exists) throw new Error('Item not found in the shop');

      const userData = userDoc.data();
      const inventory = userData.inventory || [];
      if (inventory.includes(itemId)) throw new Error('You already own this item');

      const currentPoints = userData.points || 0;
      const itemPrice = itemDoc.data().price || 0;
      if (currentPoints < itemPrice) throw new Error('Insufficient points');

      transaction.update(userRef, {
        points: currentPoints - itemPrice,
        inventory: admin.firestore.FieldValue.arrayUnion(itemId)
      });
    });
    res.status(200).json({ success: true, message: 'Purchase successful!' });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
};

// ฟังก์ชันโหลดข้อมูลร้านค้า
const getMarketItems = async (req, res) => {
  const { uid } = req.params;
  if (!uid) return res.status(400).json({ error: 'uid is required' });

  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.exists ? userDoc.data() : {};
    const inventory = userData.inventory || [];

    const shopSnapshot = await db.collection('shop_items').get();
    
    // โครงสร้างหมวดหมู่ใหม่
    const marketItems = { 'Skin': [], 'Idle': [], 'Ready': [] };

    shopSnapshot.forEach(doc => {
      const item = doc.data();
      const isOwned = inventory.includes(doc.id);

      if (marketItems[item.category]) {
        marketItems[item.category].push({
          id: doc.id,
          name: item.name || '',
          price: item.price || 0,
          owned: isOwned,
          model: item.model || '',
          animation_key: item.animation_key || '',
          character_id: item.character_id || ''
        });
      }
    });

    res.status(200).json({
      success: true,
      points: userData.points || 0,
      equipped_skin: userData.equipped_skin || '',
      equipped_idle: userData.equipped_idle || 'idle', // ค่าเริ่มต้นคือท่าชื่อ idle
      equipped_ready: userData.equipped_ready || 'ready', // ค่าเริ่มต้นคือท่าชื่อ ready
      marketItems: marketItems
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// สำหรับกด "สวมใส่" สกิน หรือ ท่าทาง
const equipItem = async (req, res) => {
  const { uid, category, itemKeyOrId } = req.body;
  
  if (!uid || !category || !itemKeyOrId) {
      return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
      const userRef = db.collection('users').doc(uid);
      let updateData = {};
      
      // เช็คว่ากำลังใส่หมวดไหน แล้วอัปเดตฟิลด์นั้น
      if (category === 'Skin') updateData.equipped_skin = itemKeyOrId;
      else if (category === 'idle') updateData.equipped_idle = itemKeyOrId;
      else if (category === 'ready') updateData.equipped_ready = itemKeyOrId;

      await userRef.update(updateData);
      res.status(200).json({ success: true, message: 'Equipped successfully' });
  } catch (error) {
      res.status(500).json({ success: false, error: error.message });
  }
};

module.exports = { buyItem, getMarketItems, equipItem };