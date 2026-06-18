import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  const PostDetailScreen({
    super.key,
    required this.postId,
    required Map<String, dynamic> postData,
  });

  Future<void> toggleFavorite(String postId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      final favorites = List<String>.from(snap['favoriteBy'] ?? []);
      if (favorites.contains(userId)) {
        favorites.remove(userId);
      } else {
        favorites.add(userId);
      }
      tx.update(postRef, {'favoriteBy': favorites});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Detail Post'),
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error memuat post: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Post tidak ditemukan'));
          }

          final data = snapshot.data!.data()! as Map<String, dynamic>;
          final location = data['location'] as GeoPoint;
          final favorites = List<String>.from(data['favoriteBy'] ?? []);
          final imageUrl = data['imageUrl'] as String?;
          final imageField = data['image'];

          Widget imageWidget;
          if (imageField != null) {
            if (imageField is String && imageField.isNotEmpty) {
              try {
                final bytes = base64Decode(imageField);
                imageWidget = Image.memory(
                  bytes,
                  height: 260,
                  fit: BoxFit.cover,
                );
              } catch (_) {
                imageWidget = Image.network(
                  imageField,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    'https://via.placeholder.com/400',
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                );
              }
            } else if (imageField is Uint8List) {
              imageWidget = Image.memory(
                imageField,
                height: 260,
                fit: BoxFit.cover,
              );
            } else if (imageField is List<int>) {
              imageWidget = Image.memory(
                Uint8List.fromList(imageField),
                height: 260,
                fit: BoxFit.cover,
              );
            } else {
              imageWidget = Image.network(
                imageUrl ?? 'https://via.placeholder.com/400',
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.network(
                  'https://via.placeholder.com/400',
                  height: 260,
                  fit: BoxFit.cover,
                ),
              );
            }
          } else if (imageUrl != null && imageUrl.isNotEmpty) {
            imageWidget = Image.network(
              imageUrl,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.network(
                'https://via.placeholder.com/400',
                height: 260,
                fit: BoxFit.cover,
              ),
            );
          } else {
            imageWidget = Image.network(
              'https://via.placeholder.com/400',
              height: 260,
              fit: BoxFit.cover,
            );
          }

          return ListView(
            children: [
              imageWidget,
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  data['description'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(
                height: 220,
                child: kIsWeb
                    ? Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Lokasi: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final url =
                                    'https://www.google.com/maps/search/${location.latitude},${location.longitude}';
                                try {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.platformDefault,
                                  );
                                } catch (e) {
                                  print('Error launching URL: $e');
                                }
                              },
                              child: const Text(
                                'Buka di Google Maps',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(location.latitude, location.longitude),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('postLocation'),
                            position: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            infoWindow: const InfoWindow(title: 'Lokasi Hewan'),
                          ),
                        },
                        zoomControlsEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      favorites.contains(userId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () => toggleFavorite(postId),
                  ),
                  Text('${favorites.length} favorit'),
                ],
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Komentar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('comments')
                    .where('postId', isEqualTo: postId)
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, commentSnapshot) {
                  // PENAMBAHAN PENGECEKAN ERROR DI SINI
                  if (commentSnapshot.hasError) {
                    print("FIRESTORE ERROR: ${commentSnapshot.error}");
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        'Database Error: ${commentSnapshot.error}\n\nJika ini masalah Index, cek Console/Terminal VS Code untuk mengklik link pembuatan Index otomatis.',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    );
                  }

                  if (commentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = commentSnapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada komentar, jadilah yang pertama!'),
                    );
                  }

                  return Column(
                    children: comments.map((doc) {
                      final comment = doc.data()! as Map<String, dynamic>;
                      return ListTile(
                        title: Text(comment['text'] ?? ''),
                        subtitle: Text(
                          comment['timestamp'] != null
                              ? (comment['timestamp'] as Timestamp)
                                    .toDate()
                                    .toString()
                              : '',
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CommentInput(postId: postId),
              ),
              const SizedBox(height: 40), // Jarak ekstra di bawah
            ],
          );
        },
      ),
    );
  }
}

class CommentInput extends StatefulWidget {
  final String postId;
  const CommentInput({super.key, required this.postId});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController controller = TextEditingController();
  bool isSubmitting = false;

  Future<void> submit() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSubmitting) return;

    setState(() => isSubmitting = true); // Mencegah spam klik

    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': widget.postId,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'text': text,
        'timestamp':
            FieldValue.serverTimestamp(), // Menggunakan serverTimestamp lebih aman
      });
      controller.clear();
      FocusScope.of(context).unfocus(); // Menutup keyboard setelah kirim
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim komentar: $e')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Tulis komentar...'),
            onSubmitted: (_) => submit(),
          ),
        ),
        IconButton(
          icon: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, color: Colors.blue),
          onPressed: submit,
        ),
      ],
    );
  }
}
