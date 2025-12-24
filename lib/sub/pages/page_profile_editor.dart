import 'dart:io'; // モバイル用
import 'package:flutter/foundation.dart'; // kIsWeb用
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class Page_Profile_Editor extends StatefulWidget {
  const Page_Profile_Editor({super.key});

  @override
  State<Page_Profile_Editor> createState() => _Page_Profile_EditorState();
}

class _Page_Profile_EditorState extends State<Page_Profile_Editor> {
  // Firebaseインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? get _currentUserUid => _auth.currentUser?.uid;

  // ローディング状態
  bool _isLoading = false;
  bool _isDataLoading = true;

  // テキスト入力コントローラー
  final TextEditingController _learnSkillController = TextEditingController();
  final TextEditingController _teachSkillController = TextEditingController();
  final TextEditingController _selfIntroController = TextEditingController();

  // 選択値
  String? _learnSkillLevel;
  String? _teachSkillLevel;
  String? _exchangeMethod;
  String? _availableTime;

  // --- 画像関連の変数 ---
  // メイン画像: 既存URL(String) または 新規選択画像(XFile)
  String? _mainImageUrl;
  XFile? _newMainImageFile; // FileではなくXFileで保持

  // サブ画像: URL(String) または 新規選択画像(XFile) が混在するリスト
  List<dynamic> _subImages = [];
  final int _maxSubImages = 5;

