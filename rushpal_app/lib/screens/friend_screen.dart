import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  // 1. เพิ่ม Controller และ State Variables สำหรับจัดการข้อมูล
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _searchedUser;
  List<dynamic> _myFriends = [];
  bool _isLoadingFriends = true;
  List<dynamic> _pendingRequests = [];

  // 2. ฟังก์ชันเรียก API ค้นหาเพื่อน
  void _searchUser(String username) async {
    if (username.trim().isEmpty) return; // ถ้าพิมพ์ว่างๆ ไม่ต้องหา

    print("🟢 1. แอปกำลังส่งชื่อนี้ไปหา Node.js: ${username.trim()}");

    setState(() {
      _isLoading = true;
      _searchedUser = null;
    });

    // เรียก API ไปหา Node.js
    final result = await FriendService.searchFriend(username.trim());

    print("🟢 2. ได้ของขวัญจาก Node.js แล้วคือ: $result");

    setState(() {
      if (result != null && result['user'] != null) {
        _searchedUser = result['user'];
      } else {
        _searchedUser = result; // ถ้าไม่มีกล่อง ก็ใช้ตามปกติ
      }
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFriends(); // โหลดข้อมูลทันทีที่เปิดหน้านี้
  }

  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final friendsList = await FriendService.getFriendsList(user.uid);
      final requestsList = await FriendService.getPendingRequests(user.uid);

      setState(() {
        _myFriends = friendsList;
        _pendingRequests = requestsList;
        _isLoadingFriends = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Friends",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppTheme.primaryPink),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.darkBlue.withOpacity(0.6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white12),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.white54),
                  hintText: "Search friend",
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchedUser = null);
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 10,
              separatorBuilder: (c, i) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                return _buildFriendItem(index);
              },
            ),
          ),

          isAlreadyFriend
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Friends",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    // 🌟 1. ดึงข้อมูลคนที่กำลังล็อกอินอยู่ ณ ตอนนี้!
                    final currentUser = FirebaseAuth.instance.currentUser;

                    // 🛡️ 2. เช็คความปลอดภัย: ถ้าไม่มีใครล็อกอินอยู่ (เซสชันหลุด) ให้หยุดการทำงาน
                    if (currentUser == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'เกิดข้อผิดพลาด กรุณาล็อกอินใหม่อีกครั้ง',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // 🌟 3. ได้เวลาใช้ UID ของจริง!
                    String myUid = currentUser.uid;
                    String friendUid = _searchedUser!['uid'];

                    // 🛡️ 4. เช็คความปลอดภัย: ป้องกันผู้ใช้แอดตัวเองเป็นเพื่อน
                    if (myUid == friendUid) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'คุณไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    print(
                      "🚀 ส่งคำขอแอดเพื่อนจากตัวเรา ($myUid) ไปหา ($friendUid)",
                    );

                    // เรียกใช้ API แอดเพื่อน (เหมือนที่คุณเขียนไว้เลย)
                    bool success = await FriendService.sendRequest(
                      myUid,
                      friendUid,
                    );

                    if (success) {
                      // ถ้าแอดสำเร็จ ให้ล้างหน้าจอและแจ้งเตือน
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ส่งคำขอเป็นเพื่อนแล้ว!'),
                          ),
                        );
                        setState(() {
                          _searchedUser = null;
                          _searchController.clear();
                        });
                        _loadFriends();
                      }
                    }
                  },
                  child: const Text(
                    "Add",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(int index) {
    bool isOnline = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? Colors.greenAccent : Colors.white24,
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.pureBlack,
              child: Icon(Icons.person, color: AppTheme.primaryPink),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend['username'] ?? "Unknown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Level ${99 - index}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.greenAccent.withOpacity(0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOnline ? "Online" : "Offline",
              style: TextStyle(
                color: isOnline ? Colors.greenAccent : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
