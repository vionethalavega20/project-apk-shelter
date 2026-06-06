import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan user sudah login sebelum mengambil uid
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Favorite'),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('favoriteBy', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final posts = snapshot.data!.docs;
          if (posts.isEmpty)
            return const Center(child: Text('Belum ada favorit.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data()! as Map<String, dynamic>;
              final imageUrl = data['imageUrl'] as String?;
              final imageField = data['image'];

              Widget imageWidget;
              if (imageField != null) {
                if (imageField is String && imageField.isNotEmpty) {
                  try {
                    final bytes = base64Decode(imageField);
                    imageWidget = Image.memory(
                      bytes,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    );
                  } catch (_) {
                    imageWidget = Image.network(
                      imageField,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.network(
                            'https://via.placeholder.com/100',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                    );
                  }
                } else if (imageField is Uint8List) {
                  imageWidget = Image.memory(
                    imageField,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  );
                } else if (imageField is List<int>) {
                  imageWidget = Image.memory(
                    Uint8List.fromList(imageField),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = Image.network(
                    imageUrl ?? 'https://via.placeholder.com/100',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      'https://via.placeholder.com/100',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  );
                }
              } else if (imageUrl != null && imageUrl.isNotEmpty) {
                imageWidget = Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://via.placeholder.com/100',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                imageWidget = Image.network(
                  'https://via.placeholder.com/100',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                );
              }

              return Card(
                color: Colors.blue.shade50,
                shadowColor: Colors.blue.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
                  ),
                  title: Text(data['description'] ?? 'Tanpa deskripsi'),
                  subtitle: Text(
                    data['locationName'] ?? 'Lokasi tidak diketahui',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          postId: posts[index].id,
                          postData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
