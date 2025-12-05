import 'dart:io'; // ← Fileクラスを使うために必要
import 'package:flutter/foundation.dart' show kIsWeb; // ← kIsWebをインポート
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ← image_picker をインポート
import 'package:firebase_storage/firebase_storage.dart'; // ← Storage をインポート
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
import 'page_onboarding_step4.dart'; // ← 次のステップ

// 状態（選択した画像ファイル）を記憶するために StatefulWidget に変更
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
  final List<XFile> _subImageFiles = []; // サブ写真リスト (最大6枚)
  bool _isLoading = false;


  Future<void> _pickImage(ImageSource source, {bool isMain = true}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          if (isMain) {
            _mainImageFile = pickedFile;
          } else {
            if (_subImageFiles.length < 6) {
              _subImageFiles.add(pickedFile);
            }
          }
        });
        if (mounted) Navigator.of(context).pop(); // モーダルを閉じる
      }
    } catch (e) {
      print("画像選択エラー: $e");
      if (mounted) Navigator.of(context).pop(); // エラーでもモーダルを閉じる
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
      return; // 処理を中断
    }

    // 2. 現在のユーザーIDを取得 (Authから)
    final User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラー: ユーザーがログインしていません')),
      );
      return; // 処理を中断
    }

    setState(() {
      _isLoading = true; // ローディング開始
    });

    try {
      // 3. Storageにアップロード
      // メイン写真のアップロード
      String mainImageUrl = '';
      final String mainPath = 'profile_images/${user.uid}/main_profile.jpg';
      final mainRef = _storage.ref().child(mainPath);

      if (kIsWeb) {
        // Webの場合：Uint8List (バイトデータ) としてアップロード
        await mainRef.putData(await _mainImageFile!.readAsBytes());
      } else {
        // Mobileの場合：File としてアップロード
        await mainRef.putFile(File(_mainImageFile!.path));
      }
      mainImageUrl = await mainRef.getDownloadURL();

      // サブ写真のアップロード
      List<String> subImageUrls = [];
      for (int i = 0; i < _subImageFiles.length; i++) {
        final String subPath = 'profile_images/${user.uid}/sub_profile_$i.jpg';
        final subRef = _storage.ref().child(subPath);

        if (kIsWeb) {
          await subRef.putData(await _subImageFiles[i].readAsBytes());
        } else {
          await subRef.putFile(File(_subImageFiles[i].path));
        }
        final String url = await subRef.getDownloadURL();
        subImageUrls.add(url);
      }

      // 4. Firestoreのユーザー情報を更新
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': mainImageUrl,
        'subProfileImageUrls': subImageUrls,
      });

      // 5. 成功したら次のStep4（詳細プロフ）へ
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const Page_onboarding_step4(),
        ));
      }

    } catch (e) {
      // エラー処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードに失敗しました: $e')),
        );
      }
    } finally {
      // 処理が完了したらローディングを解除
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
            // --- 1. ヘッダー (変更なし) ---
            const Text(
              '次は、あなたの顔が写っている\nメイン写真を登録しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // メイン写真
            Center(
              // ↓↓↓↓ 【タップ可能にする】 ↓↓↓↓
              child: GestureDetector(
                onTap: () {
                  // プレビュー画像をタップしてもモーダルが開くようにする
                  _showImagePickerModal(context);
                },
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.cyan[50],
                    shape: BoxShape.circle,
                    image: _mainImageFile  != null
                        ? DecorationImage(
                      image: (kIsWeb
                          ? NetworkImage(_mainImageFile!.path)
                          : FileImage(File(_mainImageFile!.path))) as ImageProvider,
                      fit: BoxFit.cover,
                  )
                        : null,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _mainImageFile == null
                      ? const Icon(Icons.person_add_alt_1, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('メイン写真', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // --- サブ写真エリア ---
            const Text(
              'サブ写真 (最大6枚)',
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
              itemCount: _subImageFiles.length + (_subImageFiles.length < 6 ? 1 : 0),
              itemBuilder: (context, index) {
                // 「追加ボタン」を表示する場合
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

                // 選択済み画像を表示する場合
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
                              : FileImage(File(file.path))) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // 削除ボタン
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
                // ↓↓↓↓ 【画像が選択されていなければ無効】 ↓↓↓↓
                disabledBackgroundColor: Colors.grey[300],
              ),
              // ↓↓↓↓ 【画像がなければ押せない(null)、あれば _uploadAndNavigate を呼ぶ】 ↓↓↓↓
              onPressed: _mainImageFile != null ? _uploadAndNavigate : null,
              child: const Text(
                '次へ', // ← 文言を「次へ」に変更
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // --- スキップボタン ---
            // メイン写真の登録は必須ではない（あとからでも良い）場合
            TextButton(
              onPressed: () {
                // 画像を登録せずに次のStep4へ
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