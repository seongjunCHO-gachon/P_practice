import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';

class UploadService {
  Future<void> uploadPhotosFromFolder(String folderPath, String uid) async {
    final directory = Directory(folderPath);

    if (!directory.existsSync()) {
      print("폴더가 존재하지 않습니다.");
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
      try {
        await _uploadPhoto(File(file.path), uid);
      } catch (e) {
        print('업로드 중 오류 발생: $e');
      }
    }
  }

  Future<void> _uploadPhoto(File photo, String uid) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverEndpoint/predict'),
      );
      request.fields['uid'] = uid; // UID 데이터 추가
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));

      final response = await request.send();



      if (response.statusCode == 200) {
        print('업로드 성공: ${photo.path}');
      } else {
        final errorBody = await response.stream.bytesToString();
        print('업로드 실패: ${response.statusCode}');
        print('서버 응답: $errorBody');
      }
    } catch (e) {
      print('업로드 중 오류 발생: $e');
    }
  }
}
