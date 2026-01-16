import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'page_create_schedule.dart'; // 予定作成
import 'page_schedule_requests.dart'; // リクエスト承認
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

  // 初期値は「利用」モード (false)
  bool _isProvidingSelected = false;

  @override
  Widget build(BuildContext context) {
    // ログインチェック
    if (_currentUserUid == null) {
      return const Center(child: Text('ログインしていません'));
    }

    // --- メインの予定リスト用ストリーム定義 ---
    // 提供モードなら 'providerId'、利用モードなら 'receiverId' でフィルタリング
    final String filterField = _isProvidingSelected ? 'providerId' : 'receiverId';

    final Stream<QuerySnapshot<Map<String, dynamic>>> scheduleStream =
    _firestore
        .collection('schedules')
        .where(filterField, isEqualTo: _currentUserUid)
        .where('status', isEqualTo: 'approved') // 承認済み(予約確定)のみ表示
        .orderBy('scheduleAt', descending: true) // 日付順
        .snapshots();

    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: const Text(
          '予定',
          style: TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
        elevation: 0,
        // actions: [], // ★AppBar右上のアイコンはすべて削除しました
      ),

      // ★右下の大きな＋ボタン (FloatingActionButton)
      // 「利用」モード (!_isProvidingSelected) の時だけ表示する
      floatingActionButton: !_isProvidingSelected
          ? SizedBox(
        width: 70, // 標準より少し大きく (70x70)
        height: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.cyan, // シアン色
          shape: const CircleBorder(),   // 真円
          onPressed: () {
            // 「予定作成」ページへ遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Page_create_schedule()),
            );
          },
          child: const Icon(Icons.add, size: 40, color: Colors.white), // 白い＋アイコン
        ),
      )
          : null, // 「提供」モード時は非表示

      body: Column(
        children: [
          const SizedBox(height: 24),

          // 1. トグルボタン (提供/利用の切り替え)
          _buildToggleButtons(),

          // 2. ★通知バナー (トグルボタンの下に配置)
          // 「提供」モードの時だけ、未承認リクエストをチェックして表示
          if (_isProvidingSelected)
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('schedules') // リクエストを管理するコレクション
                  .where('providerId', isEqualTo: _currentUserUid) // 自分宛て
                  .where('status', isEqualTo: 'pending') // 未承認のもの
                  .snapshots(),
              builder: (context, snapshot) {
                // データ読み込み中やエラー、または件数が0件の場合は表示しない
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink(); // 何も描画しない
                }

                // 未承認の件数
                final int pendingCount = snapshot.data!.docs.length;

                // バナーUI
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), // 余白
                  child: InkWell(
                    onTap: () {
                      // バナーをタップしたら「リクエスト一覧」へ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Page_schedule_requests()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50], // 薄いオレンジ背景
                        border: Border.all(color: Colors.orange), // オレンジ枠線
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.orange), // 注意アイコン
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '承認待ちの依頼が $pendingCount件 あります',
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.orange), // 矢印アイコン
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // 3. 予定リスト (Expandedで残りの領域を埋める)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: scheduleStream,
              builder: (context, scheduleSnapshot) {
                // 読み込み中
                if (scheduleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // エラー発生時
                if (scheduleSnapshot.hasError) {
                  return Center(
                      child: Text('エラー: ${scheduleSnapshot.error}'));
                }
                // データなし
                if (!scheduleSnapshot.hasData ||
                    scheduleSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('予定はありません'));
                }

                // データあり -> リスト表示
                final scheduleDocs = scheduleSnapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: scheduleDocs.length,
                  itemBuilder: (context, index) {
                    final scheduleData = scheduleDocs[index].data();
                    final String scheduleId = scheduleDocs[index].id;

                    // 参加者リストから「自分以外」のIDを探す
                    final List<dynamic> participants =
                    scheduleData['participants'];
                    final String opponentId = participants.firstWhere(
                          (id) => id != _currentUserUid,
                      orElse: () => '',
                    );

                    // カードウィジェットを返す
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

  /// 「提供」「利用」のトグルボタン (アニメーション付き)
  Widget _buildToggleButtons() {
    const animationDuration = Duration(milliseconds: 300);
    const animationCurve = Curves.easeInOut;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Stack(
        children: [
          // 1. 動く背景(スライダー)
          AnimatedAlign(
            duration: animationDuration,
            curve: animationCurve,
            alignment: !_isProvidingSelected
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(4.0),
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
          // 2. テキストボタン
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isProvidingSelected = false; // 利用モード
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: animationCurve,
                      style: TextStyle(
                        color: !_isProvidingSelected
                            ? Colors.white
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      child: const Text('利用'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isProvidingSelected = true; // 提供モード
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: animationCurve,
                      style: TextStyle(
                        color: _isProvidingSelected
                            ? Colors.white
                            : Colors.grey,
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

// --- 以下、リストアイテム用のウィジェット ---

/// 予定カード本体
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
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    // 相手のユーザー情報を取得
    _userDataFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.opponentId)
        .get();
  }

  // 年齢計算
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) return '?';
    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age.toString();
  }

  // 日時フォーマット
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '日時未定';
    final DateTime dt = timestamp.toDate();
    return '${dt.year}年 ${dt.month}月 ${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {
        // 読み込み中
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: Text('読み込み中...')));
        }
        // データなし
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Card(child: ListTile(title: Text('ユーザーが見つかりません')));
        }

        // データを展開
        final userData = userSnapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名無し';
        final String? profileImageUrl = userData['profileImageUrl'];
        final String location = userData['location'] ?? '未設定';
        final Timestamp? birthdayTimestamp = userData['birthday'];
        final String age = _calculateAge(birthdayTimestamp);

        final String status = widget.scheduleData['status'] ?? '不明';
        final Timestamp? scheduleAt = widget.scheduleData['scheduleAt'];
        final String service =
            widget.scheduleData['serviceName'] ?? 'スキル交換';

        // 評価ボタンの表示制御
        bool showEvaluateButton = false;
        // 「承認済み」かつ「過去の日時」の場合
        if (status == 'approved' &&
            scheduleAt != null &&
            scheduleAt.toDate().isBefore(DateTime.now())) {
          showEvaluateButton = true;

          // 既に評価済みならボタンを隠す
          if (widget.isProviderView) {
            // 提供者の場合
            if (widget.scheduleData.containsKey('isEvaluatedByProvider') &&
                widget.scheduleData['isEvaluatedByProvider'] == true) {
              showEvaluateButton = false;
            }
          } else {
            // 利用者の場合
            if (widget.scheduleData.containsKey('isEvaluatedByReceiver') &&
                widget.scheduleData['isEvaluatedByReceiver'] == true) {
              showEvaluateButton = false;
            }
          }
        }

        // ステータスバッジの色 (approvedならシアン)
        final Color statusColor =
        (status == 'approved') ? Colors.cyan : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上段: ステータスと日時
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      child: Text(
                        status == 'approved' ? '予約確定' : status,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      _formatTimestamp(scheduleAt),
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const Divider(height: 24.0),

                // 下段: 画像と詳細情報
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // プロフィール画像
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                        image: profileImageUrl != null
                            ? DecorationImage(
                          image: NetworkImage(profileImageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: profileImageUrl == null
                          ? const Icon(Icons.person,
                          size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // テキスト情報
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$nickname $location $age歳',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
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
                                Text(
                                    widget.isProviderView
                                        ? '提供サービス'
                                        : 'ご利用サービス',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                Text(service,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 評価ボタン (条件を満たす場合のみ表示)
                if (showEvaluateButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (widget.isProviderView) {
                            // 提供者 -> 利用者を評価
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Page_Evaluation_Provider(
                                        scheduleId: widget.scheduleId,
                                        opponentId: widget.opponentId,
                                      ),
                                ));
                          } else {
                            // 利用者 -> サービスを評価
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Page_Evaluation_Receiver(
                                        scheduleId: widget.scheduleId,
                                        opponentId: widget.opponentId,
                                      ),
                                ));
                          }
                        },
                        child: Text(
                          widget.isProviderView
                              ? '利用者の姿勢を評価する'
                              : 'サービスを評価する',
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