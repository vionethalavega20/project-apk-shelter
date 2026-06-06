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
      appBar: AppBar(title: const Text('Favorite')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('favoriteBy', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) return const Center(child: Text('Belum ada favorit.'));
          
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data()! as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['imageUrl'] ?? 'https://via.placeholder.com/100', 
                  width: 70, 
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Image.network('https://via.placeholder.com/100', width: 70, fit: BoxFit.cover),
                ),
                title: Text(data['description'] ?? 'Tanpa deskripsi'),
                subtitle: Text(data['locationName'] ?? 'Lokasi tidak diketahui'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId: posts[index].id,
                        postData: data, // <-- INI YANG DITAMBAHKAN
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}