import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'page_onboarding_step4.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart'; // モバイルの一時保存に必要

class Page_onboarding_step3 extends StatefulWidget {
  const Page_onboarding_step3({super.key});

  @override
  State<Page_onboarding_step3> createState() => _Page_onboarding_step3State();
}

class _Page_onboarding_step3State extends State<Page_onboarding_step3> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  XFile? _mainImageFile; // メイン写真
  final List<XFile> _subImageFiles = []; // サブ写真リスト (最大5枚)
  bool _isLoading = false;

  /// 画像選択ロジック
  Future<void> _pickImage(ImageSource source, {bool isMain = true}) async {
    try {
      // 1. まず標準機能でリサイズしながら取得
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      XFile finalFile = pickedFile;

      // 2. モバイル版のみ、この時点で強力に圧縮してファイルを差し替える
      // (Web版はプレビュー表示を優先するため、アップロード直前に圧縮します)
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          minWidth: 800,
          minHeight: 800,
          quality: 50, // 画質50% (数百KB程度になります)
        );

        if (compressedFile != null) {
          finalFile = compressedFile;
        }
      }

      // 3. 画面を更新 (Webでもモバイルでも必ず実行される場所に配置)
      setState(() {
        if (isMain) {
          _mainImageFile = finalFile;
        } else {
          if (_subImageFiles.length < 5) {
            _subImageFiles.add(finalFile);
          }
        }
      });

      if (mounted) Navigator.of(context).pop(); // モーダルを閉じる

    } catch (e) {
      debugPrint("画像選択エラー: $e");
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _removeSubImage(int index) {
    setState(() {
      _subImageFiles.removeAt(index);
    });
  }

  void _showImagePickerModal(BuildContext context, {bool isMain = true}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ライブラリから選ぶ'),
                  onTap: () => _pickImage(ImageSource.gallery, isMain: isMain),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('写真を撮る'),
                  onTap: () => _pickImage(ImageSource.camera, isMain: isMain),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  child: const Text('閉じる', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 画像をアップロードして次に進むロジック
  Future<void> _uploadAndNavigate() async {
    // 1. 画像が選択されているかチェック
    if (_mainImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まず、メイン写真を選択してください')),
      );
      return;
    }

    // 2. ユーザーID取得
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラー: ユーザーがログインしていません')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Storageにアップロード
      String mainImageUrl = '';
      final String mainPath = 'profile_images/${user.uid}/main_profile.jpg';
      final mainRef = _storage.ref().child(mainPath);

      // --- メイン画像のアップロード処理 ---
      if (kIsWeb) {
        // Web版：ここで圧縮を行ってからアップロード
        final Uint8List bytes = await _mainImageFile!.readAsBytes();
        final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 800,
          minHeight: 800,
          quality: 50,
          format: CompressFormat.jpeg,
        );
        await mainRef.putData(compressedBytes);
      } else {
        // モバイル版：すでに圧縮済みなのでそのままアップロード
        await mainRef.putFile(File(_mainImageFile!.path));
      }
      mainImageUrl = await mainRef.getDownloadURL();

      // --- サブ画像のアップロード処理 ---
      List<String> subImageUrls = [];
      for (int i = 0; i < _subImageFiles.length; i++) {
        final String subPath = 'profile_images/${user.uid}/sub_profile_$i.jpg';
        final subRef = _storage.ref().child(subPath);

        if (kIsWeb) {
          // Web版：圧縮してアップロード
          final Uint8List bytes = await _subImageFiles[i].readAsBytes();
          final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 800,
            minHeight: 800,
            quality: 50,
            format: CompressFormat.jpeg,
          );
          await subRef.putData(compressedBytes);
        } else {
          // モバイル版：そのままアップロード
          await subRef.putFile(File(_subImageFiles[i].path));
        }
        final String url = await subRef.getDownloadURL();
        subImageUrls.add(url);
      }

      // 4. Firestore更新
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': mainImageUrl,
        'subProfileImageUrls': subImageUrls,
      });

      // 5. 次へ
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const Page_onboarding_step4(),
        ));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '次は、あなたの顔が写っている\nメイン写真を登録しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // --- メイン写真エリア ---
            Center(
              child: GestureDetector(
                onTap: () => _showImagePickerModal(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _mainImageFile != null
                            ? DecorationImage(
                          image: (kIsWeb
                              ? NetworkImage(_mainImageFile!.path)
                              : FileImage(File(_mainImageFile!.path)))
                          as ImageProvider,
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _mainImageFile == null
                          ? const Icon(Icons.person, size: 100, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Text('メイン写真', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // --- サブ写真エリア ---
            const Text(
              'サブ写真 (最大5枚)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _subImageFiles.length + (_subImageFiles.length < 5 ? 1 : 0),
              itemBuilder: (context, index) {
                // 追加ボタン
                if (index == _subImageFiles.length) {
                  return GestureDetector(
                    onTap: () => _showImagePickerModal(context, isMain: false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  );
                }

                // 選択済み画像
                final file = _subImageFiles[index];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: (kIsWeb
                              ? NetworkImage(file.path)
                              : FileImage(File(file.path)))
                          as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => _removeSubImage(index),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // --- 登録ボタン ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              onPressed: _mainImageFile != null ? _uploadAndNavigate : null,
              child: const Text(
                '次へ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // --- スキップボタン ---
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const Page_onboarding_step4(),
                ));
              },
              child: const Text(
                'あとで登録する',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}