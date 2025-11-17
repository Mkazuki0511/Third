import 'package:flutter/material.dart';
import 'package:third/main.dart'; // ← メイン画面（MyHomePage）をインポートします
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート

class Page_onboarding_step4 extends StatefulWidget {
  const Page_onboarding_step4({super.key});

  @override
  State<Page_onboarding_step4> createState() => _Page_onboarding_step4State();
}

class _Page_onboarding_step4State extends State<Page_onboarding_step4> {
  // Firebaseのインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ローディング状態を管理
  bool _isLoading = false;

  // テキスト入力を管理するコントローラー
  final TextEditingController _learnSkillController = TextEditingController();
  final TextEditingController _teachSkillController = TextEditingController();
  final TextEditingController _selfIntroController = TextEditingController();

  // 各 SelectorRow の選択値を保持する変数
  String? _learnSkillLevel;
  String? _teachSkillLevel;
  String? _exchangeMethod;
  String? _availableTime;

  // 各選択肢のリスト
  final List<String> _skillLevels = ['初心者', '中級者', '上級者', 'プロレベル'];
  final List<String> _exchangeMethods = ['対面のみ', 'オンラインのみ', 'どちらも可'];
  final List<String> _availableTimes = ['平日 昼', '平日 夜', '土日 祝日', 'いつでも可'];

  @override
  void dispose() {
    _learnSkillController.dispose();
    _teachSkillController.dispose();
    _selfIntroController.dispose();
    super.dispose();
  }

  // 「SKILL LINK をはじめる」ボタンが押されたときの処理
  Future<void> _goToHome() async {
    // 1. 現在のユーザーIDを取得 (Authから)
    final User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラー: ユーザーがログインしていません')),
        );
      }
      return; // 処理を中断
    }

    setState(() {
      _isLoading = true; // ローディング開始
    });

    try {
      // 2. Firestoreに保存するデータを作成
      final dataToUpdate = {
        'learnSkill': _learnSkillController.text.trim(),
        'teachSkill': _teachSkillController.text.trim(),
        'selfIntroduction': _selfIntroController.text.trim(),
        'learnSkillLevel': _learnSkillLevel,
        'teachSkillLevel': _teachSkillLevel,
        'exchangeMethod': _exchangeMethod,
        'availableTime': _availableTime,
        'tickets': 3, // 初期チケットとして 3枚 を付与
        'rank': 'beginner', // 初期ランク
        'experiencePoints': 0, // 経験値の初期値を設定
        'servicesProvidedCount': 0, // 「提供回数」の初期値 0 を追加
        'servicesUsedCount': 0, // 「利用回数」の初期値 0 を追加
        'totalRating': 0,       // 累計評価点の初期値
        'ratingCount': 0,       // 評価回数の初期値
      };

      // 3. Firestoreのユーザー情報を更新 (update)
      await _firestore.collection('users').doc(user.uid).update(dataToUpdate);

      // 4. 成功したら、メインのホーム画面（MyHomePage）に遷移
      if (mounted) {
        // pushAndRemoveUntil で、オンボーディング画面に戻れないようにします
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'SKILL LINK'),
      ),
          (route) => false, // 戻るルートをすべて削除
    );
  }

    } catch (e) {
      // エラー処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プロフィールの保存に失敗しました: $e')),
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

  /// --- 選択肢を表示する汎用ダイアログ ---
  Future<void> _showOptionDialog({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected, // 選択された値を親に返すコールバック
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
        title: const Text('プロフィールを作成'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // ↓↓↓↓ 【ローディングUIの追加】 ↓↓↓↓
      bottomNavigationBar: _buildBottomButtons(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- フォーム本体 ---
              //１．学びたいスキル
              _buildTextInputField(
                controller: _learnSkillController, // ← 接続
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

              // 2. 教えるスキル
              _buildTextInputField(
                controller: _teachSkillController, // ← 接続
                label: '教えることができるスキル',
                hint: '例：動画編集、プログラミング',
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

              // 3. スキル交換の方法
              _buildSelectorRow(
                label: 'スキルの交換方法',
                value: _exchangeMethod ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '交換方法を選択',
                  options: _exchangeMethods,
                  onSelected: (value) => setState(() => _exchangeMethod = value),
                ),
              ),

              // 4. 対応可能時間
              _buildSelectorRow(
                label: '対応可能時間',
                value: _availableTime ?? '未設定',
                onTap: () => _showOptionDialog(
                  title: '対応時間を選択',
                  options: _availableTimes,
                  onSelected: (value) => setState(() => _availableTime = value),
                ),
              ),

              // 5. 自己紹介
              _buildTextInputField(
                controller: _selfIntroController, // ← 接続
                label: '自己紹介',
                hint: 'あなたの人柄や熱意を教えてください',
                maxLines: 5, // 複数行
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 項目（ラベルと値）の共通ウィジェット (選択式)
  Widget _buildSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap, // ← 追加
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

  /// 項目（ラベルとテキスト入力）の共通ウィジェット
  // ↓↓↓↓ 【コントローラーを受け取るように変更】 ↓↓↓↓
  Widget _buildTextInputField({
    required TextEditingController controller, // ← 追加
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
            const Text(
              '※内容はあとから変更可能です',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // 保存して次へボタン
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                // ↓↓↓↓ 【ローディング中は無効化】 ↓↓↓↓
                disabledBackgroundColor: Colors.grey[300],
              ),
              // ↓↓↓↓ 【isLoading でボタンを無効化】 ↓↓↓↓
              onPressed: _isLoading ? null : _goToHome, // メイン画面へ！
              child: const Text(
                'SKILL LINK をはじめる', // ボタンの文言をゴールに合わせる
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}