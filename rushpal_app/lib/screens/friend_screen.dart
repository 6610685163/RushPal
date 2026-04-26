import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  // 1. เพิ่ม Controller และ State Variables สำหรับจัดการข้อมูล
  final TextEditingController _searchLocalController = TextEditingController();
  List<dynamic> _myFriends = [];
  List<dynamic> _filteredFriends = [];
  bool _isLoadingFriends = true;
  List<dynamic> _pendingRequests = [];

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

      if (mounted) {
        setState(() {
          _myFriends = friendsList;
          _filteredFriends = friendsList;
          _pendingRequests = requestsList;
          _isLoadingFriends = false;
        });
      }
    }
  }

  // ฟังก์ชันค้นหาเพื่อนในลิสต์ตัวเอง
  void _filterFriends(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredFriends = List.from(_myFriends);
      });
    } else {
      setState(() {
        _filteredFriends = _myFriends.where((friend) {
          final username = (friend['username'] ?? '').toString().toLowerCase();
          return username.contains(query.trim().toLowerCase());
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _searchLocalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              // เมื่อกดปุ่มนี้ ให้โชว์หน้าต่าง Friend Requests ขึ้นมา
              _showFriendRequestsSheet(context);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.pureBlack, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.mail_rounded,
                    color: AppTheme.pureBlack,
                    size: 24,
                  ),
                  if (_pendingRequests.isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 2,
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
            ),
          ),
        ),
        title: const Text(
          "FRIENDS",
          style: TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 8.0, bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                _showAddFriendSheet(context);
              },
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.pureBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppTheme.pureBlack,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.pureBlack, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchLocalController,
                onChanged: _filterFriends,
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: AppTheme.pureBlack),
                  hintText: "Search your friends...",
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchLocalController.clear();
                      _filterFriends('');
                    },
                  ),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Friends",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.pureBlack,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoadingFriends
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  )
                : _filteredFriends.isEmpty
                ? const Center(
                    child: Text(
                      "No friends found.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filteredFriends.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      return _buildFriendItem(friend);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันแสดงหน้าต่างเพิ่มเพื่อน ---
  void _showAddFriendSheet(BuildContext context) {
    final TextEditingController searchGlobalController =
        TextEditingController();
    bool isLoadingGlobal = false;
    Map<String, dynamic>? searchedUserGlobal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // 2. ฟังก์ชันเรียก API ค้นหาเพื่อน
            void searchGlobalUser(String username) async {
              if (username.trim().isEmpty) return;

              setSheetState(() {
                isLoadingGlobal = true;
                searchedUserGlobal = null;
              });

              // เรียก API ไปหา Node.js
              final result = await FriendService.searchFriend(username.trim());

              setSheetState(() {
                if (result != null && result['user'] != null) {
                  searchedUserGlobal = result['user'];
                } else {
                  searchedUserGlobal = result;
                }
                isLoadingGlobal = false;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ADD FRIEND",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.pureBlack,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.pureBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.pureBlack,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchGlobalController,
                        onSubmitted: searchGlobalUser,
                        decoration: InputDecoration(
                          icon: const Icon(
                            Icons.person_search,
                            color: AppTheme.pureBlack,
                          ),
                          hintText: "Enter username to add...",
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              searchGlobalController.clear();
                              setSheetState(() => searchedUserGlobal = null);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isLoadingGlobal)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),

                    if (!isLoadingGlobal && searchedUserGlobal != null)
                      _buildSearchResultCard(
                        searchedUserGlobal!,
                        setSheetState,
                        searchGlobalController,
                      ),

                    if (!isLoadingGlobal &&
                        searchGlobalController.text.isNotEmpty &&
                        searchedUserGlobal == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "User not found",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI การ์ดแสดงผลลัพธ์ตอนค้นหาเจอ ---
  Widget _buildSearchResultCard(
    Map<String, dynamic> searchedUser,
    StateSetter setSheetState,
    TextEditingController controller,
  ) {
    bool isAlreadyFriend = _myFriends.any(
      (friend) => friend['uid'] == searchedUser['uid'],
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.pureBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(imageUrl: searchedUser['profileImageUrl'], radius: 25),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  searchedUser['username'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppTheme.pureBlack,
                  ),
                ),
                Text(
                  "Level ${searchedUser['level'] ?? 1}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(
                        color: AppTheme.pureBlack,
                        width: 2,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    // 1. ดึงข้อมูลคนที่กำลังล็อกอินอยู่
                    final currentUser = FirebaseAuth.instance.currentUser;

                    // 2. เช็คความปลอดภัย: ถ้าไม่มีใครล็อกอินอยู่ (เซสชันหลุด) ให้หยุดการทำงาน
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

                    // 3. ใช้ UID
                    String myUid = currentUser.uid;
                    String friendUid = searchedUser['uid'];

                    // 4. เช็คความปลอดภัย: ป้องกันผู้ใช้แอดตัวเองเป็นเพื่อน
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

                    // เรียกใช้ API แอดเพื่อน
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
                        setSheetState(() {
                          controller.clear();
                        });
                        Navigator.pop(context);
                        _loadFriends();
                      }
                    }
                  },
                  child: const Text(
                    "Add",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
      backgroundColor: AppTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Friend Requests",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureBlack,
                ),
              ),
              const SizedBox(height: 15),

              _pendingRequests.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text(
                          "No pending requests.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.separated(
                        itemCount: _pendingRequests.length,
                        separatorBuilder: (c, i) =>
                            const Divider(color: Colors.black12),
                        itemBuilder: (context, index) {
                          final reqUser = _pendingRequests[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: UserAvatar(
                              imageUrl: reqUser['profileImageUrl'],
                              radius: 22,
                            ),
                            title: Text(
                              reqUser['username'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.pureBlack,
                              ),
                            ),
                            subtitle: Text(
                              "Level ${reqUser['level'] ?? 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppTheme.pureBlack,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                // 1. ดึง UID ของตัวเรา
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  // 2. ปิดหน้าต่าง Sheet ลงไปก่อน
                                  Navigator.pop(sheetContext);

                                  setState(() => _isLoadingFriends = true);

                                  // 3. เรียก API ยอมรับเพื่อน
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
                                    // 4. โหลดรายชื่อเพื่อนใหม่
                                    _loadFriends();
                                  }
                                }
                              },
                              child: const Text(
                                "Accept",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    // 1. ดึง UID ของเพื่อนออกมาก่อน
    String? friendUid = friend['uid'];

    if (friendUid == null) return const SizedBox.shrink();

    // 2. ใช้ StreamBuilder วิ่งไปดูข้อมูลล่าสุดของเพื่อนคนนี้ใน Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayUsername = friend['username'] ?? "Unknown";
        String displayLevel = (friend['level'] ?? 1).toString();
        String? profileImageUrl = friend['profileImageUrl'];

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayUsername = userData['username'] ?? displayUsername;
          displayLevel = (userData['level'] ?? 1).toString();
          profileImageUrl = userData['profileImageUrl'];
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.pureBlack, width: 3),
            boxShadow: const [
              BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              UserAvatar(imageUrl: profileImageUrl, radius: 25),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.pureBlack,
                      ),
                    ),
                    Text(
                      "Level $displayLevel",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1.5,
                  ),
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
      },
    );
  }
}
