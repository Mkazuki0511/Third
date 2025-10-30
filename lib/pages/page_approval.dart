import 'package:flutter/material.dart';
// import 'package:third/pages/page_user_profile.dart'; // 将来「詳しく見る」で使います

class Page_approval extends StatelessWidget {
  const Page_approval({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildTitleChip(), // 「相手からのリクエスト」
            const SizedBox(height: 16),

            // ↓↓↓↓ 【ここがキモです！】 ↓↓↓↓
            // Expanded + SingleChildScrollView で、カード部分だけをスクロール可能に
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  // 横幅を 32 にして、カードを少し狭く
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: _buildRequestCard(context),
                ),
              ),
            ),

            // アクションボタンはスクロール領域の外（画面最下部）に固定
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 「相手からのリクエスト」のタイトルチップ
  Widget _buildTitleChip() {
    // (変更なし)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: const Text(
        '相手からのリクエスト',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  /// メインのユーザーカード
  Widget _buildRequestCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 【ご要望①】正方形の写真
          AspectRatio(
            aspectRatio: 1 / 1, // 1:1 (正方形)
            child: Container(
              color: Colors.pink[100],
              child: const Center(child: Text('[ayakaさんのダミー画像]')),
            ),
          ),

          // 下部の情報エリア
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ayaka 20歳 愛知',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        '化学を教えて欲しいです。',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                // 【ご要望②】「学びたい」チップを追加
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('学びたい:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('化学'),
                      backgroundColor: Colors.cyan[100],
                      labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                // 【ご要望③】「詳しく見る」ボタンを追加
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context) =>  Page_user_profile(userId: ...)),);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('詳しく見る'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 下部の「スキップ」「承認」ボタン
  Widget _buildActionButtons() {
    // (変更なし)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: Icons.close,
            text: 'スキップ',
            color: Colors.grey,
            iconColor: Colors.white,
          ),
          _buildCircleButton(
            icon: Icons.check,
            text: '承認',
            color: Colors.cyan,
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }

  /// 円形のアクションボタンの共通ウィジェット
  Widget _buildCircleButton({
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
  }) {
    return Column(
      // ↓↓↓↓ 【タイポ修正！】 'MainAxisSizeM' -> 'MainAxisSize.min' ↓↓↓↓
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 40),
        ),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}