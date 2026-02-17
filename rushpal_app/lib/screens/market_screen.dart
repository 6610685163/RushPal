import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import '../theme/app_theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final O3DController _controller = O3DController();

  // ✅ 1. แก้ไข: ตัวแปรเก็บ path ของโมเดลปัจจุบัน (เริ่มที่ guy.glb)
  String currentModel = 'assets/models/guy.glb';

  // ✅ 2. แก้ไข: ข้อมูลสินค้า ให้ชี้ไปที่ guy.glb ทั้งหมดก่อน (กัน Error)
  final Map<String, List<Map<String, dynamic>>> marketItems = {
    'Head': [
      {
        'name': 'Basic Hair',
        'price': 0,
        'owned': true,
        'model': 'assets/models/guy.glb', // แก้เป็น guy
      },
      {
        'name': 'Cap',
        'price': 500,
        'owned': false,
        // ใช้ guy.glb ไปก่อนจนกว่าจะมีไฟล์ guy_cap.glb
        'model': 'assets/models/guy.glb',
      },
      {
        'name': 'Helmet',
        'price': 1200,
        'owned': false,
        'model': 'assets/models/guy.glb',
      },
    ],
    'Body': [
      {
        'name': 'Adventurer',
        'price': 0,
        'owned': true,
        'model': 'assets/models/guy.glb', // แก้เป็น guy
      },
      {
        'name': 'Tracksuit',
        'price': 2000,
        'owned': false,
        'model': 'assets/models/guy.glb',
      },
    ],
    'Legs': [],
    'Shoes': [],
  };

  final List<String> tabs = ['Head', 'Body', 'Legs', 'Shoes'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  // ฟังก์ชันเปลี่ยนชุด
  void _tryOnItem(String modelPath) {
    setState(() {
      currentModel = modelPath;
    });
    // O3D จะ Rebuild และโหลดโมเดลใหม่ตาม key ที่เปลี่ยนไป
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Avatar Shop",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // เหรียญของผู้เล่น
          Container(
            margin: EdgeInsets.only(right: 20, top: 10, bottom: 10),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.orange, size: 20),
                SizedBox(width: 5),
                Text(
                  "99,999",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. ส่วนแสดงตัวละคร 3D (Preview)
          Expanded(
            flex: 4, // พื้นที่ 40%
            child: Stack(
              alignment: Alignment.center,
              children: [
                // พื้นหลังวงกลมที่เท้า
                Positioned(
                  bottom: 20,
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(200, 40),
                      ),
                    ),
                  ),
                ),
                // ตัวโมเดล 3D
                Container(
                  width: double.infinity,
                  child: O3D(
                    key: ValueKey(
                      currentModel,
                    ), // ใส่ Key เพื่อให้มัน Rebuild ตอนเปลี่ยนชุด
                    src: currentModel,
                    controller: _controller,
                    autoPlay: true,
                    autoRotate: true, // หมุนโชว์ตัวในหน้านี้
                    cameraControls: true, // ให้ user หมุนดูชุดได้
                    animationName: 'Idle', // ยืนนิ่งๆ ลองชุด
                    backgroundColor: Colors.transparent,
                  ),
                ),
                // ปุ่ม Filter
                Positioned(
                  right: 20,
                  top: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.tune, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // 2. แถบหมวดหมู่ (TabBar)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryRed,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),

                // 3. รายการสินค้า (Grid)
                Container(
                  height: 300,
                  color: Colors.grey[50],
                  child: TabBarView(
                    controller: _tabController,
                    children: tabs
                        .map((category) => _buildItemGrid(category))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(String category) {
    final items = marketItems[category] ?? [];

    if (items.isEmpty) {
      return Center(child: Text("No items in $category"));
    }

    return GridView.builder(
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = currentModel == item['model'];

        return GestureDetector(
          onTap: () => _tryOnItem(item['model']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryRed, width: 2)
                  : Border.all(color: Colors.transparent),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Icon(Icons.checkroom, size: 40, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      item['owned']
                          ? Text(
                              "Owned",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                              ),
                            )
                          : Text(
                              "${item['price']} G",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
