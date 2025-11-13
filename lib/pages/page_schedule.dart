import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'page_create_schedule.dart'; // ← 「予定作成」ページ
import 'page_schedule_requests.dart';
import 'page_evaluation_receiver.dart'; // 利用者が評価
import 'page_evaluation_provider.dart'; // 提供者が評価

class Page_schedule extends StatefulWidget {
  const Page_schedule({super.key});

  @override
  State<Page_schedule> createState() => _Page_scheduleState();
}

class _Page_scheduleState extends State<Page_schedule> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // ↓↓↓↓ 【修正①】初期値を 'true' -> 'false' に変更 ↓↓↓↓
  // 「提供」がtrue、「利用」がfalse
  bool _isProvidingSelected = false; // ← デフォルトを「利用」に

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Center(child: Text('ログインしていません'));
    }

    // ↓↓↓↓ 【修正②】このロジックは変更なし（'true' が「提供」のまま） ↓↓↓↓
    // _isProvidingSelected が false（利用）なら、自分が receiverId
    // _isProvidingSelected が true（提供）なら、自分が providerId
    final String filterField = _isProvidingSelected ? 'providerId' : 'receiverId';

    // Stream を定義（15:20の回答のバグ修正を適用済み）
    final Stream<QuerySnapshot<Map<String, dynamic>>> scheduleStream =
    _firestore
        .collection('schedules')
        .where(filterField, isEqualTo: _currentUserUid)
        .where('status', isEqualTo: 'approved') // 15:28の計画（承認済みのみ）
        .orderBy('scheduleAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('予定'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
        actions: [
          // ↓↓↓↓ 【修正③】AppBarのアイコンロジック（15:28の計画） ↓↓↓↓
          // _isProvidingSelected が true（提供）なら 🔔
          // _isProvidingSelected が false（利用）なら ＋
          if (_isProvidingSelected)
            IconButton(
              icon: const Icon(Icons.notifications_none), // 鈴 🔔
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const Page_schedule_requests(),
                ));
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.add_circle_outline), // ＋
              onPressed: () {
                // 「予定作成」ページへ遷移
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const Page_create_schedule(),
                ));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          _buildToggleButtons(), // 「提供」「利用」のトグルボタン

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: scheduleStream, // ← 修正済みの stream を渡す
              builder: (context, scheduleSnapshot) {
                // ... (読み込み中、エラー、0件のUIは変更なし) ...
                if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (scheduleSnapshot.hasError) {
                  // (インデックス作成のURLが表示されるはずです)
                  return Center(child: Text('エラー: ${scheduleSnapshot.error}'));
                }
                if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('予定はありません'));
                }

                // 成功！
                final scheduleDocs = scheduleSnapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: scheduleDocs.length,
                  itemBuilder: (context, index) {
                    final scheduleData = scheduleDocs[index].data();
                    final String scheduleId = scheduleDocs[index].id;
                    final List<dynamic> participants = scheduleData['participants'];
                    final String opponentId = participants.firstWhere(
                          (id) => id != _currentUserUid,
                      orElse: () => '',
                    );

                    return _ScheduleCardItem(
                      opponentId: opponentId,
                      scheduleData: scheduleData,
                      scheduleId: scheduleId,
                      isProviderView: _isProvidingSelected,
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

  /// 「提供」「利用」のトグルボタン
  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // ↓↓↓↓ 【修正④】「利用」ボタンを左（1番目）に配置 ↓↓↓↓
          _buildToggleButton(
            text: '利用',
            isSelected: !_isProvidingSelected, // 'false' の時に選択状態
            onPressed: () {
              setState(() {
                _isProvidingSelected = false; // 'false' をセット
              });
            },
          ),
          const SizedBox(width: 12),
          // ↓↓↓↓ 【修正⑤】「提供」ボタンを右（2番目）に配置 ↓↓↓↓
          _buildToggleButton(
            text: '提供',
            isSelected: _isProvidingSelected, // 'true' の時に選択状態
            onPressed: () {
              setState(() {
                _isProvidingSelected = true; // 'true' をセット
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
  final bool isProviderView;
  final String scheduleId;

  const _ScheduleCardItem({
    required this.opponentId,
    required this.scheduleData,
    required this.isProviderView,
    required this.scheduleId,
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

        // 10. 「評価する」ボタンを表示するかどうかを判定
        bool showEvaluateButton = false;
        if (status == 'approved' &&
            scheduleAt != null &&
            scheduleAt.toDate().isBefore(DateTime.now())) {
          showEvaluateButton = true;

          if (widget.isProviderView) {
            // 提供タブの場合： "isEvaluatedByProvider" をチェック
            if (widget.scheduleData.containsKey('isEvaluatedByProvider') &&
                widget.scheduleData['isEvaluatedByProvider'] == true) {
              showEvaluateButton = false;
            }
          } else {
            // 利用タブの場合： "isEvaluatedByReceiver" をチェック
            if (widget.scheduleData.containsKey('isEvaluatedByReceiver') &&
                widget.scheduleData['isEvaluatedByReceiver'] == true) {
              showEvaluateButton = false;
            }
          }
        }

        // 11. UIを構築 (Schedule_2.png のデザイン)
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
                                Text(widget.isProviderView
                                    ? '提供サービス'
                                    : 'ご利用サービス',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700])
                                ),
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

                // 12. 「評価する」ボタンを条件付きで表示
                if (showEvaluateButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // 評価ボタンの色
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // isProviderView の状態に応じて、遷移先を切り替える
                          if (widget.isProviderView) {
                            // 「提供」タブなので、"利用者の姿勢"を評価するページへ
                            Navigator.push(context, MaterialPageRoute(
                            builder: (context) => Page_Evaluation_Provider(
                            scheduleId: widget.scheduleId,
                            opponentId: widget.opponentId,
                            ),
                            ));
                          } else {
                            // 「利用」タブなので、"サービス"を評価するページへ
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => Page_Evaluation_Receiver(
                              scheduleId: widget.scheduleId, 
                              opponentId: widget.opponentId,
                                ),
                            ));
                          }
                        },

                          // ↓↓↓↓ 【テキストを動的に変更】 ↓↓↓↓
                          child: Text(
                          // 親から渡された `isProviderView` でテキストを切り替える
                          widget.isProviderView
                            ? '利用者の姿勢を評価する' // True (提供タブ)
                            : 'サービスを評価する', // False (利用タブ)
                      ),
                    ),
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