import 'package:flutter/material.dart';
import 'package:third/main.dart'; // ← メイン画面（MyHomePage）をインポートします

class Page_onboarding_step4 extends StatefulWidget {
  const Page_onboarding_step4({super.key});

  @override
  State<Page_onboarding_step4> createState() => _Page_onboarding_step4State();
}

class _Page_onboarding_step4State extends State<Page_onboarding_step4> {
  // TODO: 各項目の選択値を保持する変数を（将来的に）追加する
  // String? _location;
  // String? _teachSkillLevel;
  // ...

  // 「保存して次へ」ボタンが押されたときの処理
  void _goToHome() {
    // 【フェーズ5】
    // ここで、Step1からStep4までの「すべての情報」を
    // Firebase Firestore の `users` コレクションに保存する
    // ロジックを（将来）呼び出します。

    // 全ての登録が完了したので、メインのホーム画面（MyHomePage）に遷移します
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'SKILL LINK'),
      ),
          (route) => false, // 戻るルートをすべて削除
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
      bottomNavigationBar: _buildBottomButtons(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- フォーム本体 (差し替え) ---
              _buildTextInputField(label: '学びたいスキル', hint: '例：デザイン、英語'),
              _buildSelectorRow(label: '学びたいスキルのレベル', value: '未設定'),
              _buildTextInputField(label: '教えることができるスキル', hint: '例：化学、プログラミング'),
              _buildSelectorRow(label: '教えるスキルのレベル', value: '未設定'),
              _buildSelectorRow(label: 'スキルの交換方法', value: '未設定'),
              _buildSelectorRow(label: '対応可能時間', value: '未設定'),
              _buildTextInputField(
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
  Widget _buildSelectorRow({required String label, required String value}) {
    return GestureDetector(
      onTap: () {
        // TODO: 各項目（出身地など）の選択ロジックを実装
        print("$label がタップされました");
      },
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

  /// 項目（ラベルとテキスト入力）の共通ウィジェット (新設)
  Widget _buildTextInputField({
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
      // SafeAreaでOSのホームバーなどを避ける
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
              ),
              onPressed: _goToHome, // メイン画面へ！
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