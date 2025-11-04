import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // ← ロジック実装（フェーズ5）で使います
// import 'page_onboarding_step4.dart'; // ← 次のステップで作成する詳細プロフページ

class Page_onboarding_step3 extends StatefulWidget {
  const Page_onboarding_step3({super.key});

  @override
  State<Page_onboarding_step3> createState() => _Page_onboarding_step3State();
}

class _Page_onboarding_step3State extends State<Page_onboarding_step3> {

  // bool _hasImage = false; // 将来、画像が選択されたかを管理する

  // 「メイン写真を登録する」ボタンが押されたときの処理
  void _showImagePickerModal(BuildContext context) {
    // `with-..-42.webp` のデザインで、下からモーダルを表示
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
              mainAxisSize: MainAxisSize.min, // 高さを最小に
              children: [
                _buildModalBadges(), // 「マッチングしにくい写真の例」
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ライブラリから選ぶ'),
                  onTap: () {
                    // 【フェーズ5】
                    // ここに image_picker でライブラリを起動するロジックを書く
                    print("ライブラリから選択");
                    Navigator.of(modalContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('写真を撮る'),
                  onTap: () {
                    // 【フェーズ5】
                    // ここに image_picker でカメラを起動するロジックを書く
                    print("写真を撮る");
                    Navigator.of(modalContext).pop();
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

  // `with-..-42.webp` の「マッチングしにくい写真の例」のバッジ
  Widget _buildModalBadges() {
    return Column(
      children: [
        const Text('マッチングしにくい写真の例', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBadge("暗い"),
            _buildBadge("顔がアップすぎる"),
            _buildBadge("顔が見えない"),
          ],
        ),
      ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. ヘッダー ---
            const Text(
              '次は、あなたの顔が写っている\nメイン写真を登録しましょう',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // --- 2. メイン写真のプレビュー (with-..-41.webp) ---
            Center(
              child: Container(
                width: 250,
                height: 300,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.cyan[50], // 薄いピンクの背景
                  shape: BoxShape.circle, // 円形
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    // TODO: 将来はここに選択した画像を表示する
                    child: Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. 登録ボタン ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                // ボタンが押されたら、`with-..-42.webp` のモーダルを表示
                _showImagePickerModal(context);
              },
              child: const Text(
                'メイン写真を登録する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '※写真はあとから変更可能です',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // --- 4. 「悪い例」のプレビュー (with-..-41.webp) ---
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '異性が好まない写真の例',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBadge("顔が隠れている"),
                _buildBadge("加工アプリ"),
                _buildBadge("本人が写っていない"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}