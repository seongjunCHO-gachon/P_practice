import 'package:flutter/material.dart';
import '../api/api_service.dart';
import 'photo_gallery_page.dart';
import 'SignUpScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhotoGalleryPage()),
      );
    }
  }
  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (id == 'master' && password == 'master1') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
      if (_rememberMe) {
        await prefs.setBool('isLoggedIn', true);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhotoGalleryPage()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await loginUser(id, password);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', id);
        if (_rememberMe) {
          await prefs.setBool('isLoggedIn', true);
        }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PhotoGalleryPage()),
          );
      } else {
        _showErrorDialog('로그인 실패', 'ID 또는 비밀번호가 올바르지 않습니다.');
      }
    } catch (e) {
      _showErrorDialog('오류', '로그인 중 문제가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'ID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                const Text('로그인 상태 유지'),
              ],
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('로그인'),
              ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}