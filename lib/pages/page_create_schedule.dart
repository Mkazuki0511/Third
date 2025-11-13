import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:third/models/match_model.dart'; // ← 【重要】次のステップで作成するモデル

class Page_create_schedule extends StatefulWidget {
  const Page_create_schedule({super.key});

  @override
  State<Page_create_schedule> createState() => _Page_create_scheduleState();
}

class _Page_create_scheduleState extends State<Page_create_schedule> {
  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  // フォームの入力値を管理
  String? _selectedOpponentId; // 選択された「相手のID」
  //MatchWithUser? _selectedMatch; // ← 選択された「マッチ相手」
  DateTime? _selectedDate;      // 「日付」
  TimeOfDay? _selectedTime;    // 「時間」
  final TextEditingController _serviceController = TextEditingController();

  bool _isLoading = false;

  // ↓↓↓↓ 【重要】FutureBuilder が2回実行されるのを防ぐため ↓↓↓↓
  late Future<List<MatchWithUser>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    // initState で一度だけ「マッチ相手のリスト」を取得する
    _matchesFuture = _getMatches();
  }

  @override
  void dispose() {
    _serviceController.dispose();
    super.dispose();
  }

  /// --- 1. 「マッチした相手」のリストを取得するロジック ---
  Future<List<MatchWithUser>> _getMatches() async {
    List<MatchWithUser> matches = [];

    // 'requests' コレクションから 'status: approved' かつ 自分が参加しているものを検索
    final snapshot = await _firestore
        .collection('requests')
        .where('status', isEqualTo: 'approved')
        .where('participants', arrayContains: _currentUserUid)
        .get();

    // 取得した各マッチについて、相手のユーザー情報を取得
    for (var doc in snapshot.docs) {
      final matchData = doc.data();
      final List<dynamic> participants = matchData['participants'];

      // 相手のIDを特定
      final String opponentId = participants.firstWhere(
            (id) => id != _currentUserUid,
        orElse: () => '',
      );

      if (opponentId.isNotEmpty) {
        // 相手の 'users' ドキュメントを取得
        final userDoc = await _firestore.collection('users').doc(opponentId).get();
        if (userDoc.exists) {
          // MatchWithUser オブジェクトを作成してリストに追加
          matches.add(MatchWithUser(
            requestId: doc.id,
            opponentId: opponentId,
            opponentNickname: userDoc.data()!['nickname'] ?? '名無し',
            opponentImageUrl: userDoc.data()!['profileImageUrl'],
          ));
        }
      }
    }
    return matches;
  }

  /// --- 2. 「日付」を選択するロジック ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)), // 90日先まで
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// --- 3. 「時間」を選択するロジック ---
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// --- 4. 「予定」をFirestoreに保存するロジック ---
  Future<void> _saveSchedule() async {
    // バリデーション (入力チェック)
    if (_selectedOpponentId == null || _selectedDate == null || _selectedTime == null || _serviceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください')),
      );
      return;
    }
    // ログインチェック
    if (_currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラー: ログインしていません')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 2. トランザクションの「外」で、必要な情報を準備する

      // 保存する「場所」のリファレンス（住所）
      final userDocRef = _firestore.collection('users').doc(_currentUserUid!);
      final newScheduleDocRef = _firestore.collection('schedules').doc(); // 新しい予定のIDを先に作成

      // 選択した日付と時間を `DateTime` に結合し、`Timestamp` に変換
      final DateTime scheduleDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final Timestamp scheduleTimestamp = Timestamp.fromDate(scheduleDateTime);

      // 'schedules' コレクションに新しいドキュメントを追加
      final Map<String, dynamic> newScheduleData = {
        'status': 'pending',
        'serviceName': _serviceController.text.trim(),
        'scheduleAt': scheduleTimestamp,
        'participants': [_currentUserUid, _selectedOpponentId],
        'createdAt': FieldValue.serverTimestamp(),
        'receiverId': _currentUserUid,       // 利用する人 (自分) = 申請者
        'providerId': _selectedOpponentId, // 提供する人 (相手) = 承認者
      };

      // 3. トランザクションを実行
      await _firestore.runTransaction((transaction) async {
        // 3a. 【読み込み】まず、安全に「自分の」ドキュメントを読み込む
        final DocumentSnapshot userDoc = await transaction.get(userDocRef);

        if (!userDoc.exists) {
          throw Exception("ユーザーデータが見つかりません。");
        }

        // 3b. 【確認】チケットが1枚以上あるか確認する
        final int currentTickets = userDoc.data().toString().contains('tickets') ? userDoc.get('tickets') : 0;

        if (currentTickets < 1) {
          // チケットが0枚なら、Exceptionを投げてトランザクションを失敗させる
          throw Exception('チケットがありません。');
        }

        // 3c. 【書き込み①】チケットを1枚消費する
        transaction.update(userDocRef, {
          'tickets': FieldValue.increment(-1)
        });

        // 3d. 【書き込み②】新しい予定を作成する
        transaction.set(newScheduleDocRef, newScheduleData);
      });

      // 4. すべて成功
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予定を申請しました！')),
        );
        Navigator.of(context).pop(); // 成功したら前の画面（予定タブ）に戻る
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予定の申請に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('予定を作成'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. 「誰と」 (マッチ相手のリスト) ---
            const Text('誰と交換しますか？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<MatchWithUser>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('マッチ相手を読み込み中...');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('予定を作成できる相手がいません');
                }

                // DropdownButton でマッチ相手を選択
                return DropdownButtonFormField<String>(
                  value: _selectedOpponentId, // value は String?,
                  hint: const Text('相手を選択'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: snapshot.data!.map((match) {
                    return DropdownMenuItem<String>(
                      value: match.opponentId, // value は String (相手のID)
                      child: Text(match.opponentNickname), // 相手のニックネーム
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOpponentId = newValue;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // --- 2. 「何を」 (サービス名) ---
            const Text('何を交換しますか？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _serviceController,
              decoration: const InputDecoration(
                hintText: '例：プログラミング講座',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. 「いつ」 (日付と時間) ---
            const Text('いつ交換しますか？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // 日付選択
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
              ),
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDate == null
                  ? '日付を選択'
                  : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),
            // 時間選択
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4.0),
              ),
              leading: const Icon(Icons.access_time),
              title: Text(_selectedTime == null
                  ? '時間を選択'
                  : _selectedTime!.format(context)),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 32),

            // --- 5. 保存ボタン ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: _saveSchedule, // 保存ロジックを呼ぶ
              child: const Text(
                '予定を保存する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}