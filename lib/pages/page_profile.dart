import 'package:flutter/material.dart';
// import 'package:third/sub/pages/page_profile.edit.dart'; // 将来的に使います

class Page_profile extends StatelessWidget {
  const Page_profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 背景を少しグレーに
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildRankCard(),
                const SizedBox(height: 16),
                _buildBadgesCard(),
                const SizedBox(height: 16),
                _buildMenuList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー（アイコン、統計、編集ボタン）
  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              // backgroundImage: NetworkImage('...'),
            ),
            const SizedBox(width: 16),
            // 統計情報を横に並べる
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('5', '残チケット'),
                  _buildStatColumn('無料', 'プラン'),
                  _buildStatColumn('2', '提供サービス'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 「プロフィールを確認・編集」ボタン
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('プロフィールを確認・編集'),
            onPressed: () {
              // ここに、前回作成した「公開プロフィール」UIのページへの遷移を書く
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  /// 統計表示用の共通ウィジェット
  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// ランクカード
  Widget _buildRankCard() {
    return Card(
      color: Colors.yellow[100], // ゴールドランクの色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child:Text('ゴールドランク', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('10', '提供回数'),
                _buildStatColumn('4.5', '平均満足度'),
                _buildStatColumn('10', '利用回数'),
              ],
            ),
            const SizedBox(height: 16),
            // プログレスバー（ダミー）
            LinearProgressIndicator(
              value: 0.8, // 80%
              backgroundColor: Colors.grey[300],
              color: Colors.orange,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('あと1000exでプラチナランク', style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  /// 実績バッジカード
  Widget _buildBadgesCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child:Text('実績バッジ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Chip(label: const Text('人気講師'), backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade400)),
                Chip(label: const Text('天才プログラミング講師'), backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade400)),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// メニューリスト
  Widget _buildMenuList() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      // Cardの中でListTileを使う場合、余白が自動で入るので Padding を無効化
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias, // 角丸を適用
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.grey), // Withの足あとアイコン風
            title: const Text('足あと'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('24', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.grey),
            title: const Text('お気に入り'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 16),
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.grey),
            title: const Text('お知らせ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}