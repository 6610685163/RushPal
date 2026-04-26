import 'package:flutter/material.dart';
import 'package:rushpal/theme/app_theme.dart';
import 'package:rushpal/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rushpal/widgets/user_avatar.dart';

class FriendScreen extends StatefulWidget {
  final void Function(int count)? onRequestsChanged;

  const FriendScreen({super.key, this.onRequestsChanged});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final TextEditingController _searchLocalController = TextEditingController();
  String _searchQuery = '';
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // สร้าง Stream ครั้งเดียว เพื่อ listen การเปลี่ยนแปลง doc ของ user ปัจจุบัน
      _userDocStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _searchLocalController.dispose();
    super.dispose();
  }

  // แปลง friends field จาก Firestore เป็น list ของ uid
  List<String> _extractFriendUids(dynamic friendsField) {
    if (friendsField == null) return [];
    if (friendsField is List) {
      return friendsField
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['uid'] ?? '').toString();
            return '';
          })
          .where((uid) => uid.isNotEmpty)
          .toList();
    }
    return [];
  }

  // แปลง friendRequests field จาก Firestore เป็น list ของ uid
  List<String> _extractPendingUids(dynamic pendingField) {
    if (pendingField == null) return [];
    if (pendingField is List) {
      return pendingField
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['uid'] ?? '').toString();
            return '';
          })
          .where((uid) => uid.isNotEmpty)
          .toList();
    }
    return [];
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userDocStream,
            builder: (context, snapshot) {
              List<String> pendingUids = [];
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                pendingUids = _extractPendingUids(data['friendRequests']);

                // แจ้ง MainScreen ให้อัปเดต navbar badge แบบ real-time
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onRequestsChanged?.call(pendingUids.length);
                });
              }

              return GestureDetector(
                onTap: () => _showFriendRequestsSheet(context, pendingUids),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.pureBlack,
                        offset: Offset(0, 3),
                      ),
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
                      if (pendingUids.isNotEmpty)
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
                              '${pendingUids.length}',
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
              );
            },
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
              onTap: () => _showAddFriendSheet(context),
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
          // Search bar
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
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: AppTheme.pureBlack),
                  hintText: "Search your friends...",
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchLocalController.clear();
                      setState(() => _searchQuery = '');
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

          // ---- My Friends List — Real-time via StreamBuilder ----
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userDocStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),
                  );
                }

                List<String> friendUids = [];
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  friendUids = _extractFriendUids(data['friends']);
                }

                if (friendUids.isEmpty) {
                  return const Center(
                    child: Text(
                      "No friends found.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: friendUids.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final friendUid = friendUids[index];

                    // แต่ละ card ฟัง real-time จาก doc ของเพื่อน
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendUid)
                          .snapshots(),
                      builder: (context, friendSnap) {
                        String displayUsername = '...';
                        String displayLevel = '1';
                        String? profileImageUrl;

                        if (friendSnap.hasData && friendSnap.data!.exists) {
                          final d =
                              friendSnap.data!.data() as Map<String, dynamic>;
                          displayUsername = d['username'] ?? 'Unknown';
                          displayLevel = (d['level'] ?? 1).toString();
                          profileImageUrl = d['profileImageUrl'];
                        }

                        // ซ่อน item ถ้าไม่ตรง search query
                        if (_searchQuery.isNotEmpty &&
                            !displayUsername.toLowerCase().contains(
                              _searchQuery,
                            )) {
                          return const SizedBox.shrink();
                        }

                        return _buildFriendItem(
                          friendUid: friendUid,
                          displayUsername: displayUsername,
                          displayLevel: displayLevel,
                          profileImageUrl: profileImageUrl,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- หน้าต่างเพิ่มเพื่อน ---
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
          builder: (BuildContext ctx, StateSetter setSheetState) {
            void searchGlobalUser(String username) async {
              if (username.trim().isEmpty) return;
              setSheetState(() {
                isLoadingGlobal = true;
                searchedUserGlobal = null;
              });
              final result = await FriendService.searchFriend(username.trim());
              setSheetState(() {
                searchedUserGlobal = (result != null && result['user'] != null)
                    ? result['user']
                    : result;
                isLoadingGlobal = false;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(ctx).size.height * 0.6,
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
                        sheetContext,
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

  Widget _buildSearchResultCard(
    Map<String, dynamic> searchedUser,
    StateSetter setSheetState,
    TextEditingController controller,
    BuildContext sheetContext,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        List<String> friendUids = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          friendUids = _extractFriendUids(data['friends']);
        }
        bool isAlreadyFriend = friendUids.contains(searchedUser['uid']);

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
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;

                        if (currentUser.uid == searchedUser['uid']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'คุณไม่สามารถเพิ่มตัวเองเป็นเพื่อนได้',
                              ),
                            ),
                          );
                          return;
                        }

                        bool success = await FriendService.sendRequest(
                          currentUser.uid,
                          searchedUser['uid'],
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ส่งคำขอเป็นเพื่อนแล้ว!'),
                            ),
                          );
                          setSheetState(() => controller.clear());
                          Navigator.pop(sheetContext);
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
      },
    );
  }

  // --- Friend Requests Bottom Sheet — Real-time via StreamBuilder ---
  void _showFriendRequestsSheet(
    BuildContext context,
    List<String> initialPendingUids,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext sheetContext) {
        // StreamBuilder ภายใน sheet เพื่อรับข้อมูล real-time
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            List<String> pendingUids = [];
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              pendingUids = _extractPendingUids(data['friendRequests']);
            }

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(sheetContext).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Friend Requests",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.pureBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (pendingUids.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${pendingUids.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  pendingUids.isEmpty
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
                            itemCount: pendingUids.length,
                            separatorBuilder: (c, i) =>
                                const Divider(color: Colors.black12),
                            itemBuilder: (context, index) {
                              final requesterUid = pendingUids[index];

                              // ดึงข้อมูล profile ของคนที่ส่ง request แบบ real-time
                              return StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(requesterUid)
                                    .snapshots(),
                                builder: (context, reqSnap) {
                                  String reqUsername = '...';
                                  String reqLevel = '1';
                                  String? reqProfileUrl;

                                  if (reqSnap.hasData && reqSnap.data!.exists) {
                                    final d =
                                        reqSnap.data!.data()
                                            as Map<String, dynamic>;
                                    reqUsername = d['username'] ?? 'Unknown';
                                    reqLevel = (d['level'] ?? 1).toString();
                                    reqProfileUrl = d['profileImageUrl'];
                                  }

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: UserAvatar(
                                      imageUrl: reqProfileUrl,
                                      radius: 22,
                                    ),
                                    title: Text(
                                      reqUsername,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.pureBlack,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Level $reqLevel",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ปุ่ม Decline
                                        GestureDetector(
                                          onTap: () async {
                                            await FriendService.declineRequest(
                                              user.uid,
                                              requesterUid,
                                            );
                                            // Stream อัปเดตเองอัตโนมัติ ไม่ต้อง setState
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppTheme.pureBlack,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: AppTheme.pureBlack,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        // ปุ่ม Accept
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: const BorderSide(
                                                color: AppTheme.pureBlack,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          onPressed: () async {
                                            bool success =
                                                await FriendService.acceptRequest(
                                                  user.uid,
                                                  requesterUid,
                                                );
                                            if (success && mounted) {
                                              if (sheetContext.mounted)
                                                Navigator.pop(sheetContext);
                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'เพิ่มเป็นเพื่อนสำเร็จ!',
                                                  ),
                                                ),
                                              );
                                              // Stream จะ refresh ทั้ง friends list และ pending list เอง
                                            } else if (!success && mounted) {
                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'เกิดข้อผิดพลาด กรุณาลองใหม่',
                                                  ),
                                                ),
                                              );
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
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendItem({
    required String friendUid,
    required String displayUsername,
    required String displayLevel,
    String? profileImageUrl,
  }) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    _confirmRemoveFriend(context, friendUid, displayUsername),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.pureBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.pureBlack,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_remove_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    String friendUid,
    String username,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.pureBlack, width: 3),
        ),
        title: const Text(
          'Remove Friend',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.pureBlack,
          ),
        ),
        content: Text(
          'Remove "$username" from your friends?',
          style: const TextStyle(
            color: AppTheme.pureBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                bool success = await FriendService.removeFriend(
                  user.uid,
                  friendUid,
                );
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
                    ),
                  );
                }
                // ไม่ต้อง setState เพราะ Stream อัปเดต friends list เองอัตโนมัติ
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.pureBlack, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppTheme.pureBlack, offset: Offset(0, 2)),
                ],
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
