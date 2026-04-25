const admin = require('firebase-admin');
const db = admin.firestore();

exports.searchFriend = async (req, res) => {
    try {
        const { username } = req.body;

        if (!username) {
            return res.status(400).json({ error: 'Username is required' });
        }

        const usersRef = db.collection('users');
        const snapshot = await usersRef.where('username', '==', username).get();

        if (snapshot.empty) {
            return res.status(404).json({ error: 'User not found' });
        }

        let foundUser = null;
        snapshot.forEach(doc => {
            foundUser = {
                uid: doc.id,
                username: doc.data().username,
                skinId: doc.data().skinId,
                level: doc.data().level || 1
            };
        });

        res.status(200).json({ user: foundUser });
    } catch (error) {
        console.error('Error searching for friend:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });

    }
};

exports.sendRequest = async (req, res) => {
    try {
        const { myUid, friendUid } = req.body;
        const usersRef = db.collection('users');

        // เอา UID ของเราไปหย่อนไว้ในตู้จดหมาย (friendRequests) ของเพื่อน
        await usersRef.doc(friendUid).update({
            friendRequests: admin.firestore.FieldValue.arrayUnion(myUid)
        });

        res.status(200).json({ message: "ส่งคำขอเป็นเพื่อนแล้ว" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

exports.acceptRequest = async (req, res) => {
    try {
        const { myUid, friendUid } = req.body;
        const usersRef = db.collection('users');

        // 1. เพิ่มเพื่อนในลิสต์ของเรา และลบคำขอออก
        await usersRef.doc(myUid).update({
            friends: admin.firestore.FieldValue.arrayUnion(friendUid),
            friendRequests: admin.firestore.FieldValue.arrayRemove(friendUid)
        });

        // 2. เพิ่มเราในลิสต์ของเพื่อนด้วย
        await usersRef.doc(friendUid).update({
            friends: admin.firestore.FieldValue.arrayUnion(myUid)
        });

        res.status(200).json({ message: "ตอบรับเป็นเพื่อนสำเร็จ" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

exports.getPendingRequests = async (req, res) => {
    try {
        const { uid } = req.body;
        const userDoc = await db.collection('users').doc(uid).get();
        const requestsUIDs = userDoc.data().friendRequests || [];

        if (requestsUIDs.length === 0) return res.status(200).json([]);

        const requestsList = [];
        const snapshot = await db.collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', requestsUIDs).get();

        snapshot.forEach(doc => {
            requestsList.push({
                uid: doc.id,
                username: doc.data().username,
                level: doc.data().level || 1
            });
        });

        res.status(200).json(requestsList);
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

// ฟังก์ชันดึงรายชื่อเพื่อนทั้งหมด
exports.getFriendsList = async (req, res) => {
    try {
        const { uid } = req.body;

        if (!uid) {
            return res.status(400).json({ message: "กรุณาส่ง UID มาด้วย" });
        }

        // 1. ไปดึงข้อมูลตัวเราเองเพื่อเอา Array รายชื่อ UID เพื่อน
        const userDoc = await db.collection('users').doc(uid).get();

        if (!userDoc.exists) {
            return res.status(404).json({ message: "ไม่พบผู้ใช้ในระบบ" });
        }

        const friendsUIDs = userDoc.data().friends || [];

        if (friendsUIDs.length === 0) {
            return res.status(200).json([]); // คืนค่าลิสต์ว่างถ้ายังไม่มีเพื่อน
        }

        // 2. ไปดึงรายละเอียด (ชื่อ, เลเวล) ของ UID ทุกตัวที่อยู่ในลิสต์เพื่อน
        const friendsList = [];
        // Firestore 'in' query ค้นหาได้สูงสุดครั้งละ 30 ids
        const snapshot = await db.collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', friendsUIDs)
            .get();

        snapshot.forEach(doc => {
            friendsList.push({
                uid: doc.id,
                username: doc.data().username,
                level: doc.data().level || 1,
                skinId: doc.data().skinId
            });
        });

        res.status(200).json(friendsList);

    } catch (error) {
        console.error("Error fetching friends:", error);
        res.status(500).json({ message: "เกิดข้อผิดพลาด", error: error.message });
    }
};