import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Page_Profile_Editor extends StatefulWidget {
  const Page_Profile_Editor({super.key});

  @override
  State<Page_Profile_Editor> createState() => _Page_Profile_EditorState();
}

class _Page_Profile_EditorState extends State<Page_Profile_Editor> {
  // Firebaseのインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // ローディング状態
  bool _isLoading = false;
  bool _isDataLoading = true; // ← データ読み込み中の状態

  // テキスト入力を管理するコントローラー
  final TextEditingController _learnSkillController = TextEditingController();
  final TextEditingController _teachSkillController = TextEditingController();
  final TextEditingController _selfIntroController = TextEditingController();

  // 各 SelectorRow の選択値を保持する変数
  String? _learnSkillLevel;
  String? _teachSkillLevel;
  String? _exchangeMethod;
  String? _availableTime;

  // (page_onboarding_step4 からコピーした選択肢リスト)
  final List<String> _skillLevels = ['初心者', '中級者', '上級者', 'プロレベル'];
  final List<String> _exchangeMethods = ['対面のみ', 'オンラインのみ', 'どちらも可'];
  final List<String> _availableTimes = ['平日 日中', '平日 夜', '土日 祝日', 'いつでも可'];

  @override
  void initState() {
    super.initState();
    // ↓↓↓↓ 【ここがロジック】 ↓↓↓↓
    // ページが開かれた瞬間に、既存のデータを読み込む
    _loadCurrentUserData();
    // ↑↑↑↑ 【ここまで】 ↑↑↑↑
  }

  /// --- 1. 既存のプロフィールデータを読み込むロジック ---
  Future<void> _loadCurrentUserData() async {
    if (_currentUserUid == null) {
      setState(() { _isDataLoading = false; });
      return;
    }

    try {
      // 自分のドキュメントを 1回だけ取得 (get)
      final doc = await _firestore.collection('users').doc(_currentUserUid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 取得したデータで、コントローラーと変数を初期化
        setState(() {
          _learnSkillController.text = data['learnSkill'] ?? '';
          _teachSkillController.text = data['teachSkill'] ?? '';
          _selfIntroController.text = data['selfIntroduction'] ?? '';
          _learnSkillLevel = data['learnSkillLevel'];
          _teachSkillLevel = data['teachSkillLevel'];
          _exchangeMethod = data['exchangeMethod'];
          _availableTime = data['availableTime'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データの読み込みに失敗しました: $e')),
      );
    } finally {
      setState(() { _isDataLoading = false; });
    }
  }

  @override
  void dispose() {
    _learnSkillController.dispose();
    _teachSkillController.dispose();
    _selfIntroController.dispose();
    super.dispose();
  }


  /// --- 2. 「保存」ボタンが押されたときの処理 ---
  Future<void> _saveProfile() async {
    if (_currentUserUid == null) return;

    setState(() { _isLoading = true; });

    try {
      // Firestoreに保存するデータを作成
      final dataToUpdate = {
        'learnSkill': _learnSkillController.text.trim(),
        'teachSkill': _teachSkillController.text.trim(),
        'selfIntroduction': _selfIntroController.text.trim(),
        'learnSkillLevel': _learnSkillLevel,
        'teachSkillLevel': _teachSkillLevel,
        'exchangeMethod': _exchangeMethod,
        'availableTime': _availableTime,
      };

      // Firestoreのユーザー情報を更新 (update)
      await _firestore.collection('users').doc(_currentUserUid).update(dataToUpdate);

      // 成功したら、前の画面（プロフィール確認）に戻る
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました！')),
        );
        // ↓↓↓↓ 【修正】_goToHome から pop に変更 ↓↓↓↓
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プロフィールの更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // (page_onboarding_step4 からコピーしたダイアログ)
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
    height: 300, // 高さを固定
    child: ListView.builder(
    shrinkWrap: true,
    itemCount: options.length,
    itemBuilder: (BuildContext context, int index) {
    final option = options[index];
    return ListTile(
    title: Text(option),
    onTap: () {
    onSelected(option); // 選択された値をコールバックで返す
    Navigator.of(dialogContext).pop(); // ダイアログを閉じる
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
      // ↓↓↓↓ 【修正】ボタンのロジックを変更 ↓↓↓↓
      bottomNavigationBar: _buildBottomButtons(context),

      // ↓↓↓↓ 【修正】データ読み込み中か、保存中かでUIを切り替え ↓↓↓↓
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
              // --- フォーム本体 ---
              // (page_onboarding_step4 と同じフォーム)
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
            ],
          ),
        ),
      ),
    );
  }

  // (page_onboarding_step4 と同じUIメソッド)
  Widget _buildSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // ← 接続
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
            controller: controller, // ← 接続
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

  /// 画面下部のボタンエリア
  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 保存ボタン
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
              // ↓↓↓↓ 【修正】_goToHome -> _saveProfile に変更 ↓↓↓↓
              onPressed: _isLoading ? null : _saveProfile,
              child: const Text(
                '保存する', // ← 文言を「保存する」に変更
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}