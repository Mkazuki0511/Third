import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
// import 'page_create_schedule.dart'; // ← 次に作成する「予定作成」ページ

class Page_schedule extends StatefulWidget {
  const Page_schedule({super.key});

  @override
  State<Page_schedule> createState() => _Page_scheduleState();
}

class _Page_scheduleState extends State<Page_schedule> {
  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザーID
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // 「提供」がtrue、「利用」がfalse
  bool _isProvidingSelected = true;

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Center(child: Text('ログインしていません'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ↓↓↓↓ 【AppBarを追加】 ↓↓↓↓
      appBar: AppBar(
        title: const Text('予定'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
        actions: [
          // 「予定作成」ボタン
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: 次のステップで「予定作成」ページへ遷移する
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => Page_create_schedule(),
              // ));
              print("予定作成ページへ（未実装）");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          _buildToggleButtons(), // 「提供」「利用」のトグルボタン

          // ↓↓↓↓ 【ここからがロジック本体】 ↓↓↓↓
          Expanded(
            // 1. StreamBuilderで「予定」を監視
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('schedules') // ← 新しいコレクション
                  .where('participants', arrayContains: _currentUserUid) // 自分（のID）が参加している
              // TODO: .where('status', isEqualTo: 'upcoming') // （将来）「予約確定」のものだけ
                  .orderBy('scheduleAt', descending: true) // 予定の日時が新しい順
                  .snapshots(),

              builder: (context, scheduleSnapshot) {
                // 読み込み中
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // エラー
                if (scheduleSnapshot.hasError) {
                  return Center(child: Text('エラー: ${scheduleSnapshot.error}'));
                }
                // 予定 0件
                if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('予定はありません'));
                }

                // 2. 成功！予定のリストを取得
                final scheduleDocs = scheduleSnapshot.data!.docs;

                // 3. ListView で予定カードを一覧表示
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: scheduleDocs.length,
                  itemBuilder: (context, index) {
                    final scheduleData = scheduleDocs[index].data();
                    final List<dynamic> participants = scheduleData['participants'];

                    // 4. 「相手」のIDを特定する
                    final String opponentId = participants.firstWhere(
                          (id) => id != _currentUserUid, // 自分じゃないほうが相手
                      orElse: () => '',
                    );

                    // 5. 「相手のID」と「予定データ」を使って、カードを表示
                    return _ScheduleCardItem(
                      opponentId: opponentId,
                      scheduleData: scheduleData,
                    );
                  },
                );
              },
            ),
          ),
          // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑
        ],
      ),
    );
  }

  /// 「提供」「利用」のトグルボタン (変更なし)
  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildToggleButton(
            text: '提供',
            isSelected: _isProvidingSelected,
            onPressed: () {
              setState(() {
                _isProvidingSelected = true;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildToggleButton(
            text: '利用',
            isSelected: !_isProvidingSelected,
            onPressed: () {
              setState(() {
                _isProvidingSelected = false;
              });
            },
          ),
        ],
      ),
    );
  }

  /// トグルボタンの共通ウィジェット (変更なし)
  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.cyan : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.cyan,
          side: BorderSide(color: isSelected ? Colors.cyan : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}


// --- ↓↓↓↓ 【ここからが新設ウィジェット】 ↓↓↓↓ ---
/// --- 予定カード本体（`opponentId` からユーザー情報を取得する） ---
class _ScheduleCardItem extends StatefulWidget {
  final String opponentId;
  final Map<String, dynamic> scheduleData;

  const _ScheduleCardItem({
    required this.opponentId,
    required this.scheduleData,
  });

  @override
  State<_ScheduleCardItem> createState() => _ScheduleCardItemState();
}

class _ScheduleCardItemState extends State<_ScheduleCardItem> {
  // 相手のユーザーデータを `Future` で1回だけ取得
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // 6. `opponentId` を使って、'users' コレクションから相手のデータを取得
    _userDataFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.opponentId)
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

  /// --- scheduleAt(Timestamp) を「yyyy年MM月dd日 HH:mm」に変換 ---
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '日時未定';
    final DateTime dt = timestamp.toDate();
    // (intl パッケージを使うとより柔軟ですが、ここではシンプルに)
    return '${dt.year}年 ${dt.month}月 ${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {
    // 7. `FutureBuilder` で相手のユーザーデータの読み込みを待つ
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

        // 8. 成功！相手のデータを取得
        final userData = userSnapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名無し';
        final String? profileImageUrl = userData['profileImageUrl'];
        final String location = userData['location'] ?? '未設定';
        final Timestamp? birthdayTimestamp = userData['birthday'];
        final String age = _calculateAge(birthdayTimestamp);

        // 9. 予定データを取得
        final String status = widget.scheduleData['status'] ?? '不明';
        final Timestamp? scheduleAt = widget.scheduleData['scheduleAt'];
        final String service = widget.scheduleData['serviceName'] ?? 'スキル交換'; // (例: "プログラミング講座")

        // 10. UIを構築 (Schedule_2.png のデザイン)
        final Color statusColor = (status == '予約確定') ? Colors.cyan : Colors.grey;

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上段：ステータスと日付
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      _formatTimestamp(scheduleAt), // ← 本物の日時に
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const Divider(height: 24.0),

                // 下段：画像と詳細
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左側の画像
                    CircleAvatar(
                      radius: 40, // (80x80 のコンテナの代わりに)
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // 右側の詳細
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nickname $location ($age歳)', // ← 本物のデータに
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ご利用サービス', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text(
                                    service, // ← 本物のサービス名に
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}