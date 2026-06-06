import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shimmer/shimmer.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  String description = '';
  File? imageFile;
  Uint8List? imageData; // will hold compressed bytes (mobile + web)
  Position? position;
  bool loading = false;
  bool imageProcessing = false; // show shimmer while compressing

  Future<void> selectImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
      );

      if (picked != null) {
        setState(() {
          imageProcessing = true;
        });

        if (kIsWeb) {
          // On web: just read bytes (compression not supported reliably)
          imageData = await picked.readAsBytes();
          imageFile = null;
        } else {
          // On mobile: compress the selected file to reduce size
          final originalPath = picked.path;
          try {
            final compressedBytes = await FlutterImageCompress.compressWithFile(
              originalPath,
              quality: 85,
              minWidth: 1080,
              keepExif: false,
            );

            if (compressedBytes != null && compressedBytes.isNotEmpty) {
              imageData = Uint8List.fromList(compressedBytes);
              imageFile = null;
            } else {
              // fallback to original file if compression failed
              imageFile = File(originalPath);
              imageData = await File(originalPath).readAsBytes();
            }
          } catch (e) {
            // if compression throws, fallback to original file
            imageFile = File(originalPath);
            imageData = await File(originalPath).readAsBytes();
          }
        }

        setState(() {
          imageProcessing = false;
        });
      }
    } catch (error) {
      setState(() {
        imageProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $error')));
    }
  }

  Future<void> locate() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
      return;
    }

    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {});
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((imageFile == null && imageData == null) || position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto dan lokasi terlebih dahulu')),
      );
      return;
    }

    setState(() => loading = true);
    _formKey.currentState!.save();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final String? imageUrl = null; // tidak simpan placeholder URL

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'description': description,
        'imageUrl': imageUrl,
        'image': imageData != null ? base64Encode(imageData!) : null,
        'location': GeoPoint(position!.latitude, position!.longitude),
        'locationName': 'GPS: ${position!.latitude}, ${position!.longitude}',
        'createdAt': Timestamp.now(),
        'favoriteBy': [],
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan post: $error')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _imagePreview() {
    if (imageProcessing) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 220,
          color: Colors.white,
          width: double.infinity,
        ),
      );
    }

    if (imageData != null) {
      return Image.memory(imageData!, height: 220, fit: BoxFit.cover);
    }

    if (!kIsWeb && imageFile != null) {
      return Image.file(imageFile!, height: 220, fit: BoxFit.cover);
    }

    return Container(
      height: 220,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.photo, size: 48, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Tambah Post'),
        backgroundColor: Colors.blue.shade300,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Deskripsi hewan',
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isNotEmpty ? null : 'Masukkan deskripsi',
                  onSaved: (value) => description = value!.trim(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.photo),
                label: const Text('Pilih Foto'),
                onPressed: selectImage,
              ),
              const SizedBox(height: 12),
              _imagePreview(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.location_on),
                label: const Text('Ambil Lokasi GPS'),
                onPressed: locate,
              ),
              if (position != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Lokasi: ${position!.latitude}, ${position!.longitude}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : submit,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Post Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