  // 選択肢リスト
  final List<String> _skillLevels = ['初心者', '中級者', '上級者', 'プロレベル'];
  final List<String> _exchangeMethods = ['対面のみ', 'オンラインのみ', 'どちらも可'];
  final List<String> _availableTimes = ['平日 日中', '平日 夜', '土日 祝日', 'いつでも可'];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  /// --- 1. 既存データの読み込み ---
  Future<void> _loadCurrentUserData() async {
    if (_currentUserUid == null) {
      setState(() => _isDataLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(_currentUserUid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        setState(() {
          _learnSkillController.text = data['learnSkill'] ?? '';
          _teachSkillController.text = data['teachSkill'] ?? '';
          _selfIntroController.text = data['selfIntroduction'] ?? '';
          _learnSkillLevel = data['learnSkillLevel'];
          _teachSkillLevel = data['teachSkillLevel'];
          _exchangeMethod = data['exchangeMethod'];
          _availableTime = data['availableTime'];

          // 画像データの読み込み
          _mainImageUrl = data['profileImageUrl'];

          // サブ写真リスト読み込み (フィールド名は subProfileImageUrls)
          if (data['subProfileImageUrls'] != null && data['subProfileImageUrls'] is List) {
            _subImages = List.from(data['subProfileImageUrls']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isDataLoading = false);
    }
  }

  @override
  void dispose() {
    _learnSkillController.dispose();
    _teachSkillController.dispose();
    _selfIntroController.dispose();
    super.dispose();
  }

  /// --- 画像選択ロジック ---

  Future<void> _pickMainImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          // XFileのまま保持する
          _newMainImageFile = picked;
        });
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
    }
  }

  Future<void> _pickSubImage() async {
    if (_subImages.length >= _maxSubImages) return;

    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _subImages.add(picked);
        });
      }
    } catch (e) {
      debugPrint('画像選択エラー: $e');
    }
  }

  /// --- 画像アップロード用ヘルパー ---
  /// Webとモバイルでアップロード方法を分ける関数
  Future<void> _uploadFile(Reference ref, XFile file) async {
    if (kIsWeb) {
      // Web: バイトデータでアップロード
      final bytes = await file.readAsBytes();
      await ref.putData(bytes);
    } else {
      // Mobile: ファイルパスからアップロード
      await ref.putFile(File(file.path));
    }
  }

  /// --- 2. 保存処理 ---
  Future<void> _saveProfile() async {
    if (_currentUserUid == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. メイン画像のアップロード処理
      String? finalMainUrl = _mainImageUrl;

      if (_newMainImageFile != null) {
        // 新しい画像がある場合
        final String fileName = 'main_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child('profile_images/$_currentUserUid/$fileName');

        await _uploadFile(ref, _newMainImageFile!); // ヘルパー関数を使用
        finalMainUrl = await ref.getDownloadURL();

      } else if (_mainImageUrl == null) {
        // 画像が削除された場合
        finalMainUrl = null;
      }

      // 2. サブ画像のアップロード処理
      List<String> finalSubUrls = [];

      for (int i = 0; i < _subImages.length; i++) {
        final item = _subImages[i];

        if (item is String) {
          // 既存URLはそのまま
          finalSubUrls.add(item);
        } else if (item is XFile) {
          // 新規画像はアップロード
          final String fileName = 'sub_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final Reference ref = _storage.ref().child('profile_images/$_currentUserUid/$fileName');

          await _uploadFile(ref, item); // ヘルパー関数を使用
          final String url = await ref.getDownloadURL();
          finalSubUrls.add(url);
        }
      }

      // 3. Firestore更新
      final dataToUpdate = {
        'learnSkill': _learnSkillController.text.trim(),
        'teachSkill': _teachSkillController.text.trim(),
        'selfIntroduction': _selfIntroController.text.trim(),
        'learnSkillLevel': _learnSkillLevel,
        'teachSkillLevel': _teachSkillLevel,
        'exchangeMethod': _exchangeMethod,
        'availableTime': _availableTime,

        // 画像フィールド
        'profileImageUrl': finalMainUrl,
        'subProfileImageUrls': finalSubUrls, // 正しいフィールド名
      };

      await _firestore.collection('users').doc(_currentUserUid).update(dataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました！')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ダイアログ表示
  Future<void> _showOptionDialog({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final option = options[index];
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    onSelected(option);
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  /// プレビュー表示用のImageProviderを取得するヘルパー
  ImageProvider? _getImageProvider(dynamic imageSource) {
    if (imageSource == null) return null;

    if (imageSource is String) {
      // URLの場合
      return NetworkImage(imageSource);
    } else if (imageSource is XFile) {
      // 新規選択画像の場合
      if (kIsWeb) {
        // Web: Blob URLとして読み込む
        return NetworkImage(imageSource.path);
      } else {
        // Mobile: ファイルパスから読み込む
        return FileImage(File(imageSource.path));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('プロフィールを編集'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      bottomNavigationBar: _buildBottomButtons(context),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 画像編集エリア ---
              const Text('メイン写真', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildMainImageEditor(),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('サブ写真', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_subImages.length} / $_maxSubImages', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              _buildSubImagesEditor(),
              const SizedBox(height: 24),
              // --------------------

              _buildTextInputField(
                controller: _learnSkillController,
                label: '学びたいスキル',
                hint: '例：デザイン、英語',
              ),
              _buildSelectorRow(
                label: '学びたいスキルのレベル',
                value: _learnSkillLevel ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '学びたいレベルを選択',
                  options: _skillLevels,
                  onSelected: (value) => setState(() => _learnSkillLevel = value),
                ),
              ),
              _buildTextInputField(
                controller: _teachSkillController,
                label: '教えることができるスキル',
                hint: '例：化学、プログラミング',
              ),
              _buildSelectorRow(
                label: '教えるスキルのレベル',
                value: _teachSkillLevel ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '教えるレベルを選択',
                  options: _skillLevels,
                  onSelected: (value) => setState(() => _teachSkillLevel = value),
                ),
              ),
              _buildSelectorRow(
                label: 'スキルの交換方法',
                value: _exchangeMethod ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '交換方法を選択',
                  options: _exchangeMethods,
                  onSelected: (value) => setState(() => _exchangeMethod = value),
                ),
              ),
              _buildSelectorRow(
                label: '対応可能時間',
                value: _availableTime ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '対応時間を選択',
                  options: _availableTimes,
                  onSelected: (value) => setState(() => _availableTime = value),
                ),
              ),
              _buildTextInputField(
                controller: _selfIntroController,
                label: '自己紹介',
                hint: 'あなたの人柄や熱意を教えてください',
                maxLines: 5,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImageEditor() {
    // 優先順位: 新規画像 > 既存URL
    dynamic imageSource;
    if (_newMainImageFile != null) {
      imageSource = _newMainImageFile;
    } else if (_mainImageUrl != null && _mainImageUrl!.isNotEmpty) {
      imageSource = _mainImageUrl;
    }

    final imageProvider = _getImageProvider(imageSource);

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickMainImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          if (imageProvider != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _newMainImageFile = null;
                  _mainImageUrl = null;
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('削除', style: TextStyle(color: Colors.red)),
            )
          else
            TextButton(
              onPressed: _pickMainImage,
              child: const Text('写真を変更'),
            ),
        ],
      ),
    );
  }

  Widget _buildSubImagesEditor() {
    final bool canAdd = _subImages.length < _maxSubImages;
    final int itemCount = _subImages.length + (canAdd ? 1 : 0);

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // 追加ボタン
          if (canAdd && index == _subImages.length) {
            return GestureDetector(
              onTap: _pickSubImage,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 30, color: Colors.grey),
                    Text('追加', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          // 画像アイテム
          final imageItem = _subImages[index];
          final provider = _getImageProvider(imageItem);

          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: provider != null
                      ? DecorationImage(image: provider, fit: BoxFit.cover)
                      : null,
                  color: Colors.grey[300], // 画像がない場合の背景
                ),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _subImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text(
                '保存する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}