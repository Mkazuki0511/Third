import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'page_user_profile.dart'; // 「詳しく見る」用

// このページは page_approval.dart とほぼ同じ構成です
class Page_schedule_requests extends StatefulWidget {
  const Page_schedule_requests({super.key});

  @override
  State<Page_schedule_requests> createState() => _Page_schedule_requestsState();
}

class _Page_schedule_requestsState extends State<Page_schedule_requests> {
  // Firebaseのインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーID
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  /// --- 「承認」ロジック ---
  Future<void> _approveSchedule(String scheduleId) async {
    final String? myId = _auth.currentUser?.uid;
    final String receiverId = (await _firestore.collection('schedules').doc(scheduleId).get()).data()!['receiverId'];

    if (myId == null) return;

    try {
      // トランザクション -> シンプルな update に戻す
      // (servicesUsedCount の +1 を削除したため)
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': 'approved',
      });

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

  /// --- 「拒否」ロジック ---
  Future<void> _denySchedule(String scheduleId) async {
    try {
      // status を 'denied'（拒否）に更新
      await _firestore.collection('schedules').doc(scheduleId).update({
        'status': 'denied',
      });
    } catch (e) {
      // エラー処理
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Scaffold(body: Center(child: Text('ログインしていません')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('相手からの予定申請'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: Column(
        children: [
          Expanded(
            // 1. 「自分宛(providerId)」かつ「申請中(pending)」の予定を監視
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('schedules')
                  .where('providerId', isEqualTo: _currentUserUid) // 自分（提供者）宛
                  .where('status', isEqualTo: 'pending') // 申請中
                  .orderBy('createdAt', descending: true) // 新しい申請から表示
                  .snapshots(),

              builder: (context, requestSnapshot) {
                // 読み込み中
                if (requestSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // エラー
                if (requestSnapshot.hasError) {
                  // (注：このクエリも「インデックス」が必要です)
                  return Center(child: Text('エラー: ${requestSnapshot.error}'));
                }
                // リクエスト 0件
                if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('新しい予定の申請はありません'));
                }

                // 2. 成功！申請のリストを取得
                final requestDocs = requestSnapshot.data!.docs;

                // 3. ListView で申請カードを一覧表示
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: requestDocs.length,
                  itemBuilder: (context, index) {
                    final scheduleData = requestDocs[index].data();
                    final String scheduleId = requestDocs[index].id; // ドキュメントID
                    final String requesterId = scheduleData['receiverId']; // 申請者（利用者）のID

                    // 4. 申請カードを表示
                    return _ScheduleRequestCard(
                      requesterId: requesterId,
                      scheduleData: scheduleData,
                      onApprove: () => _approveSchedule(scheduleId),
                      onDeny: () => _denySchedule(scheduleId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



// --- ↓↓↓↓ 【ここからが新設ウィジェット】 ↓↓↓↓ ---
/// --- 申請カード本体（`requesterId` からユーザー情報を取得する） ---
class _ScheduleRequestCard extends StatefulWidget {
  final String requesterId;
  final Map<String, dynamic> scheduleData;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const _ScheduleRequestCard({
    required this.requesterId,
    required this.scheduleData,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  State<_ScheduleRequestCard> createState() => _ScheduleRequestCardState();
}

class _ScheduleRequestCardState extends State<_ScheduleRequestCard> {
  // `requesterId` を元に取得した「申請者」のユーザーデータ
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // 5. `requesterId` を使って、'users' コレクションから申請者のデータを取得
    _userDataFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.requesterId)
        .get();
  }

  /// --- scheduleAt(Timestamp) を「yyyy年MM月dd日 HH:mm」に変換 ---
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '日時未定';
    final DateTime dt = timestamp.toDate();
    return '${dt.year}年 ${dt.month}月 ${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 6. `FutureBuilder` でユーザーデータの読み込みを待つ
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {

        // ユーザーデータ読み込み中
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: Text('読み込み中...')));
        }
        // ユーザーデータエラー
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Card(child: ListTile(title: Text('ユーザーが見つかりません')));
        }

        // 7. 成功！申請者のデータを取得
        final userData = userSnapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名無し';
        final String? profileImageUrl = userData['profileImageUrl'];

        // 8. 予定データを取得
        final String serviceName = widget.scheduleData['serviceName'] ?? 'スキル交換';
        final Timestamp? scheduleAt = widget.scheduleData['scheduleAt'];

        // 9. 取得したデータを使って「申請カードUI」を構築
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 申請者情報
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  title: Text('$nickname さんからの申請', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('「$serviceName」'),
                ),
                const Divider(height: 16),

                // 申請日時
                Text(
                  _formatTimestamp(scheduleAt),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // アクションボタン
                Row(
                  children: [
                    // 拒否ボタン
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onDeny, // 拒否ロジック
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('拒否する'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 承認ボタン
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onApprove, // 承認ロジック
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('承認する'),
                      ),
                    ),
                  ],
                ),
                // 「詳しく見る」ボタン
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) =>  Page_user_profile(userId: widget.requesterId),
                      ));
                    },
                    child: const Text('相手のプロフィールを見る'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}