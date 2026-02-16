import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import '../theme/app_theme.dart';
import 'market_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final O3DController _controller = O3DController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. พื้นหลังสีแดงด้านบน
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),

          // 2. เนื้อหาหลัก
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 10),

                // --- MAIN CHARACTER CARD (การ์ดตัวละคร) ---
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Stack(
                        children: [
                          // ✅ A. Background Image (แก้ให้เต็มพื้นที่การ์ด)
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/home_bg.png',
                              fit: BoxFit.cover, // ให้รูปเต็มกรอบ
                              errorBuilder: (c, e, s) =>
                                  Container(color: Colors.grey[200]),
                            ),
                          ),

                          // B. Character Model (Guy)
                          Positioned(
                            bottom: 20, // ปรับระดับเท้า
                            left: 0,
                            right: 0,
                            top: 0,
                            child: O3D(
                              src: 'assets/models/guy.glb',
                              controller: _controller,
                              autoPlay: true,
                              autoRotate: false,
                              cameraControls: false,
                              animationName: 'mixamo.com',
                              backgroundColor: Colors.transparent,
                            ),
                          ),

                          // C. UI Overlays (Badge & Share)
                          Positioned(
                            top: 20,
                            left: 20,
                            child: _buildBadge(
                              "Streak 5",
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // --- ส่วนควบคุมด้านล่าง (START + BAR) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ 1. ปุ่ม START (ตรงกลาง) + ปุ่ม Party (เล็ก)
                      _buildStartButtonArea(),
                      SizedBox(height: 20),
                      // ✅ 2. Custom Navigation Bar (แคปซูลอันเดียว)
                      _buildCustomBottomBar(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButtonArea() {
    return Container(
      height: 70,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ปุ่ม START อยู่ตรงกลางจริงๆ
          Container(
            width: 180, // ปรับความกว้างให้พอดีตามรูป
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "START",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // ปุ่ม Party เล็กๆ อยู่ด้านขวา
          Positioned(
            right: 10,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Color(0xFFE0F7FA),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Icon(Icons.groups_outlined, color: Colors.cyan, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_rounded, isActive: true),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => MarketScreen()),
            ),
            child: _buildNavItem(Icons.storefront_rounded),
          ),
          _buildNavItem(Icons.bar_chart_rounded),
          _buildNavItem(Icons.group_rounded),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryRed,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Player Name",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Lv. 99",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: 0.7,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 14,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "1000",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.hexagon_outlined, size: 32, color: Colors.black87),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 5),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, {bool isActive = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: isActive
          ? BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            )
          : null,
      child: Icon(
        icon,
        size: 28,
        color: isActive ? AppTheme.primaryRed : Colors.grey[700],
      ),
    );
  }
}
