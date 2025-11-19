import 'dart:io'; // ← Fileクラスを使うために必要
import 'package:flutter/foundation.dart' show kIsWeb; // ← 【修正①】kIsWebをインポート
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

  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ↓↓↓↓ 【修正②】File? から XFile? に変更 ↓↓↓↓
  XFile? _imageFile; // File? _image;
  bool _isLoading = false;

  // ImagePickerのインスタンス
  final ImagePicker _picker = ImagePicker();

  /// --- 1. 画像を選択するロジック ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        // ↓↓↓↓ 【修正③】pickedFileをそのままセット ↓↓↓↓
        setState(() {
          _imageFile = pickedFile; // File(pickedFile.path) にしない
        });
        if (mounted) Navigator.of(context).pop(); // モーダルを閉じる
      }
    } catch (e) {
      print("画像選択エラー: $e");
      if (mounted) Navigator.of(context).pop(); // エラーでもモーダルを閉じる
    }
  }

  /// --- 2. 画像をアップロードして次に進むロジック ---
  Future<void> _uploadAndNavigate() async {
    // 1. 画像が選択されているかチェック
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まず、写真を選択してください')),
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
      final String filePath = 'profile_images/${user.uid}/main_profile.jpg';
      final ref = _storage.ref().child(filePath);

      // ↓↓↓↓ 【修正④】kIsWeb でアップロード方法を分岐 ↓↓↓↓
      if (kIsWeb) {
        // Webの場合：Uint8List (バイトデータ) としてアップロード
        await ref.putData(await _imageFile!.readAsBytes());
      } else {
        // Mobileの場合：File としてアップロード
        await ref.putFile(File(_imageFile!.path));
      }
      // ↑↑↑↑ 【ここまで】 ↑↑↑↑

      // 4. アップロードした画像のURLを取得
      final String downloadUrl = await ref.getDownloadURL();

      // 5. Firestoreのユーザー情報を更新
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl, // FirestoreのURLを更新
      });

      // 6. 成功したら次のStep4（詳細プロフ）へ
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


  // 「メイン写真を登録する」ボタンが押されたときの処理
  void _showImagePickerModal(BuildContext context) {
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
                  onTap: () {
                    // ↓↓↓↓ 【ここがロジック】 ↓↓↓↓
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('写真を撮る'),
                  onTap: () {
                    // ↓↓↓↓ 【ここがロジック】 ↓↓↓↓
                    _pickImage(ImageSource.camera);
                  },
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


  Widget _buildBadge(String text) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.error_outline, color: Colors.red), // ダミー
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
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
      // ↓↓↓↓ 【ローディングUIの追加】 ↓↓↓↓
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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

            // --- 2. メイン写真のプレビュー (変更！) ---
            Center(
              // ↓↓↓↓ 【タップ可能にする】 ↓↓↓↓
              child: GestureDetector(
                onTap: () {
                  // プレビュー画像をタップしてもモーダルが開くようにする
                  _showImagePickerModal(context);
                },
                child: Container(
                  width: 250,
                  height: 300,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.cyan[50],
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                      // ↓↓↓↓ 【画像が選択されたら表示】 ↓↓↓↓
                      image: _imageFile != null
                          ? DecorationImage(
                              image: (kIsWeb
                                  ? NetworkImage(_imageFile!.path) // Web用
                                  : FileImage(File(_imageFile!.path)) // Mobile用
                              ) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    // ↓↓↓↓ 【画像がなければアイコン表示】 ↓↓↓↓
                    child: _imageFile == null
                        ? const Center(
                      child: Icon(Icons.person_add_alt_1, size: 80, color: Colors.grey),
                    )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. 登録ボタン (変更！) ---
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
              onPressed: _imageFile != null ? _uploadAndNavigate : null,
              child: const Text(
                '次へ', // ← 文言を「次へ」に変更
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // --- 4. スキップボタン (新設) ---
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