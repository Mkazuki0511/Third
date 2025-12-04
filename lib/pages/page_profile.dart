import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:third/sub/pages/page_favorites.dart';
import 'package:third/sub/pages/page_profile.edit.dart'; // 「プロフィールを確認・編集」
import 'package:third/sub/pages/page_footprints.dart'; // 「足あとページ」
import 'package:third/sub/pages/page_favorites.dart'; // 「いいね履歴」

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

        // 3. UIの状態をハンドリング

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

        // 4. 成功！データを取得
        final userData = snapshot.data!.data()!;

        // 5. 平均満足度をここで計算
        final double totalRating = (userData['totalRating'] ?? 0).toDouble();
        final int ratingCount = userData['ratingCount'] ?? 0;

        // 0除算を避けて、「平均満足度」を計算
        final double averageRating = (ratingCount == 0)
            ? 0.0 // まだ誰も評価していない
            : totalRating / ratingCount;

        // 6. データを使ってUIを構築
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
                    _buildRankCard(userData, averageRating: averageRating),
                    const SizedBox(height: 16),

                    _buildBadgesCard(userData, averageRating: averageRating),
                    const SizedBox(height: 16),

                    _buildMenuList(context, userData),
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
    final String plan = userData['plan'] ?? '無料';

    final String teachSkill = userData['teachSkill'] ?? '';
    final String service = (teachSkill.isNotEmpty) ? '1' : '0';

    final int serviceCount = userData['servicesProvidedCount'] ?? 0;

    return Column(
      children: [
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
                  _buildStatColumn(service, '提供サービス'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 「プロフィールを確認・編集」ボタン (ロジックはまだ)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('プロフィールを確認・編集'),

            onPressed: () {
              // 新しく作った「自分のプロフィール確認」ページへ遷移
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const Page_profile_edit(),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(), // RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
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

  /// ランク情報を定義するヘルパークラス
  Map<String, dynamic> _getRankInfo(int exp) {
    // 画像に基づいたランク定義
    if (exp >= 3500) {
      return {
        'name': 'Legend',
        'color': const Color(0xFF81D4FA), // 水色
        'ribbon': const Color(0xFFFF4081), // ピンク
        'minExp': 3500,
        'nextExp': null, // 最上位
      };
    } else if (exp >= 1800) {
      return {
        'name': 'Mentor',
        'color': const Color(0xFFFFC107), // ゴールド/黄色
        'ribbon': const Color(0xFFFF5722), // 赤/オレンジ
        'minExp': 1800,
        'nextExp': 3500,
      };
    } else if (exp >= 900) {
      return {
        'name': 'Partner',
        'color': const Color(0xFFCFD8DC), // シルバー/グレー
        'ribbon': Colors.cyan,             // シアン (アプリテーマ色)
        'minExp': 900,
        'nextExp': 1800,
      };
    } else if (exp >= 300) {
      return {
        'name': 'Learner',
        'color': const Color(0xFFD87608), // ブロンズ/茶色
        'ribbon': const Color(0xFF5C6BC0), // インディゴ/紫
        'minExp': 300,
        'nextExp': 900,
      };
    } else {
      return {
        'name': 'Beginner',
        'color': const Color(0xFFE53935), // 赤
        'ribbon': const Color(0xFFFFB300), // 黄色
        'minExp': 0,
        'nextExp': 300,
      };
    }
  }

  /// ランクカード
  Widget _buildRankCard(Map<String, dynamic> userData, {required double averageRating}) {
    // Firestoreから経験値を取得 (なければ0)
    final int exp = userData['experiencePoints'] ?? 0;
    final int serviceCount = userData['servicesProvidedCount'] ?? 0;
    final int serviceUsedCount = userData['servicesUsedCount'] ?? 0;

    // 現在のランク情報を取得
    final rankInfo = _getRankInfo(exp);
    final String rankName = rankInfo['name'];
    final Color cardColor = rankInfo['color'];
    final Color ribbonColor = rankInfo['ribbon'];
    final int minExp = rankInfo['minExp'];
    final int? nextExp = rankInfo['nextExp'];

    // プログレスバーの計算 (0.0 〜 1.0)
    double progress = 0.0;
    String nextLevelText = 'MAX RANK';

    if (nextExp != null) {
      final int range = nextExp - minExp; // 次のランクまでの必要経験値量
      final int currentInLevel = exp - minExp; // 現在のランク内での獲得量
      progress = (currentInLevel / range).clamp(0.0, 1.0);
      nextLevelText = 'あと ${nextExp - exp} EXPでランクアップ';
    } else {
      progress = 1.0; // 最高ランク
    }

    return Card(
      color: cardColor, // ランクによって色を変える
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Stack(
        clipBehavior: Clip.none, // リボンを少しはみ出させる場合などに有効
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ランク名 (リボンのような装飾)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    decoration: BoxDecoration(
                      color: ribbonColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      rankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 統計データ (白文字にして視認性を確保)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRankStat('提供回数', '$serviceCount回'),
                    _buildRankStat('平均満足度', averageRating.toStringAsFixed(1)),
                    _buildRankStat('利用回数', '$serviceUsedCount回'),
                  ],
                ),

                const SizedBox(height: 24),

                // プログレスバー
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextLevelText,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ランクカード内の統計用ウィジェット (文字色を白に固定)
  Widget _buildRankStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              color: Colors.white70
          ),
        ),
      ],
    );
  }

  /// 実績バッジカード (まだダミー)
  Widget _buildBadgesCard(Map<String, dynamic> userData, {required double averageRating}) {

    // バッジ獲得のロジック
    final bool hasPopularBadge = (averageRating >= 4.0);

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
              runSpacing: 4.0,
              children: [
                // 「人気講師」バッジ
                _buildBadgeItem(
                  label: '人気講師',
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  isUnlocked: hasPopularBadge, // 4.0以上で true になる
                ),
                // TODO: 他のバッジもここに追加
                // 例：
                // _buildBadgeItem(
                //   label: 'ベテラン',
                //   icon: Icons.military_tech,
                //   color: Colors.blueGrey,
                //   isUnlocked: (userData['servicesProvidedCount'] ?? 0) >= 10,
                // ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// バッジ1個分の表示ウィジェット（共通化）
  /// (page_profile.dart のクラスの末尾などに追加)
  Widget _buildBadgeItem({
    required String label,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
  }) {
    // 獲得していないバッジはグレーアウト
    final displayColor = isUnlocked ? color : Colors.grey[350];
    final displayTextColor = isUnlocked ? Colors.black87 : Colors.grey[500];
    final labelText = isUnlocked ? label : '$label (未獲得)';

    // Chip を使うとデザインが簡単です
    return Chip(
      avatar: Icon(icon, color: displayColor, size: 18),
      label: Text(
        labelText,
        style: TextStyle(color: displayTextColor, fontSize: 13),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: displayColor ?? Colors.grey[350]!),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }

  /// メニューリスト (まだダミー)
  Widget _buildMenuList(BuildContext context, Map<String, dynamic> userData) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final Timestamp? lastCheckedTs = userData['lastCheckedFootprints'];
    final DateTime lastChecked = lastCheckedTs?.toDate() ?? DateTime(2000);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [

      // --- 1. 足あと (StreamBuilderで実装) ---
      StreamBuilder<QuerySnapshot>(

      // ★「自分」の 'footprints' サブコレクションを監視
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid) // ★自分のUID
          .collection('footprints')
          .snapshots(), // リアルタイムで件数を監視

        builder: (context, snapshot) {

          // データ取得中 or エラーの場合は簡易表示
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              leading: Icon(Icons.visibility, color: Colors.grey),
              title: Text('足あと'),
              trailing: Text('...', style: TextStyle(color: Colors.grey)),
            );
          }

          // エラーもしくはデータが無い場合
          if (!snapshot.hasData) {
            return const ListTile(
              leading: Icon(Icons.visibility, color: Colors.grey),
              title: Text('足あと'),
              trailing: Text('0', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final docs = snapshot.data!.docs;
          final int footprintCount = snapshot.data!.docs.length;

          int unreadCount = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp? ts = data['timestamp'];

            // 足あとの日時が、最終確認日時より「後(未来)」なら未読とみなす
            if (ts != null && ts.toDate().isAfter(lastChecked)) {
              unreadCount++;
            }
          }

          return ListTile(
            leading: const Icon(Icons.visibility, color: Colors.grey),
            title: const Text('足あと'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(), // 未読件数を表示
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )

                else
                  const Text('0', style: TextStyle(color: Colors.grey, fontSize: 16)),

                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const PageFootprints(),
              ));
            },
          );
        },
      ),
          const Divider(height: 1, indent: 16),

          // --- 2. お気に入り ---
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.grey),
            title: const Text('お気に入り'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                   builder: (context) => const PageFavorites(),
              ));
            },
          ),
          const Divider(height: 1, indent: 16),

          // --- 3. お知らせ ---
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