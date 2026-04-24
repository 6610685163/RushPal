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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Friends",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.person_add,
                  color: AppTheme.primaryRed,
                  size: 28,
                ),
                onPressed: () {
                  // เมื่อกดปุ่มนี้ ให้โชว์หน้าต่าง Friend Requests ขึ้นมา
                  _showFriendRequestsSheet(context);
                },
              ),
              // 🌟 ถ้ามีคนขอแอดมา ให้โชว์จุดแดงพร้อมตัวเลข
              if (_pendingRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                // สั่งให้ค้นหาเมื่อกดปุ่ม Enter/Done บนคีย์บอร์ด
                onSubmitted: _searchUser,
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Search username...",
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

          // แสดงสถานะ Loading ระหว่างรอ API
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            ),

          // แสดงผลลัพธ์การค้นหา (ถ้าเจอ)
          if (!_isLoading && _searchedUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: _buildSearchResultCard(),
            ),

          // แสดงข้อความหาไม่เจอ
          if (!_isLoading &&
              _searchController.text.isNotEmpty &&
              _searchedUser == null)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "User not found",
                style: TextStyle(color: Colors.red),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Friends",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          // Friend List (อันเดิมของคุณ)
          Expanded(
            child: _isLoadingFriends
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                : _myFriends.isEmpty
                ? const Center(child: Text("You don't have any friends yet."))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _myFriends.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final friend = _myFriends[index];
                      return _buildFriendItem(friend);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- UI หน้าต่างโชว์คำขอเป็นเพื่อน (Bottom Sheet) ---
  void _showFriendRequestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5, // สูงครึ่งจอ
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Friend Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // เช็คว่ามีคนแอดมาไหม
              _pendingRequests.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          "No pending requests.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.separated(
                        itemCount: _pendingRequests.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          final reqUser = _pendingRequests[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.black12,
                              child: Icon(Icons.person, color: Colors.grey),
                            ),
                            title: Text(
                              reqUser['username'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text("Level ${reqUser['level'] ?? 1}"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async {
                                // 🌟 1. ดึง UID ของตัวเรา
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  // 🌟 2. ปิดหน้าต่าง Sheet ลงไปก่อน
                                  Navigator.pop(sheetContext);

                                  setState(() => _isLoadingFriends = true);

                                  // 🌟 3. เรียก API ยอมรับเพื่อน
                                  bool success =
                                      await FriendService.acceptRequest(
                                        user.uid,
                                        reqUser['uid'],
                                      );

                                  if (success) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'เพิ่มเป็นเพื่อนสำเร็จ!',
                                          ),
                                        ),
                                      );
                                    }
                                    // 🌟 4. โหลดรายชื่อเพื่อนใหม่ (ชื่อจะไปโผล่ใน My Friends ทันที)
                                    _loadFriends();
                                  }
                                }
                              },
                              child: const Text(
                                "Accept",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // --- UI การ์ดแสดงผลลัพธ์ตอนค้นหาเจอ ---
  Widget _buildSearchResultCard() {
    bool isAlreadyFriend = _myFriends.any(
      (friend) => friend['uid'] == _searchedUser!['uid'],
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.05), // ไฮไลท์สีแดงอ่อนๆ
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppTheme.primaryRed),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchedUser!['username'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Level ${_searchedUser!['level'] ?? 1}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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

  // --- UI รายชื่อเพื่อนเดิมของคุณ ---
  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Level ${friend['level'] ?? 1}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Online",
              style: TextStyle(
                color: Colors.green[700],
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
