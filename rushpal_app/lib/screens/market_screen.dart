import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final O3DController _controller = O3DController();

  // Variables for State management
  bool isLoading = true;
  int userPoints = 0;
  String currentModel = 'assets/models/guy.glb';
  Map<String, dynamic>? selectedItem;

  // Get user UID from Firebase Auth (if logged in)
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  // API URL (use 10.0.2.2 for Android Emulator, or computer's IP for physical device)
  final String apiUrl = "http://10.0.2.2:3000/api/shop";

  // Empty structure waiting for API data
  Map<String, List<Map<String, dynamic>>> marketItems = {
    'Head': [],
    'Body': [],
    'Legs': [],
    'Shoes': [],
  };

  final List<String> tabs = ['Head', 'Body', 'Legs', 'Shoes'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    fetchMarketData(); // Call API to fetch data on screen load
  }

  // Function to fetch shop data and user points from Backend
  Future<void> fetchMarketData() async {
    setState(() => isLoading = true);
    try {
      if (currentUid.isEmpty) {
        print("Not logged in to Firebase Auth");
        // If you want to test without a login system, use a hardcoded ID temporarily, e.g.,
        // final response = await http.get(Uri.parse('$apiUrl/items/4pDXQmjG9tenIILMLizB7Kcj0adt2'));
      }

      final response = await http.get(Uri.parse('$apiUrl/items/$currentUid'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoints = data['points'] ?? 0;
          
          // Clear old data and insert new data from API
          marketItems = { 'Head': [], 'Body': [], 'Legs': [], 'Shoes': [] };
          Map<String, dynamic> fetchedItems = data['marketItems'] ?? {};
          
          fetchedItems.forEach((key, value) {
            marketItems[key] = List<Map<String, dynamic>>.from(value);
          });
          
          isLoading = false;
        });
      } else {
        print("Failed to load data: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error connecting to server: $e");
      setState(() => isLoading = false);
    }
  }

  // Function to buy an item
  Future<void> buyItem(String itemId) async {
    try {
      // Show Loading Dialog while buying
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse('$apiUrl/buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': currentUid,
          'itemId': itemId,
        }),
      );

      // Close Loading Dialog
      if (mounted) Navigator.pop(context);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Purchase successful, show notification and reload data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase successful!'), backgroundColor: Colors.green),
          );
        }
        fetchMarketData(); // Update points and item status
      } else {
        // Purchase failed (e.g., insufficient points)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Purchase failed: ${data['error']}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Error during purchase: $e");
    }
  }

  // Function to change outfit and keep track of selected item
  void _tryOnItem(Map<String, dynamic> item) {
    setState(() {
      currentModel = item['model']?.toString() ?? 'assets/models/guy.glb';
      selectedItem = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Avatar Shop",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.orange, size: 20),
                const SizedBox(width: 5),
                Text(
                  isLoading ? "..." : "$userPoints",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Show loading indicator if loading
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : Column(
        children: [
          // 1. 3D Character Display Section
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 20,
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(200, 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: O3D(
                    key: ValueKey(currentModel),
                    src: currentModel,
                    controller: _controller,
                    autoPlay: true,
                    autoRotate: true,
                    cameraControls: true,
                    animationName: 'Idle',
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.tune, color: Colors.black54),
                  ),
                ),
                
                // === "Buy" button appears if the selected item is not owned ===
                if (selectedItem != null && (selectedItem!['owned'] == false || selectedItem!['owned'] == null))
                  Positioned(
                    bottom: 20,
                    child: ElevatedButton.icon(
                      onPressed: () => buyItem(selectedItem!['id']),
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
                      label: Text(
                        "Buy ${selectedItem!['price'] ?? 0} G",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Category TabBar
          Container(
            decoration: const BoxDecoration(
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),

                // 3. Item List
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
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        // ==========================================
        // Null check to prevent red screen of death
        // ==========================================
        final String itemName = item['name']?.toString() ?? 'Unnamed';
        final String itemImage = item['image']?.toString() ?? '';
        final String itemModel = item['model']?.toString() ?? 'assets/models/guy.glb';
        final int itemPrice = item['price'] ?? 0;
        final bool isOwned = item['owned'] ?? false;

        final isSelected = currentModel == itemModel;

        return GestureDetector(
          onTap: () => _tryOnItem(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryRed, width: 2)
                  : Border.all(color: Colors.transparent),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: itemImage.isNotEmpty 
                        ? (itemImage.startsWith('http')
                            ? Image.network(
                                itemImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                              )
                            : Image.asset(
                                itemImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom, color: Colors.grey),
                              ))
                        : const Icon(Icons.checkroom, size: 40, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      isOwned
                          ? const Text(
                              "Owned",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              "$itemPrice G",
                              style: const TextStyle(
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