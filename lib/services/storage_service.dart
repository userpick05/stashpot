import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Uploads user photos to Firebase Storage and returns their download URL.
class StorageService {
  final FirebaseStorage _storage;
  StorageService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  static const _timeout = Duration(seconds: 45);

  /// Uploads [bytes] (JPEG) under the household and returns a download URL.
  Future<String> uploadImage(String householdId, Uint8List bytes) async {
    final ref = _storage
        .ref('households/$householdId/images/${const Uuid().v4()}.jpg');
    await ref
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
        .timeout(_timeout);
    return ref.getDownloadURL();
  }
}
