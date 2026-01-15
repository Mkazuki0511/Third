import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
import 'page_user_profile.dart'; // ← 「詳しく見る」の遷移先

// 状態（読み込みなど）を管理するため StatefulWidget に変更
class Page_approval extends StatefulWidget {
  const Page_approval({super.key});

  @override
  State<Page_approval> createState() => _Page_approvalState();
}

class _Page_approvalState extends State<Page_approval> {
  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザーID
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  /// --- 「承認」ロジック ---
  Future<void> _approveRequest(String requestId) async {
    // 承認を実行する「自分」のIDを取得
    final String? myId = _auth.currentUser?.uid;
    // リクエストを送ってきた「相手」のIDを取得
    final String fromId = (await _firestore.collection('requests').doc(requestId).get()).data()!['fromId'];

    if (myId == null) return; // ログインしていなければ中断

    try {
      // 1. requests コレクションの status を 'approved' に更新
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'approved',

        // トークタブでの検索を簡単にするため、参加者リストを追加
        'participants': [myId, fromId],

      });

      // TODO: 【フェーズ5.3】
      // 2. 自分の 'matches' サブコレクションに相手のIDを追加
      // 3. 相手の 'matches' サブコレクションに自分のIDを追加

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リクエストを承認しました！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('承認処理に失敗しました: $e')),
        );
      }
    }
  }

  /// --- 「スキップ」ロジック ---
  Future<void> _skipRequest(String requestId) async {
    try {
      // requests コレクションの status を 'skipped' に更新
      // (または .delete() で削除してもOK)
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'skipped',
      });
    } catch (e) {
      // エラー処理
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Center(child: Text('ログインしていません'));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildTitleChip(), // 「相手からのリクエスト」
            const SizedBox(height: 16),

            // ↓↓↓↓ 【ここからがロジック本体】 ↓↓↓↓
            Expanded(
              // 1. 「自分宛」かつ「承認待ち」のリクエストを監視
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('requests')
                    .where('toId', isEqualTo: _currentUserUid)
                    .where('status', isEqualTo: 'pending')
                    .orderBy('createdAt', descending: true) // 新しいリクエストから表示
                    .snapshots(),

                builder: (context, requestSnapshot) {
                  // 読み込み中
                  if (requestSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // エラー
                  if (requestSnapshot.hasError) {
                    return Center(child: Text('エラー: ${requestSnapshot.error}'));
                  }
                  // リクエスト 0件
                  if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('新しいリクエストはありません'));
                  }

                  // 2. 成功！リクエストのリストを取得
                  final requestDocs = requestSnapshot.data!.docs;

                  // 3. ListView でリクエストカードを一覧表示
                  // (Tinder風スワイプは、まずこれが動いてから、
                  //  flutter_card_swiper パッケージで置き換えます)
                  return ListView.builder(
                    itemCount: requestDocs.length,
                    itemBuilder: (context, index) {
                      final requestData = requestDocs[index].data();
                      final String requestId = requestDocs[index].id; // ドキュメントID (承認/スキップで使う)
                      final String fromId = requestData['fromId']; // 送信者のID

                      // 4. リクエストカードを表示
                      return _RequestCard(
                        fromId: fromId,
                        requestId: requestId,
                        onApprove: () => _approveRequest(requestId),
                        onSkip: () => _skipRequest(requestId),
                      );
                    },
                  );
                },
              ),
            ),
            // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑
          ],
        ),
      ),
    );
  }

  /// 「相手からのリクエスト」のタイトルチップ (変更なし)
  Widget _buildTitleChip() {
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
}



// --- ↓↓↓↓ 【ここからが新設ウィジェット】 ↓↓↓↓ ---
/// --- リクエストカード本体（`fromId` からユーザー情報を取得する） ---
class _RequestCard extends StatefulWidget {
  final String fromId;
  final String requestId;
  final VoidCallback onApprove;
  final VoidCallback onSkip;

  const _RequestCard({
    required this.fromId,
    required this.requestId,
    required this.onApprove,
    required this.onSkip,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  // `fromId` を元に取得した「送信者」のユーザーデータ
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // 5. `fromId` を使って、'users' コレクションから送信者のデータを取得
    _userDataFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fromId)
        .get();
  }

  /// --- birthday(Timestamp) から年齢を計算するロジック ---
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) return '?';
    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age.toString();
  }

  String _getRankImagePath(int exp) {
    if (exp >= 3500) {
      return 'assets/images/Lank_Legend.png';
    } else if (exp >= 1800) {
      return 'assets/images/Lank_Mentor.png';
    } else if (exp >= 900) {
      return 'assets/images/Lank_Partner.png';
    } else if (exp >= 300) {
      return 'assets/images/Lank_Learner.png';
    } else {
      return 'assets/images/Lank_Beginner.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 6. `FutureBuilder` でユーザーデータの読み込みを待つ
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {

        // ユーザーデータ読み込み中
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // ユーザーデータエラー
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Card(child: ListTile(title: Text('ユーザーが見つかりません')));
        }

        // 7. 成功！送信者のデータを取得
        final userData = userSnapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名無し';
        final String? profileImageUrl = userData['profileImageUrl'];
        final String location = userData['location'] ?? '未設定';
        final Timestamp? birthdayTimestamp = userData['birthday'];
        final String age = _calculateAge(birthdayTimestamp);
        final String selfIntroduction = userData['selfIntroduction'] ?? '自己紹介はありません。';
        final int experiencePoints = userData['experiencePoints'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // 1. プロフィールカード本体 (デザインをプロフィールページに合わせる)
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0), // プロフィールページと同じ丸み
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05), // プロフィールページと同じ薄い影
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 画像 (正方形)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
                      child: AspectRatio(
                        aspectRatio: 1 / 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                        child: profileImageUrl != null
                            ? Image.network(profileImageUrl, fit: BoxFit.cover)
                            : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 80, color: Colors.white),
                        )),
                      ),
                    ),

                    // 情報エリア
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 名前・年齢・地域・ランク
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nickname,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$age歳  $location',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              // ランクアイコン
                              Image.asset(
                                _getRankImagePath(experiencePoints),
                                height: 30, // 少し大きめに
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // ★ 自己紹介 (最大3行で省略)
                          Text(
                            selfIntroduction,
                            maxLines: 3, // 3行まで表示
                            overflow: TextOverflow.ellipsis, // 末尾を ... にする
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5, // 行間を少し開ける
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 「詳しく見る」ボタン
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => Page_user_profile(userId: widget.fromId),
                                ));
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyan, // テキスト色
                                side: const BorderSide(color: Colors.cyan), // 枠線色
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('詳しく見る', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 「承認」「スキップ」ボタン (カードの外、下部に配置)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleButton(
                      icon: Icons.close,
                      text: 'スキップ',
                      color: Colors.grey, // 背景白
                      iconColor: Colors.white, // アイコンと文字をグレーに
                      onPressed: widget.onSkip,
                    ),
                    _buildCircleButton(
                      icon: Icons.check,
                      text: '承認',
                      color: Colors.cyan, // メインカラー
                      iconColor: Colors.white,
                      onPressed: widget.onApprove,
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /// 円形のアクションボタンの共通ウィジェット (onPressed を追加)
  Widget _buildCircleButton({
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed, // ← タップイベント
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ↓↓↓↓ InkWell でタップ可能にする ↓↓↓↓
        InkWell(
          onTap: onPressed, // ← 渡されたロジックを接続
          borderRadius: BorderRadius.circular(35),
          child: Container(
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
        ),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}