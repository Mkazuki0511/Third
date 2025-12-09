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
      //backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '予定',
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        //backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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

  /// 「提供」「利用」のトグルボタン (添付画像風のデザイン)
  Widget _buildToggleButtons() {
    // アニメーションの時間を定義
    const animationDuration = Duration(milliseconds: 300);
    // アニメーションの動き方を定義（滑らかに加速・減速）
    const animationCurve = Curves.easeInOut;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 50,
      // グレーの背景レール
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Stack(
        children: [
          // 1. 動く白い背景 (スライダー)
          AnimatedAlign(
            duration: animationDuration,
            curve: animationCurve,
            // 状態に応じて配置場所を左端か右端に変える
            alignment: !_isProvidingSelected ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5, // 幅は全体の半分
              heightFactor: 1.0, // 高さは全体と同じ
              child: Container(
                margin: const EdgeInsets.all(4.0), // レールとの隙間
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. 前面のテキストとタップ領域
          Row(
            children: [
              // 左側：「利用」ボタン領域
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isProvidingSelected = false;
                    });
                  },
                  child: Container(
                    // タップ領域を確保するための透明なコンテナ
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    // テキストの色も滑らかに変える
                    child: AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: animationCurve,
                      style: TextStyle(
                        // 選択されている(false)なら黒、そうでなければグレー
                        color: !_isProvidingSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      child: const Text('利用'),
                    ),
                  ),
                ),
              ),
              // 右側：「提供」ボタン領域
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isProvidingSelected = true;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: animationCurve,
                      style: TextStyle(
                        // 選択されている(true)なら黒、そうでなければグレー
                        color: _isProvidingSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      child: const Text('提供'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // 影の色（薄い黒）
              spreadRadius: 1, // 影の広がり範囲
              blurRadius: 8,   // 影のぼかし具合
              offset: const Offset(0, 0), // ★ここを (0, 0) にすると影が上下左右均等（真ん中）になります
            ),
          ],
        ),

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
                        borderRadius: BorderRadius.circular(0.0),
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
                    Container(
                      width: 100,  // 横幅
                      height: 100, // 高さ（ここを大きくすると縦長になります）
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // 画像がない時の背景色
                        borderRadius: BorderRadius.circular(8.0), // 角を少し丸くする
                        image: profileImageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(profileImageUrl),
                          fit: BoxFit.cover, // 枠に合わせて画像を切り取る（歪まない）
                        )
                            : null,
                      ),
                      // 画像がない場合は人型アイコンを表示
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
                            '$nickname $location $age歳', // ← 本物のデータに
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                                    style: TextStyle(fontSize: 10, color: Colors.grey[700])
                                ),
                                const SizedBox(height: 4),

                                Text(
                                    service, // ← 本物のサービス名に
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
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