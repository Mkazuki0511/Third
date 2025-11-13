import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:third/sub/pages/page_profile.edit.dart'; // 「プロフィールを確認・編集」

class Page_profile extends StatelessWidget {
  const Page_profile({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 現在のユーザーを取得
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // ログインしていない/UIDが取得できない場合のUI
    if (currentUser == null) {
      return const Center(child: Text('ログインしていません'));
    }

    // 2. StreamBuilderでFirestoreのデータをリアルタイムで監視
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(), // .snapshots() でリアルタイム更新
      builder: (context, snapshot) {

        // --- 3. UIの状態をハンドリング ---

        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // エラー発生
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        // データが存在しない (Firestoreにドキュメントがない)
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('ユーザーデータが見つかりません'));
        }

        // --- 4. 成功！データを取得 ---
        final userData = snapshot.data!.data()!;

        // 5. データを使ってUIを構築
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(context, userData),
                    const SizedBox(height: 16),
                    // データを渡す
                    _buildRankCard(userData),
                    const SizedBox(height: 16),
                    _buildBadgesCard(userData),
                    const SizedBox(height: 16),
                    _buildMenuList(userData),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ヘッダー（アイコン、統計、編集ボタン）
  // ↓↓↓↓ 【修正】userData を受け取るように変更 ↓↓↓↓
  Widget _buildHeader(BuildContext context, Map<String, dynamic> userData) {
    // Firestoreから nickname と profileImageUrl を取得
    final String nickname = userData['nickname'] ?? '名前なし';
    final String? profileImageUrl = userData['profileImageUrl']; // null の可能性がある
    // Firestoreから tickets と plan を取得
    final int tickets = userData['tickets'] ?? 0; // チケット数
    final String plan = userData['plan'] ?? '無料'; // 将来のプラン用 (今はダミー)
    // (提供サービス数は、Firestoreに 'teachSkill' があるかどうかで判定もできますが、
    //  Account.png に合わせ、今はまだダミーの '2' を使います)

    return Column(
      children: [
        // ↓↓↓↓ 【修正】ニックネームを（仮で）ここに追加 ↓↓↓↓
        Text(
            nickname,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              // profileImageUrlがnullでなければNetworkImageを、nullならnullを渡す
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : null,
              // backgroundImageがnullの場合（画像未設定）は、代わりにアイコンを表示
              child: profileImageUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            // 統計情報（まだダミー）
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(tickets.toString(), '残チケット'), // 本物のデータ
                  _buildStatColumn(plan, 'プラン'), // ダミー
                  _buildStatColumn('1', '提供サービス'), // ダミー
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 「プロフィールを確認・編集」ボタン (ロジックはまだ)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('プロフィールを確認・編集'),

            onPressed: () {
              // 新しく作った「自分のプロフィール確認」ページへ遷移
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const Page_profile_edit(),
              ));
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
  Widget _buildRankCard(Map<String, dynamic> userData) {
    // Firestoreから rank と experiencePoints を取得
    final String rank = userData['rank'] ?? 'Beginner'; // 本物のランク
    final int exp = userData['experiencePoints'] ?? 0 ; // 本物の経験値

    // (ランクアップに必要な経験値のロジック（仮）)
    final int nextRankExp = 1000; // (例: 次は1000必要)
    final double progress = (exp / nextRankExp).clamp(0.0, 1.0);

    return Card(
      color: Colors.yellow[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(rank, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
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
            // プログレスバー
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.orange,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Center(child: Text('あと ${nextRankExp - exp} exでプラチナランク', style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  /// 実績バッジカード (まだダミー)
  Widget _buildBadgesCard(Map<String, dynamic> userData) {
    // TODO: 将来 userData からバッジ情報を取得する
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('実績バッジ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  /// メニューリスト (まだダミー)
  Widget _buildMenuList(Map<String, dynamic> userData) {
    // TODO: 将来 userData から「足あと」の数などを取得する
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.grey), // 足あと
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