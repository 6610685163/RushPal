const supabase = require('../config/supabase');

exports.saveRunResult = async (req, res) => {
    try {
        const { user_id, distance, pace, duration_seconds, calories } = req.body;

        const { data, error } = await supabase
            .from('runs')
            .insert([{ user_id, distance, pace, duration_seconds, calories }]);

        if (error) throw error;
        res.status(201).json({ message: "บันทึกข้อมูลสำเร็จ", data });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

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