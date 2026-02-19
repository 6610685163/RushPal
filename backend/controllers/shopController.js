// controllers/shopController.js
const { db, admin } = require('../config/firebase');

// Function to buy an item
const buyItem = async (req, res) => {
  const { uid, itemId } = req.body;

  if (!uid || !itemId) {
    return res.status(400).json({ error: 'Missing uid or itemId' });
  }

  const userRef = db.collection('users').doc(uid);
  const itemRef = db.collection('shop_items').doc(itemId);

  try {
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      const itemDoc = await transaction.get(itemRef);

      if (!userDoc.exists) throw new Error('User not found');
      if (!itemDoc.exists) throw new Error('Item not found in the shop');

      const userData = userDoc.data();
      const itemData = itemDoc.data();

      const inventory = userData.inventory || [];
      if (inventory.includes(itemId)) {
        throw new Error('You already own this item');
      }

      const currentPoints = userData.points || 0;
      const itemPrice = itemData.price || 0;
      
      if (currentPoints < itemPrice) {
        throw new Error('Insufficient points');
      }

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


// Function to fetch market items and check ownership status
const getMarketItems = async (req, res) => {
  const { uid } = req.params; // Get user uid from URL parameter

  if (!uid) {
    return res.status(400).json({ error: 'uid is required' });
  }

  try {
    // 1. Fetch user data to check their inventory
    const userDoc = await db.collection('users').doc(uid).get();
    const inventory = userDoc.exists ? (userDoc.data().inventory || []) : [];

    // 2. Fetch all shop items from the database
    const shopSnapshot = await db.collection('shop_items').get();
    
    // 3. Restructure data to match Flutter frontend requirements
    const marketItems = {
      'Head': [],
      'Body': [],
      'Legs': [],
      'Shoes': []
    };

    shopSnapshot.forEach(doc => {
      const item = doc.data();
      // Check if the user already owns this item
      const isOwned = inventory.includes(doc.id);

      // Group items by category
      if (marketItems[item.category]) {
        marketItems[item.category].push({
          id: doc.id,
          name: item.name || '',
          price: item.price || 0,
          owned: isOwned,
          model: item.model || 'assets/models/guy.glb',
          image: item.image || ''
        });
      }
    });

    // Send data back to the app
    res.status(200).json({
      success: true,
      points: userDoc.exists ? userDoc.data().points : 0, // Send user points to update the UI
      marketItems: marketItems
    });

  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

module.exports = { buyItem, getMarketItems };