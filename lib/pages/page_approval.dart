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
    try {
      // 1. requests コレクションの status を 'approved' に更新
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'approved',
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
      backgroundColor: Colors.grey[100],
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
        final String teachSkill = userData['teachSkill'] ?? 'スキル未設定';
        // (Consent.png には「学びたい」は表示されていないが、必要なら追加)
        // final String learnSkill = userData['learnSkill'] ?? 'スキル未設定';


        // 8. 取得したデータを使って「承認カードUI」を構築
        // (page_onboarding_step3 で使ったUIを流用)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                clipBehavior: Clip.antiAlias,
                elevation: 4.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // メイン画像
                    AspectRatio(
                      aspectRatio: 1 / 1, // 正方形
                      child: profileImageUrl != null
                          ? Image.network(profileImageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 80, color: Colors.white)),
                    ),

                    // 下部の情報エリア
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nickname $age歳 $location',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[700]),
                              Flexible(
                                child: Text(
                                  '「$teachSkill」を教えて欲しいです。', // ダミーの依頼文
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // 「詳しく見る」で他人のプロフィールページへ
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) =>  Page_user_profile(userId: widget.fromId),
                                ));
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
              ),

              // 9. 「承認」「スキップ」ボタン
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleButton(
                      icon: Icons.close,
                      text: 'スキップ',
                      color: Colors.grey,
                      iconColor: Colors.white,
                      onPressed: widget.onSkip, // ← スキップロジックを呼ぶ
                    ),
                    _buildCircleButton(
                      icon: Icons.check,
                      text: '承認',
                      color: Colors.cyan,
                      iconColor: Colors.white,
                      onPressed: widget.onApprove, // ← 承認ロジックを呼ぶ
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