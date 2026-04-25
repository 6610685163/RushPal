const supabase = require('../config/supabase');
const admin = require('firebase-admin'); // เรียกใช้ firebase-admin

exports.saveRunResult = async (req, res) => {
    try {
        const { user_id, distance, pace, duration_seconds, calories } = req.body;

        // 1. บันทึกประวัติการวิ่งลง Supabase (เหมือนเดิม)
        const { data, error } = await supabase
            .from('runs')
            .insert([{ user_id, distance, pace, duration_seconds, calories }]);

        if (error) throw error;

        // 2. ระบบคำนวณเงินและ EXP (รับ distance มาเป็น กิโลเมตร)
        const earnedGold = Math.floor(distance * 100); // 1 km = 10 G
        const earnedExp = Math.floor(distance * 1000); // 1 km = 1000 EXP

        // 3. ไปดึงข้อมูลผู้เล่นคนนี้จาก Firebase มาเช็ค
        const db = admin.firestore();
        const userRef = db.collection('users').doc(user_id);
        const userDoc = await userRef.get();

        if (userDoc.exists) {
            let userData = userDoc.data();
            let currentLevel = userData.level || 1;
            let currentExp = userData.exp || 0;
            let currentPoints = userData.points || 0;

            // เอา EXP จากการวิ่งรอบนี้ไปบวกเพิ่ม
            currentExp += earnedExp;

            let totalLevelUpBonus = 0; // 💡 ตัวแปรเก็บเงินโบนัสรวมกรณีอัปหลายเวลพร้อมกัน
            
            // สูตรเทส: เวล 1-2 ใช้ 50 เมตร (50 EXP), เวล 2-3 ใช้ 100 เมตร (100 EXP)
            let expNeeded = currentLevel * 50; 
            
            while (currentExp >= expNeeded) {
                currentExp -= expNeeded; // หัก EXP ที่ใช้เลื่อนขั้นออก
                currentLevel++; // เลเวลอัป!

                // 💡 คำนวณเงินรางวัลเวลอัปตามสูตรที่คุณให้มา
                // เวล 2 ได้ 100, เวล 3 ได้ 120, เวล 4 ได้ 140
                // สูตรคือ: 100 + ((เลเวลใหม่ - 2) * 20)
                let levelReward = 100 + (currentLevel - 2) * 20;
                totalLevelUpBonus += levelReward;

                expNeeded = currentLevel * 50; // ตั้งเป้าหมายสำหรับเลเวลถัดไป
            }

            // 5. อัปเดตข้อมูลใหม่กลับลง Firebase
            // 💡 นำ (เงินจากการวิ่ง + เงินโบนัสเวลอัป) ไปบวกเพิ่มใน points เดิม
            await userRef.update({
                level: currentLevel,
                exp: currentExp,
                points: currentPoints + earnedGold + totalLevelUpBonus
            });

            res.status(201).json({ 
                message: "บันทึกข้อมูลและอัปเดตเลเวลสำเร็จ!", 
                reward: { 
                    goldFromRunning: earnedGold, 
                    goldFromLevelUp: totalLevelUpBonus, // แจ้งยอดโบนัสกลับไปด้วย
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

// ... (ส่วนของ getUserStats เอาไว้เหมือนเดิมไม่ต้องลบนะครับ) ...
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
            startDate = new Date(0); // ถ้าส่ง 'all' มา จะดึงข้อมูลตั้งแต่เริ่มต้น
        }

        // 💡 อัปเดตเพิ่ม 'pace' เข้าไปในคำสั่ง select ด้วย
        const { data, error } = await supabase
            .from('runs')
            .select('distance, duration_seconds, calories, pace') 
            .eq('user_id', user_id)
            .gte('created_at', startDate.toISOString());

        if (error) throw error;

        let totalDistance = 0, totalTime = 0, totalCalories = 0;
        let bestPace = null; // 💡 ตัวแปรสำหรับเก็บเพซที่ดีที่สุด (น้อยที่สุด)

        data.forEach(run => {
            totalDistance += (run.distance || 0);
            totalTime += (run.duration_seconds || 0);
            totalCalories += (run.calories || 0);

            // 💡 ตรวจหา Best Pace (ตัวเลขยิ่งน้อยยิ่งแปลว่าวิ่งเร็ว)
            if (run.pace && run.pace > 0) {
                if (bestPace === null || run.pace < bestPace) {
                    bestPace = run.pace;
                }
            }
        });

        res.status(200).json({
            time_frame,
            total_distance: parseFloat(totalDistance.toFixed(2)),
            total_time_seconds: totalTime,
            total_calories: totalCalories,
            best_pace: bestPace // 💡 ส่งค่าเพซที่ดีที่สุดกลับไปให้ Flutter
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};