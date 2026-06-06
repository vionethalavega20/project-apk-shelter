import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Home Shelter'),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/sign_in');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada postingan hewan.'));
          }

          final posts = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data();

              final imageUrl = data['imageUrl'] as String?;
              final imageField = data['image'];
              final description = (data['description'] as String?) ?? '';
              final locationName =
                  (data['locationName'] as String?) ?? 'Lokasi tidak tersedia';

              Widget imageWidget;
              if (imageField != null) {
                if (imageField is String && imageField.isNotEmpty) {
                  try {
                    final bytes = base64Decode(imageField);
                    imageWidget = Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  } catch (_) {
                    imageWidget = Image.network(
                      imageField,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.network(
                            'https://via.placeholder.com/400',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                    );
                  }
                } else if (imageField is Uint8List) {
                  imageWidget = Image.memory(
                    imageField,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                } else if (imageField is List<int>) {
                  imageWidget = Image.memory(
                    Uint8List.fromList(imageField),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                } else {
                  imageWidget = Image.network(
                    imageUrl ?? 'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      'https://via.placeholder.com/400',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }
              } else if (imageUrl != null && imageUrl.isNotEmpty) {
                imageWidget = Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                );
              } else {
                imageWidget = Image.network(
                  'https://via.placeholder.com/400',
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PostDetailScreen(postId: doc.id, postData: data),
                    ),
                  );
                },
                child: Card(
                  color: Colors.blue.shade50,
                  shadowColor: Colors.blue.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: imageWidget),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          locationName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade300,
        onPressed: () {
          Navigator.pushNamed(context, '/add_post');
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Tambahan wajib jika item lebih dari 3 agar label tidak hilang
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.blueGrey,
        backgroundColor: Colors.blue.shade50,
        onTap: (index) {
          // Menyesuaikan index rute navigasi
          if (index == 1) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/favorites');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
          setState(() => currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ), // Tab Search
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
