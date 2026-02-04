import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload single image
  Future<String?> uploadImage(File file, String folder) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('$folder/$fileName');
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> files, String folder) async {
    List<String> urls = [];
    
    for (File file in files) {
      final String? url = await uploadImage(file, folder);
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }

  // Upload video
  Future<String?> uploadVideo(File file, String folder) async {
    try {
      final String fileName = '${_uuid.v4()}.mp4';
      final Reference ref = _storage.ref().child('$folder/$fileName');
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // Upload multiple videos
  Future<List<String>> uploadVideos(List<File> files, String folder) async {
    List<String> urls = [];
    
    for (File file in files) {
      final String? url = await uploadVideo(file, folder);
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }

  // Delete file
  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}