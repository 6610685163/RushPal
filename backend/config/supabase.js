// ไฟล์: backend/config/supabase.js
require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

// สร้างตัวเชื่อมต่อ Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

module.exports = supabase;