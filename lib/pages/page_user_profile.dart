import 'package:flutter/material.dart';

// これは「他人の」プロフィール詳細を表示するページです
class Page_user_profile extends StatelessWidget {
  const Page_user_profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 全体の背景色

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // ↓↓↓↓ 【修正①】bottomNavigationBar を削除 ↓↓↓↓
      // bottomNavigationBar: _buildFixedLikeButton(),

      // ↓↓↓↓ 【修正②】body を Stack に変更 ↓↓↓↓
      body: Stack(
        children: [
          // 【1層目】スクロールするコンテンツ
          _buildScrollingContent(),

          // 【2層目】手前に浮き上がる「いいね！」ボタン
          _buildFloatingLikeButton(),
        ],
      ),
    );
  }

  /// 1層目：スクロールするコンテンツ
  Widget _buildScrollingContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMainPhotoCard(), // メイン写真 (AppBarの裏から表示)

          // 写真以外のコンテンツ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildNameAndLocation(), // 名前と基本情報
                const SizedBox(height: 16),
                _buildSelfIntroductionCard(), // 自己紹介
                const SizedBox(height: 16),
                _buildBasicInfoCard(), // 基本情報（詳細）
                const SizedBox(height: 16),
                _buildInterestsCard(), // 興味・関心タグ

                // ↓↓↓↓ 【修正③】超重要！ボタンが重なる分の「透明な余白」を一番下に追加 ↓↓↓↓
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2層目：画面下部に固定される「いいね！」ボタン
  Widget _buildFloatingLikeButton() {
    // Stackの中で Align を使うことで、特定の位置に固定できます
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // ↓↓↓↓ 【修正④】背景を透明に ↓↓↓↓
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        // SafeAreaで、OSのナビゲーションバー（iPhoneのホームバーなど）を避ける
        child: SafeArea(
          child: SizedBox(
            width: double.infinity, // 横幅いっぱいに広げる
            child: ElevatedButton.icon(
              onPressed: () {
                // 【フェーズ4】ここに「いいね！」ロジックを実装
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: const Text(
                'いいね！',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- ここから下は、コンテンツの中身 (変更なし) ---

  /// メインの写真カード
  Widget _buildMainPhotoCard() {
    // (変更なし)
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: const DecorationImage(
            image: NetworkImage('https://via.placeholder.com/400x600/CCCCCC/FFFFFF?text=PROFILE_IMAGE'),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[400],
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'オンライン',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 名前のエリア
  Widget _buildNameAndLocation() {
    // (変更なし)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'りょう 23歳 愛知',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Chip(
              label: Text('Partner'),
              backgroundColor: Colors.blueAccent,
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Chip(
              label: const Text('教えるよ: 化学'),
              backgroundColor: Colors.cyan[100],
              labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Chip(
              label: const Text('学びたい: デザイン'),
              backgroundColor: Colors.cyan[100],
              labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  /// 自己紹介カード
  Widget _buildSelfIntroductionCard() {
    // (変更なし)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '自己紹介文',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'はじめまして！ りょうです。\n\n'
                  '大学院で理学研究を専攻しており、\n'
                  '日々研究や研究発表に追われています。\n'
                  '化学の知識や実験データのまとめ方については\n'
                  '詳しく、人に教えることも多いです。\n\n'
                  'ただ、私には大きな悩みがあります。\n'
                  'どうしても見栄えが悪く、\n'
                  '伝えたいことが十分に伝わらないと感じています。',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// 基本情報カード
  Widget _buildBasicInfoCard() {
    // (変更なし)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow(icon: Icons.work_outline, label: '職業', value: '大学院生'),
            Divider(height: 20),
            _buildInfoRow(icon: Icons.school_outlined, label: '学歴', value: '大学卒'),
          ],
        ),
      ),
    );
  }

  /// 興味・関心カード
  Widget _buildInterestsCard() {
    // (変更なし)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '興味・関心',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Chip(
                  label: Text('化学'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                Chip(
                  label: Text('デザイン'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                // ...
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 基本情報カード内の一行
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    // (変更なし)
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
        Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}