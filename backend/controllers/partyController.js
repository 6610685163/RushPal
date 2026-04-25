const admin = require('firebase-admin');
const db = admin.firestore();

function generatePartyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 5; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
}

// 1. สร้างห้องปาร์ตี้ (Create Party)
exports.createParty = async (req, res) => {
    try {
        const { uid, username, skinId } = req.body;

        if (!uid || !username) {
            return res.status(400).json({ message: "ข้อมูลไม่ครบถ้วน" });
        }

        const partyCode = generatePartyCode();

        const newParty = {
            hostUid: uid,
            partyCode: partyCode,
            status: 'waiting', // สถานะ: กำลังรอเพื่อน
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            members: {
                // เก็บข้อมูล Host (คนสร้างห้อง) เป็นสมาชิกคนแรก
                [uid]: {
                    username: username,
                    skinId: skinId || "skin_m_1",
                    distanceKm: 0.0,
                    durationSec: 0,
                    isReady: false, // ยังไม่ได้กดพร้อม
                    isLeader: true // เป็นหัวหน้าห้อง
                }
            }
        };

        await db.collection('parties').doc(partyCode).set(newParty);

        res.status(200).json({ message: "สร้างห้องสำเร็จ", partyId: partyCode });

    } catch (error) {
        console.error("Error creating party:", error);
        res.status(500).json({ message: "สร้างห้องไม่สำเร็จ", error: error.message });
    }
};

// 2. เชิญเพื่อนเข้าปาร์ตี้ (Invite Friend)
exports.inviteFriend = async (req, res) => {
    try {
        const { myPartyId, friendUid, myUsername } = req.body;

        // เอาบัตรเชิญไปใส่ใน Document 'users' ของเพื่อน
        await db.collection('users').doc(friendUid).update({
            // ใช้ arrayUnion เพื่อให้เพื่อนรับคำเชิญได้หลายห้องพร้อมกัน
            partyInvites: admin.firestore.FieldValue.arrayUnion({
                partyId: myPartyId,
                hostName: myUsername,
                timestamp: Date.now()
            })
        });

        res.status(200).json({ message: "ส่งคำเชิญแล้ว!" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

// 3. ยอมรับคำเชิญเข้าห้อง (Accept Invite)
exports.acceptInvite = async (req, res) => {
    try {
        const { partyId, myUid, myUsername, mySkinId, inviteObject } = req.body;

        const partyRef = db.collection('parties').doc(partyId);
        const partyDoc = await partyRef.get();

        if (!partyDoc.exists || partyDoc.data().status !== 'waiting') {
            return res.status(400).json({ message: "ห้องนี้ถูกปิดหรือเริ่มวิ่งไปแล้ว" });
        }

        // 1. เพิ่มตัวเราเข้าไปในห้องปาร์ตี้ของเพื่อน
        await partyRef.update({
            [`members.${myUid}`]: {
                username: myUsername,
                skinId: mySkinId || "skin_m_1",
                distanceKm: 0.0,
                durationSec: 0,
                isReady: false
            }
        });

        // 2. ลบบัตรเชิญออกจากหน้าต่างแจ้งเตือนของเรา
        await db.collection('users').doc(myUid).update({
            partyInvites: admin.firestore.FieldValue.arrayRemove(inviteObject)
        });

        res.status(200).json({ message: "เข้าห้องสำเร็จ", partyId: partyId });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

// 4. เข้าร่วมห้องด้วยการกรอกรหัส (Join by Code)
exports.joinPartyByCode = async (req, res) => {
    try {
        const { partyCode, uid, username, skinId } = req.body;

        // แปลงพิมพ์เล็กเป็นพิมพ์ใหญ่ ป้องกันคนพิมพ์ผิด
        const codeToJoin = partyCode.toUpperCase();

        const partyRef = db.collection('parties').doc(codeToJoin);
        const partyDoc = await partyRef.get();

        // เช็คว่าห้องมีจริงไหม และเริ่มไปหรือยัง
        if (!partyDoc.exists || partyDoc.data().status !== 'waiting') {
            return res.status(400).json({ message: "ไม่พบรหัสห้องนี้ หรือปาร์ตี้เริ่มวิ่งไปแล้ว" });
        }

        // จับยัดเข้าปาร์ตี้
        await partyRef.update({
            [`members.${uid}`]: {
                username: username,
                skinId: skinId || "skin_m_1",
                distanceKm: 0.0,
                durationSec: 0,
                isReady: false, // เพิ่งเข้าห้องมา ต้องกด Ready ทีหลัง
                isLeader: false
            }
        });

        res.status(200).json({ message: "เข้าร่วมปาร์ตี้สำเร็จ", partyId: codeToJoin });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

// 5. สลับสถานะ Ready (Toggle Ready)
exports.toggleReady = async (req, res) => {
    try {
        const { partyCode, uid, isReady } = req.body;

        // อัปเดตแค่ฟิลด์ isReady ของคนๆ นั้นใน Object members
        await db.collection('parties').doc(partyCode).update({
            [`members.${uid}.isReady`]: isReady
        });

        res.status(200).json({ message: "อัปเดตสถานะพร้อมสำเร็จ" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

exports.leaveParty = async (req, res) => {
    try {
        const { partyCode, uid } = req.body;
        const partyRef = db.collection('parties').doc(partyCode);

        // 1. ลบชื่อเราออกจาก Object members
        await partyRef.update({
            [`members.${uid}`]: admin.firestore.FieldValue.delete()
        });

        // 2. (โบนัสความสะอาด) เช็คว่าถ้าคนออกไปหมดแล้ว ให้ลบห้องทิ้งไปเลย Database จะได้ไม่รก!
        const partyDoc = await partyRef.get();
        if (partyDoc.exists) {
            const currentMembers = partyDoc.data().members;
            if (Object.keys(currentMembers).length === 0) {
                await partyRef.delete();
                console.log(`🗑️ ลบห้อง ${partyCode} ทิ้งเพราะไม่มีคนอยู่แล้ว`);
            }
        }

        res.status(200).json({ message: "ออกจากปาร์ตี้สำเร็จ" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};

// 7. เริ่มวิ่ง (Start Party)
exports.startParty = async (req, res) => {
    try {
        const { partyCode } = req.body;

        // อัปเดตสถานะห้องให้เป็น running
        await db.collection('parties').doc(partyCode).update({
            status: 'running'
        });

        res.status(200).json({ message: "ปาร์ตี้เริ่มวิ่งแล้ว!" });
    } catch (error) {
        res.status(500).json({ message: "Error", error: error.message });
    }
};