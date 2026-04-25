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
            startDate = new Date(0);
        }

        const { data, error } = await supabase
            .from('runs')
            .select('distance, duration_seconds, calories')
            .eq('user_id', user_id)
            .gte('created_at', startDate.toISOString());

        if (error) throw error;

        let totalDistance = 0, totalTime = 0, totalCalories = 0;

        data.forEach(run => {
            totalDistance += (run.distance || 0);
            totalTime += (run.duration_seconds || 0);
            totalCalories += (run.calories || 0);
        });

        res.status(200).json({
            time_frame,
            total_distance: parseFloat(totalDistance.toFixed(2)),
            total_time_seconds: totalTime,
            total_calories: totalCalories
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};