import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginScreen.dart';
import '../api/upload.dart';
import '../api/api_service.dart';

class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  _PhotoGalleryPageState createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  List<FileSystemEntity> _photos = [];
  List<FileSystemEntity> _filteredPhotos = [];
  String _searchQuery = '';
  String? selectedFolderPath;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId(); // 사용자 ID 로드
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUserId = prefs.getString('userId');

    if (loadedUserId == null || loadedUserId.isEmpty) {
      // userId가 비어 있으면 로그아웃 처리 및 로그인 화면으로 이동
      _handleLogout(context);
    } else {
      setState(() {
        userId = loadedUserId;
      });
    }
  }

  Future<void> _pickFolder() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      final directory = Directory(directoryPath);
      // 선택된 폴더 내 모든 사진 파일 검색
      final photos = directory
          .listSync()
          .where((file) => ['jpg', 'jpeg', 'png', 'gif', 'webp']
          .contains(file.path.split('.').last.toLowerCase()))
          .toList();

      setState(() {
        _photos = photos;
        _filteredPhotos = _photos;
        selectedFolderPath = directoryPath;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
  }

  List<FileSystemEntity> _applySearchFilter(
      List<FileSystemEntity> photos, String query) {
    if (query.isEmpty) {
      return photos;
    }
    return photos.where((photo) {
      final fileName = photo.path.split(Platform.pathSeparator).last.toLowerCase();
      return fileName.contains(query.toLowerCase());
    }).toList();
  }

  void _updateSearchQuery(String? query) async {
    if (query == null || query.isEmpty) {
      // query가 null이거나 비어있을 때 처리
      setState(() {
        _searchQuery = '';
        _filteredPhotos = _photos;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
    });

    try {
      final photos = await searchPhotosByCategory(query, userId);
      setState(() {
        _filteredPhotos = photos.map((item) {
          if (selectedFolderPath != null) {
            final fullPath = "$selectedFolderPath/${item['title']}";
            return File(fullPath); // 현재 폴더 경로와 파일 이름을 결합
          } else {
            return null; // 예외적인 경우 null 반환
          }
        }).whereType<File>().toList(); // null 제거
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류 발생: $e')),
      );
    }
  }


  void _sortPhotos({required bool ascending}) {
    setState(() {
      _photos.sort((a, b) {
        final aTime = File(a.path).lastModifiedSync();
        final bTime = File(b.path).lastModifiedSync();
        return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
      });
      _filteredPhotos = _applySearchFilter(_photos, _searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: '사진 검색',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 텍스트 중앙 배치
          ),
          textAlign: TextAlign.start,
          textInputAction: TextInputAction.search,
          onSubmitted: _updateSearchQuery,
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                selectedFolderPath != null
                    ? "현재 폴더 위치:\n${selectedFolderPath!}"  // 폴더 경로를 표시
                    : "폴더를 선택하세요", // 폴더가 선택되지 않은 경우 기본 메시지
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('폴더 선택'),
              leading: const Icon(Icons.folder),
              onTap: () async {
                // 사용자로부터 폴더 경로를 선택받음
                await _pickFolder();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('업로드'),
              leading: const Icon(Icons.cloud_upload),
              onTap: () async {
                if (userId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사용자 ID를 로드하지 못했습니다. 다시 로그인해주세요.')),
                  );
                  return;
                }

                if (selectedFolderPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('폴더를 먼저 선택해주세요.')),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('업로드 중입니다. 잠시만 기다려 주세요...'),
                    duration: Duration(seconds: 60), // 메시지가 유지되도록 설정
                  ),
                );

                final folderName = selectedFolderPath!.split(Platform.pathSeparator).last;
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('업로드 확인'),
                      content: Text('선택된 폴더: "$folderName"의 파일을 업로드하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), // 취소
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true), // 확인
                          child: const Text('확인'),
                        ),
                      ],
                    );
                  },
                );
                if (confirm != true) {
                  return;
                }

                final uploadService = UploadService();
                try {
                  await uploadService.uploadPhotosFromFolder(selectedFolderPath!, userId);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('업로드가 완료되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('업로드 중 오류 발생: $e')),
                  );
                }
              },
            ),
            ExpansionTile(
              title: const Text('정렬'),
              leading: const Icon(Icons.sort),
              children: [
                Column(
                  children: [
                    const Divider(),
                    ListTile(
                      title: const Text(
                        '최근 사진부터 정렬',
                        style: TextStyle(fontSize: 12.0), // 폰트 크기 축소
                      ),
                      leading: const Icon(Icons.arrow_downward),
                      onTap: () {
                        _sortPhotos(ascending: false); // 내림차순 정렬
                        Navigator.pop(context); // 메뉴 닫기
                      },
                    ),
                    const Divider(), // 경계선 추가
                    ListTile(
                      title: const Text(
                        '오래된 사진부터 정렬',
                        style: TextStyle(fontSize: 12.0), // 폰트 크기 축소
                      ),
                      leading: const Icon(Icons.arrow_upward),
                      onTap: () {
                        _sortPhotos(ascending: true); // 오름차순 정렬
                        Navigator.pop(context); // 메뉴 닫기
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(), // 상단 메뉴와 로그아웃 버튼 구분선
            ListTile(
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: () async {
                await _handleLogout(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _filteredPhotos.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.')) // 검색 결과가 없을 때 메시지 표시
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _filteredPhotos.length,
              itemBuilder: (context, index) {
                final photo = _filteredPhotos[index];
                String photoPath = photo.path;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPhotoViewer(
                          photos: _filteredPhotos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: photoPath, // 고유 태그로 애니메이션 연결
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenPhotoViewer extends StatefulWidget {
  final List<FileSystemEntity> photos;
  final int initialIndex;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  _FullScreenPhotoViewerState createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  bool _disableSwipe = false; // 스와이프 비활성화 여부를 추적하는 변수

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          // 화면 탭 시 팝업 메뉴 표시
          _showOptionsMenu(
              widget.photos[_pageController.page!.toInt()]
          );
        },
        child: PageView.builder(
          controller: _pageController,
          physics: _disableSwipe
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return Center(
              child: Hero(
                tag: photo.path,
                child: InteractiveViewer(
                  panEnabled: true,
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  void _showOptionsMenu(FileSystemEntity photo) {
    final photoPath = photo.path;
    final photoTitle = photoPath
        .split('/')
        .last;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('사진 정보'),
                onTap: () {
                  Navigator.pop(context);
                  _showPhotoDetails(photo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('저장'),
                onTap: () {
                  Navigator.pop(context);
                  _showSaveConfirmation(photoPath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('카테고리 보기'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showPhotoCategory(photoTitle);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swipe),
                title: Text(
                    _disableSwipe ? '스와이프 활성화1' : '스와이프 비활성화'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _disableSwipe = !_disableSwipe;
                  });
                },
              ),

            ],
          ),
        );
      },
    );
  }

  void _showSaveConfirmation(String photoPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사진 저장'),
          content: Text('파일 경로: $photoPath\n\n이 파일을 저장하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 저장 취소
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final photoFile = File(photoPath);
                await _savePhoto(photoFile); // 사진 저장
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoDetails(FileSystemEntity photo) {
    final file = File(photo.path);
    final size = file.lengthSync();
    final modifiedDate = file.lastModifiedSync();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('파일 이름: ${file.path
                  .split(Platform.pathSeparator)
                  .last}'),
              Text('파일 크기: ${(size / 1024).toStringAsFixed(2)} KB'),
              Text('수정 날짜: $modifiedDate'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  } // 파일 선택
  Future<void> _savePhoto(File photoFile) async {
    // 저장 디렉토리 설정
    final directory = Directory('/storage/emulated/0/Download');
    if (!directory.existsSync()) {
      directory.createSync(); // 디렉토리가 없으면 생성
    }

    // 원본 파일 이름 가져오기
    final fileName = photoFile.path
        .split(Platform.pathSeparator)
        .last;

    // 중복된 파일 이름 처리
    final uniqueFileName = _getUniqueFileName(directory, fileName);
    final newPath = '${directory.path}/$uniqueFileName';

    try {
      // 파일 복사
      await photoFile.copy(newPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일이 저장되었습니다: $newPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _showPhotoCategory(String title) async {
    try {
      final categories = await fetchPhotoCategory(title);


      // `categories`가 null이거나 빈 값일 경우 기본 메시지 설정
      final categoryList = (categories.isNotEmpty)
          ? categories.join(', ')
          : '카테고리가 없습니다.';

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('사진 카테고리'),
            content: Text('카테고리: $categoryList'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('닫기'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카테고리 가져오기 오류: $e')),
      );
    }
  }

  String _getUniqueFileName(Directory directory, String fileName) {
    String uniqueFileName = fileName;
    int count = 1;

    // 파일 이름과 확장자 분리
    final nameWithoutExtension = fileName
        .split('.')
        .first;
    final extension = fileName
        .split('.')
        .last;

    // 중복된 파일 이름이 존재할 경우 새로운 이름 생성
    while (File('${directory.path}/$uniqueFileName').existsSync()) {
      uniqueFileName = '$nameWithoutExtension$count.$extension';
      count++;
    }

    return uniqueFileName;
  }

}