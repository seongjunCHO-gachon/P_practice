import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';

class UploadService {
  Future<void> uploadPhotosFromFolder(String folderPath, String uid) async {
    final directory = Directory(folderPath);

    if (!directory.existsSync()) {
      return;
    }
    final files = directory.listSync().where((file) {
      final extension = file.path
          .split('.')
          .last
          .toLowerCase();
      return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    });

    for (var file in files) {
        await _uploadPhoto(File(file.path), uid);
    }
  }

  Future<void> _uploadPhoto(File photo, String uid) async {

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverEndpoint/api/predict'),
      );
      request.fields['uid'] = uid; // UID
      // 데이터 추가
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));
      await request.send().timeout(const Duration(seconds: 60));
  }
}
