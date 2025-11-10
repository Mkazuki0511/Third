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
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid; // 現在ログインしているユーザーのID
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ← Firestore インスタンスを追加

  /// --- birthday(Timestamp) から年齢を計算するロジック ---
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

  /// --- 自分が既にリクエストした（またはマッチした）相手のIDリストを取得する ---
  Future<List<String>> _getInteractedUserIds() async {
    if (_currentUserUid == null) {
      return []; // ログインしてなければ空
    }

    // 1. 自分が「送信」したリクエスト（いいね！した相手）
    final requestsSnapshot = await _firestore
        .collection('requests')
        .where('fromId', isEqualTo: _currentUserUid)
        .get();

    // 相手のID (toId) だけをリストに抽出
    final List<String> requestedUserIds = requestsSnapshot.docs.map((doc) {
      return doc.data()['toId'] as String;
    }).toList();

    // 2. （将来）マッチ済みの相手などもここに追加

    // 3. 自分のIDもリストに追加（自分自身を「探す」に表示しないため）
    requestedUserIds.add(_currentUserUid!);

    return requestedUserIds;
  }
  // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(), // 検索バーとフィルターボタン

            // ユーザーカードのリスト（スクロール可能）
            Expanded(
              // ↓↓↓↓ 【ここから StreamBuilder に変更】 ↓↓↓↓
              child: FutureBuilder<List<String>>(
                  future: _getInteractedUserIds(), // ← 今作ったメソッドを呼ぶ
                  builder: (context, interactionSnapshot) {

                    // 1. IDリストの読み込み中
                    if (interactionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 2. IDリストの取得に失敗
                    if (interactionSnapshot.hasError) {
                      return Center(child: Text('エラー: ${interactionSnapshot.error}'));
                    }

                    // 3. IDリスト取得成功
                    // (もしリストが空でも、自分のIDは含まれているので 'whereNotIn' はエラーにならない)
                    final List<String> interactedUserIds = interactionSnapshot.data ?? [_currentUserUid!];

                    // 4. IDリストを使って、「ユーザー」のStreamBuilderを構築
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      // 'uid' が「操作済みIDリスト」に【含まれない】ユーザーだけを取得
                      stream: _firestore
                          .collection('users')
                          .where('uid', whereNotIn: interactedUserIds.isEmpty ? ['dummyId'] : interactedUserIds) // 'whereNotIn' を使用
                          .snapshots(),

                      builder: (context, userSnapshot) {
                        // 読み込み中
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // エラー発生
                        if (userSnapshot.hasError) {
                          return Center(child: Text('エラー: ${userSnapshot.error}'));
                        }

                        // データが 0件
                        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('表示できるユーザーがいません'));
                        }

                        // 成功！
                        final usersDocs = userSnapshot.data!.docs;

                        return GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: usersDocs.length,
                          itemBuilder: (context, index) {
                            final userData = usersDocs[index].data();
                            return _buildUserGridCard(
                              context: context,
                              userData: userData,
                            );
                          },
                        );
                      },
                    );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 検索バーとフィルターボタン
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
      onTap: () async {
        // ↓↓↓↓ 【ここが「詳しく見る」のロジック】 ↓↓↓↓
        // 遷移先の page_user_profile に、タップした人の 'uid' を渡す
        await Navigator.push(context, MaterialPageRoute(
          builder: (context) => Page_user_profile(userId: userData['uid']),
        ));
        setState(() {});
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