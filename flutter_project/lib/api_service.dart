import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';


// 로그인 요청 함수
Future<bool> loginUser(String id, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$serverEndpoint/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'password': password}),
    );

    if (response.statusCode == 200) {
      return true; // 로그인 성공
    } else {
      print('로그인 실패: ${response.body}');
      return false; // 로그인 실패
    }
  } catch (e) {
    print('로그인 요청 중 오류: $e');
    return false;
  }
}

// 회원가입 요청 함수
Future<String> signUpUser(String id, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$serverEndpoint/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'password': password}),
    );

    if (response.statusCode == 201) {
      return 'success'; // 회원가입 성공
    } else if (response.statusCode == 409) {
      return 'exists'; // 이미 존재하는 아이디
    } else {
      print('회원가입 실패: ${response.body}');
      return 'error'; // 기타 오류
    }
  } catch (e) {
    print('회원가입 요청 중 오류: $e');
    return 'error';
  }
}

Future<List<Map<String, dynamic>>> searchPhotos(String query) async {
  final url = Uri.parse('$serverEndpoint/search?query=$query');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      return [];
    }
  } else {
    throw Exception('Failed to search photos: ${response.body}');
  }
}