import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';


// 로그인 요청 함수
Future<bool> loginUser(String id, String password) async {
  final response = await http.post(
    Uri.parse('$serverEndpoint/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': id, 'password': password}),
  );

  if (response.statusCode == 200) {
    return true; // 로그인 성공
  } else {
    return false; // 로그인 실패
  }
}

// 회원가입 요청 함수
Future<String> signUpUser(String id, String password) async {
  final response = await http.post(
    Uri.parse('$serverEndpoint/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': id, 'password': password}),
  );

  if (response.statusCode == 201) {
    return 'success'; // 회원가입 성공
  } else if (response.statusCode == 409) {
    return 'exists'; // 이미 존재하는 아이디
  } else {
    return 'error'; // 기타 오류
  }
}


Future<List<Map<String, dynamic>>> searchPhotosByCategory(String category, String uid) async {
  final url = Uri.parse('$serverEndpoint/api/search');

  try {
    // POST 요청 보내기
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': category,
        'uid': uid,
      }),
    );

    // HTTP 상태 코드 확인
    if (response.statusCode == 200) {
      // JSON 응답 파싱
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      // 'data' 필드에서 리스트 추출
      final List<dynamic> dataList = jsonResponse['data'] ?? [];


      // 각 객체에서 'predictions' 추출 및 변환
      final List<Map<String, dynamic>> photos = dataList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final Set<String> seenTitles = {};

      final List<Map<String, dynamic>> uniquePhotos = [];

      for (var photo in photos) {
        if (photo.containsKey('predictions') && photo['predictions'] is List) {
          // 중복 제거
          List<String> predictions = List<String>.from(photo['predictions']);
          List<String> uniquePredictions = predictions.toSet().toList();

          // 중복 제거된 predictions 업데이트
          photo['predictions'] = uniquePredictions;
        }
        photo.remove('pid');
        photo.remove('uid');

        if (!seenTitles.contains(photo['title'])) {
          seenTitles.add(photo['title']);
          uniquePhotos.add(photo);
        }
      }
      return uniquePhotos;
    } else {
      // 오류 상태 처리
      throw Exception('Failed to search photos: ${response.statusCode}');
    }
  } catch (e) {
    // 예외 처리
    throw Exception("Error searching photos: $e");
  }
}


Future<List<String>> fetchPhotoCategory(String title) async {
  final url = Uri.parse('$serverEndpoint/api/get_photo_category');
  final body = jsonEncode({"title": title});

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    // 데이터를 문자열 리스트로 변환
    final List<String> categories = List<String>.from(data);
    return categories;
  } else {
    throw Exception(
        'Error fetching photo category: ${response.statusCode} - ${response
            .reasonPhrase}');
  }
}