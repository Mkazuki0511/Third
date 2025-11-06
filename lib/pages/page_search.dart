import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
import 'page_user_profile.dart'; // ← 「詳しく見る」の遷移先

// データを読み込むため StatefulWidget に変更
class Page_search extends StatefulWidget {
  const Page_search({super.key});

  @override
  State<Page_search> createState() => _Page_searchState();
}

class _Page_searchState extends State<Page_search> {

  // ↓↓↓↓ 【ここからロジック】 ↓↓↓↓
  // 現在ログインしているユーザーのID
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  /// --- birthday(Timestamp) から年齢を計算するロジック ---
  /// (page_profile_edit からコピー)
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) {
      return '?'; // データがなければ '?' を表示
    }
    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age.toString();
  }
  // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(), // 検索バーとフィルターボタン (変更なし)

            // ユーザーカードのリスト（スクロール可能）
            Expanded(
              // ↓↓↓↓ 【ここから StreamBuilder に変更】 ↓↓↓↓
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // --- 1. Stream（データの流れ）を定義 ---
                // 'users' コレクションから
                // 'uid' が 'currentUserUid' と「等しくない」もの（＝自分以外）を取得
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('uid', isNotEqualTo: _currentUserUid)
                    .snapshots(), // リアルタイムで監視

                // --- 2. Stream の状態に応じてUIを構築 ---
                builder: (context, snapshot) {
                  // 読み込み中
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // エラー発生
                  if (snapshot.hasError) {
                    return Center(child: Text('エラー: ${snapshot.error}'));
                  }

                  // データが 0件 の場合
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('表示できるユーザーがいません'));
                  }

                  // --- 3. 成功！データを取得 ---
                  final usersDocs = snapshot.data!.docs;

                  // --- 4. GridView.builder でデータを表示 ---
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 1.0, // 正方形
                    ),
                    itemCount: usersDocs.length, // Firestoreから取得した数
                    itemBuilder: (context, index) {
                      // 1人分のユーザーデータを取得
                      final userData = usersDocs[index].data();

                      // データをカードウィジェットに渡す
                      return _buildUserGridCard(
                        context: context, // ← 遷移用に context を渡す
                        userData: userData, // ← 1人分のデータを渡す
                      );
                    },
                  );
                },
              ),
              // ↑↑↑↑ 【StreamBuilder ここまで】 ↑↑↑↑
            ),
          ],
        ),
      ),
    );
  }

  /// 検索バーとフィルターボタン (変更なし)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '検索条件を設定する',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: フィルター設定
            },
          ),
        ],
      ),
    );
  }

  // ↓↓↓↓ 【ここが「新しい」正しいメソッドです】 ↓↓↓↓
  /// 「With」風の2列グリッド用ユーザーカード
  Widget _buildUserGridCard({
    required BuildContext context,
    required Map<String, dynamic> userData,
  }) {
    // Firestore のデータを取り出す
    final String nickname = userData['nickname'] ?? '名無し';
    final Timestamp? birthdayTimestamp = userData['birthday'];
    final String age = _calculateAge(birthdayTimestamp); // 年齢を計算
    final String location = userData['location'] ?? '未設定';
    final String? profileImageUrl = userData['profileImageUrl'];
    final String teachSkill = userData['teachSkill'] ?? 'スキル未設定';

    // TODO: 'commonPoints' や 'photoCount' もロジックで計算する

    return GestureDetector( // ← カード全体をタップ可能にする
      onTap: () {
        // ↓↓↓↓ 【ここが「詳しく見る」のロジック】 ↓↓↓↓
        // 遷移先の page_user_profile に、タップした人の 'uid' を渡す
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => Page_user_profile(userId: userData['uid']),
        ));
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. メイン画像
            // ↓↓↓↓ 【profileImageUrl で分岐】 ↓↓↓↓
            profileImageUrl != null
                ? Image.network(
              profileImageUrl,
              fit: BoxFit.cover,
              // 画像読み込みエラー時のフォールバック
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50, color: Colors.white));
              },
            )
                : Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50, color: Colors.white)),

            // 2. 画像のグラデーション
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 3. 共通点・写真数タグ (今はまだダミー)
            Positioned(
              top: 8,
              right: 8,
              child: Chip(
                label: Text('共通点 5', style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.orange.withOpacity(0.8),
                padding: EdgeInsets.zero,
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Chip(
                label: Text('📷 6', style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.zero,
              ),
            ),

            // 4. メインのテキスト情報
            // ↓↓↓↓ 【本物のデータを表示】 ↓↓↓↓
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$age歳 $location',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.cyan[200], size: 14), // 「教える」アイコン
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          teachSkill, // 教えるスキル（"ディズニー行きたい" の代わり）
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
// ↑↑↑↑ 【このファイルに含まれる _buildUserGridCard は、この1つだけです】 ↑↑↑↑
}