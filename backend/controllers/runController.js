const supabase = require('../config/supabase');
const admin = require('firebase-admin');

exports.saveRunResult = async (req, res) => {
    try {
        // 💡 1. เพิ่มการรับค่า partycode เข้ามา
        const { user_id, distance, pace, duration_seconds, calories, partycode } = req.body;

        // 💡 2. บันทึกประวัติการวิ่งลง Supabase พร้อม partycode
        const { data, error } = await supabase
            .from('runs')
            .insert([{ user_id, distance, pace, duration_seconds, calories, partycode }]);

        if (error) throw error;

        const earnedGold = Math.floor(distance * 100); 
        const earnedExp = Math.floor(distance * 1000); 

        const db = admin.firestore();
        const userRef = db.collection('users').doc(user_id);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
            let userData = userDoc.data();
            let currentLevel = userData.level || 1;
            let currentExp = userData.exp ?? 0;  // ใช้ ?? แทน || เพื่อรองรับ exp = 0
            let currentPoints = userData.points || 0;

            currentExp += earnedExp;

            let totalLevelUpBonus = 0; 
            let expNeeded = currentLevel * 50;

            while (currentExp >= expNeeded) {
                currentExp -= expNeeded; 
                currentLevel++; 
                let levelReward = 100 + (currentLevel - 2) * 20;
                totalLevelUpBonus += levelReward;
                expNeeded = currentLevel * 50; 
            }

            await userRef.set({
                level: currentLevel,
                exp: currentExp,
                points: currentPoints + earnedGold + totalLevelUpBonus
            }, { merge: true });

            res.status(201).json({
                message: "บันทึกข้อมูลและอัปเดตเลเวลสำเร็จ!",
                reward: {
                    goldFromRunning: earnedGold,
                    goldFromLevelUp: totalLevelUpBonus,
                    exp: earnedExp,
                    newLevel: currentLevel
                }
            });
        } else {
            res.status(201).json({ message: "บันทึกใน Supabase สำเร็จ แต่ไม่พบ User นี้ใน Firebase" });
        }

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// ... (ส่วนของ getUserStats เอาไว้เหมือนเดิมเป๊ะๆ ครับ) ...
exports.getUserStats = async (req, res) => {
    try {
        const { user_id } = req.params;
        const { time_frame } = req.query;

        let startDate = new Date();
        if (time_frame === 'daily') {
            startDate.setHours(0, 0, 0, 0);
        } else if (time_frame === 'weekly') {
            const day = startDate.getDay();
            const diff = startDate.getDate() - day + (day === 0 ? -6 : 1);
            startDate = new Date(startDate.setDate(diff));
            startDate.setHours(0, 0, 0, 0);
        } else if (time_frame === 'monthly') {
            startDate.setDate(1);
            startDate.setHours(0, 0, 0, 0);
        } else {
            startDate = new Date(0); 
        }

        const { data, error } = await supabase
            .from('runs')
            .select('distance, duration_seconds, calories, pace, created_at')
            .eq('user_id', user_id)
            .gte('created_at', startDate.toISOString());

        if (error) throw error;

        let totalDistance = 0, totalTime = 0, totalCalories = 0;
        let bestPace = null; 

        let chartData = [];
        if (time_frame === 'weekly') {
            chartData = [0, 0, 0, 0, 0, 0, 0]; 
        } else if (time_frame === 'monthly') {
            chartData = new Array(31).fill(0); 
        } else if (time_frame === 'daily') {
            chartData = new Array(24).fill(0); 
        }

        data.forEach(run => {
            totalDistance += (run.distance || 0);
            totalTime += (run.duration_seconds || 0);
            totalCalories += (run.calories || 0);

            if (run.pace && run.pace > 0) {
                if (bestPace === null || run.pace < bestPace) {
                    bestPace = run.pace;
                }
            }

            if (run.created_at) {
                const runDate = new Date(run.created_at);

                if (time_frame === 'weekly') {
                    const dayIndex = runDate.getDay(); 
                    const chartIndex = dayIndex === 0 ? 6 : dayIndex - 1; 
                    chartData[chartIndex] += (run.distance || 0);
                }
                else if (time_frame === 'monthly') {
                    const dateIndex = runDate.getDate() - 1; 
                    chartData[dateIndex] += (run.distance || 0);
                }
                else if (time_frame === 'daily') {
                    const hourIndex = runDate.getHours(); 
                    chartData[hourIndex] += (run.distance || 0);
                }
            }
        });

        res.status(200).json({
            time_frame,
            total_distance: parseFloat(totalDistance.toFixed(2)),
            total_time_seconds: totalTime,
            total_calories: totalCalories,
            best_pace: bestPace,
            chart_data: chartData 
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// ==========================================
// 💡 ฟังก์ชันใหม่สำหรับระบบ Daily Quest
// ==========================================

// 1. ดึงสถานะเควสของวันนี้ (ตัดยอดเที่ยงคืน)
exports.getQuestStatus = async (req, res) => {
    try {
        const { user_id } = req.params;
        const { partycode } = req.query;

        // หาวันที่ของวันนี้ในเวลาไทย (UTC+7)
        // ✅ โค้ดใหม่ (ถูกต้อง)
        const now = new Date();
        // offset +7 ชั่วโมง แล้วตัดเวลาทิ้ง → ได้ต้นวันในเวลาไทย (เป็น UTC ms)
        const TH_OFFSET_MS = 7 * 60 * 60 * 1000;
        const nowInTH = new Date(now.getTime() + TH_OFFSET_MS);
        const startOfDayTH = new Date(Date.UTC(
            nowInTH.getUTCFullYear(),
            nowInTH.getUTCMonth(),
            nowInTH.getUTCDate(),
            0, 0, 0, 0
        ));
        // แปลงกลับเป็น UTC จริงๆ สำหรับ query Supabase
        const todayUTC = new Date(startOfDayTH.getTime() - TH_OFFSET_MS);
        const dateString = `${nowInTH.getUTCFullYear()}-${String(nowInTH.getUTCMonth()+1).padStart(2,'0')}-${String(nowInTH.getUTCDate()).padStart(2,'0')}`;

        console.log(`[Quest] user_id=${user_id} partycode=${partycode}`);
        console.log(`[Quest] todayUTC=${todayUTC.toISOString()} dateString=${dateString}`);

        // 1. คำนวณระยะทางวิ่งส่วนตัว (ของวันนี้ เวลาไทย)
        const { data: personalData, error: personalError } = await supabase
            .from('runs')
            .select('distance')
            .eq('user_id', user_id)
            .gte('created_at', todayUTC.toISOString());

        console.log(`[Quest] personalData=${JSON.stringify(personalData)} error=${personalError?.message}`);

        let personalDistance = 0;
        if (personalData) {
            personalDistance = personalData.reduce((sum, run) => sum + (run.distance || 0), 0);
        }

        // 2. คำนวณระยะทางวิ่งปาร์ตี้ (ของวันนี้ เวลาไทย)
        let partyDistance = 0;
        if (partycode && partycode !== 'null' && partycode.trim() !== '') {
            const { data: partyData } = await supabase
                .from('runs')
                .select('distance')
                .eq('partycode', partycode)
                .gte('created_at', todayUTC.toISOString());
            
            if (partyData) {
                partyDistance = partyData.reduce((sum, run) => sum + (run.distance || 0), 0);
            }
        }

        // 3. เช็คสถานะการรับรางวัลใน Firestore
        const db = admin.firestore();
        const userDoc = await db.collection('users').doc(user_id).get();
        
        let isPersonalClaimed = false;
        let isPartyClaimed = false;

        if (userDoc.exists) {
            const userData = userDoc.data();
            // ถ้าวันที่รับรางวัลล่าสุด ตรงกับวันที่ของวันนี้ แปลว่ารับไปแล้ว
            isPersonalClaimed = userData.lastPersonalQuestClaim === dateString;
            isPartyClaimed = userData.lastPartyQuestClaim === dateString;
        }

        res.status(200).json({
            personalDistance: parseFloat(personalDistance.toFixed(2)),
            partyDistance: parseFloat(partyDistance.toFixed(2)),
            isPersonalClaimed,
            isPartyClaimed
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// 2. กดรับรางวัลเควส (20G / 100EXP)
exports.claimQuest = async (req, res) => {
    try {
        const { user_id, quest_type } = req.body; 
        
        // ✅ โค้ดใหม่
        const now = new Date();
        const TH_OFFSET_MS = 7 * 60 * 60 * 1000;
        const nowInTH = new Date(now.getTime() + TH_OFFSET_MS);
        const dateString = `${nowInTH.getUTCFullYear()}-${String(nowInTH.getUTCMonth()+1).padStart(2,'0')}-${String(nowInTH.getUTCDate()).padStart(2,'0')}`;

        const db = admin.firestore();
        const userRef = db.collection('users').doc(user_id);
        const userDoc = await userRef.get();

        if (!userDoc.exists) return res.status(404).json({ message: "ไม่พบข้อมูลผู้ใช้" });

        let userData = userDoc.data();
        
        // ป้องกันการกดย้ำ (เช็คซ้ำอีกรอบก่อนแจกของ)
        if (quest_type === 'personal' && userData.lastPersonalQuestClaim === dateString) {
            return res.status(400).json({ message: "คุณรับรางวัลนี้ไปแล้ว" });
        }
        if (quest_type === 'party' && userData.lastPartyQuestClaim === dateString) {
            return res.status(400).json({ message: "คุณรับรางวัลนี้ไปแล้ว" });
        }

        let currentLevel = userData.level || 1;
        let currentExp = userData.exp ?? 0;  // ใช้ ?? รองรับ user เก่าที่ไม่มี exp field
        let currentPoints = userData.points || 0;

        // 💡 แจกรางวัลเควส: 20 G และ 100 EXP
        currentExp += 100; 
        currentPoints += 20; 

        // ตรวจสอบการอัปเลเวล (ใช้สูตรเดิม)
        let totalLevelUpBonus = 0;
        let expNeeded = currentLevel * 50; 
        while (currentExp >= expNeeded) {
            currentExp -= expNeeded;
            currentLevel++;
            totalLevelUpBonus += (100 + (currentLevel - 2) * 20);
            expNeeded = currentLevel * 50;
        }

        currentPoints += totalLevelUpBonus;

        // เตรียมข้อมูลอัปเดต
        const updates = { 
            level: currentLevel, 
            exp: currentExp, 
            points: currentPoints 
        };
        
        // ประทับตราวานที่รับรางวัล
        if (quest_type === 'personal') updates.lastPersonalQuestClaim = dateString;
        else if (quest_type === 'party') updates.lastPartyQuestClaim = dateString;

        await userRef.set(updates, { merge: true });

        res.status(200).json({ 
            message: "รับรางวัลสำเร็จ!", 
            rewardG: 20 + totalLevelUpBonus, 
            rewardExp: 100,
            newLevel: currentLevel
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};