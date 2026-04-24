const supabase = require('../config/supabase');

// 1. ฟังก์ชันบันทึกข้อมูลวิ่ง (แก้ไขเพิ่ม calories)
exports.saveRunResult = async (req, res) => {
    try {
        const { user_id, distance, pace, duration_seconds, calories } = req.body;

        const { data, error } = await supabase
            .from('runs')
            .insert([
                {
                    user_id: user_id,
                    distance: distance,
                    pace: pace,
                    duration_seconds: duration_seconds,
                    calories: calories // 👈 เพิ่มบรรทัดนี้
                }
            ]);

        if (error) throw error;
        res.status(201).json({ message: "บันทึกข้อมูลการวิ่งสำเร็จ", data });
    } catch (error) {
        console.error("❌ Error saving to Supabase:", error);
        res.status(500).json({ error: error.message });
    }
};

// 2. ฟังก์ชันใหม่! สำหรับดึงสถิติ (รายวัน, สัปดาห์, เดือน)
exports.getUserStats = async (req, res) => {
    try {
        const { user_id } = req.params;
        const { time_frame } = req.query; // รับค่า 'daily', 'weekly', 'monthly'

        // คำนวณหาวันที่เริ่มต้น (Start Date) ตาม Time Frame
        let startDate = new Date();
        if (time_frame === 'daily') {
            startDate.setHours(0, 0, 0, 0); // เริ่มต้นเที่ยงคืนของวันนี้
        } else if (time_frame === 'weekly') {
            const day = startDate.getDay();
            const diff = startDate.getDate() - day + (day === 0 ? -6 : 1); // เริ่มต้นวันจันทร์ของสัปดาห์นี้
            startDate = new Date(startDate.setDate(diff));
            startDate.setHours(0, 0, 0, 0);
        } else if (time_frame === 'monthly') {
            startDate.setDate(1); // เริ่มต้นวันที่ 1 ของเดือนนี้
            startDate.setHours(0, 0, 0, 0);
        } else {
            startDate = new Date(0); // ถ้าไม่ส่งมา เอาข้อมูลทั้งหมด (All time)
        }

        // ดึงข้อมูลการวิ่งทั้งหมดในช่วงเวลาที่กำหนด
        const { data, error } = await supabase
            .from('runs')
            .select('distance, duration_seconds, calories')
            .eq('user_id', user_id)
            .gte('created_at', startDate.toISOString());

        if (error) throw error;

        // นำข้อมูลมาบวกกัน (Aggregate)
        let totalDistance = 0;
        let totalTime = 0;
        let totalCalories = 0;

        data.forEach(run => {
            totalDistance += (run.distance || 0);
            totalTime += (run.duration_seconds || 0);
            totalCalories += (run.calories || 0);
        });

        res.status(200).json({
            time_frame: time_frame || 'all_time',
            total_distance: parseFloat(totalDistance.toFixed(2)),
            total_time_seconds: totalTime,
            total_calories: totalCalories
        });
    } catch (error) {
        console.error("❌ Error fetching stats:", error);
        res.status(500).json({ error: error.message });
    }
};