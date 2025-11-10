import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ↓↓↓↓ 【修正①】StatelessWidget -> StatefulWidget に変更 ↓↓↓↓
class Page_user_profile extends StatefulWidget {

  // どのユーザーのプロフィールを表示するか、IDを受け取る
  final String userId;

  const Page_user_profile({
    super.key,
    required this.userId,
  });

  @override
  State<Page_user_profile> createState() => _Page_user_profileState();
}

// ↓↓↓↓ 【修正②】新しい _State クラスを作成 ↓↓↓↓
class _Page_user_profileState extends State<Page_user_profile> {

  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 「いいね！」ボタンのローディング状態
  bool _isLoading = false;

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

  // ↓↓↓↓ 【ここからが今回のロジック】 ↓↓↓↓
  /// --- 「いいね！」(リクエスト) を送信するロジック ---
  Future<void> _sendRequest() async {
    // 1. 自分のID (currentUser) と 相手のID (targetUser) を取得
    final String? myId = _auth.currentUser?.uid;
    final String targetUserId = widget.userId; // ← StatefulWidgetなので 'widget.' が必要

    if (myId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラー: ログインしていません')),
      );
      return;
    }

    // 2. 既にリクエスト済みか、マッチ済みか、などを（将来的には）チェックする
    // TODO: (今はシンプルに、押したらリクエストを送る)

    setState(() {
      _isLoading = true; // ローディング開始
    });

    try {
      // 3. Firestore の 'requests' コレクションに新しいドキュメントを追加
      await _firestore.collection('requests').add({
        'fromId': myId,         // 送信者 (自分)
        'toId': targetUserId, // 受信者 (相手)
        'status': 'pending',  // 状態: '承認待ち'
        'createdAt': FieldValue.serverTimestamp(), // 送信日時
      });

      // 4. 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('「いいね！」を送信しました！')),
        );
        Navigator.of(context).pop(); // (例: 探す画面に戻る)
      }

    } catch (e) {
      // エラー処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リクエストの送信に失敗しました: $e')),
        );
      }
    } finally {
      // 処理が完了したらローディングを解除
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 「いいね！」ボタンを画面下部に固定
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // ↓↓↓↓ 【修正③】_isLoading を渡す ↓↓↓↓
      floatingActionButton: _buildFloatingLikeButton(context, _isLoading),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // ↓↓↓↓ 【修正④】widget.userId を使う ↓↓↓↓
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ユーザーデータが見つかりません'));
          }

          // データを取得
          final userData = snapshot.data!.data()!;
          final String nickname = userData['nickname'] ?? '名前なし';
          final String? profileImageUrl = userData['profileImageUrl'];
          final String location = userData['location'] ?? '未設定';
          final Timestamp? birthdayTimestamp = userData['birthday'];
          final String age = _calculateAge(birthdayTimestamp);
          final String selfIntroduction = userData['selfIntroduction'] ?? '自己紹介がありません';
          final String teachSkill = userData['teachSkill'] ?? '未設定';
          final String learnSkill = userData['learnSkill'] ?? '未設定';

          // UIを構築 (変更なし)
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainPhotoCard(profileImageUrl),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildNameAndLocation(nickname, age, location, teachSkill, learnSkill),
                      const SizedBox(height: 16),
                      _buildSelfIntroductionCard(selfIntroduction),
                      const SizedBox(height: 16),
                      _buildBasicInfoCard(), // (まだダミー)
                      const SizedBox(height: 16),
                      _buildInterestsCard(), // (まだダミー)
                      const SizedBox(height: 120), // ボタンの余白
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 2層目：画面下部に固定される「いいね！」ボタン
  // ↓↓↓↓ 【修正⑤】isLoading を受け取る ↓↓↓↓
  Widget _buildFloatingLikeButton(BuildContext context, bool isLoading) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // ↓↓↓↓ 【修正⑥】ローディング中は押せないように(null)する ↓↓↓↓
              onPressed: isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                // ↓↓↓↓ 【修正⑦】ローディング中の見た目を設定 ↓↓↓↓
                disabledBackgroundColor: Colors.grey[400],
              ),
              icon: isLoading
                  ? Container( // ローディング中はインジケーターを表示
                width: 24, height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Icon(Icons.thumb_up_alt_outlined), // 通常時はアイコン
              label: Text(
                isLoading ? '送信中...' : 'いいね！', // テキストも切り替える
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- (ここから下は、UI表示用のメソッド) ---

  /// メインの写真カード
  Widget _buildMainPhotoCard(String? profileImageUrl) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: profileImageUrl != null
              ? DecorationImage(
            image: NetworkImage(profileImageUrl),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: profileImageUrl == null
            ? const Center(child: Icon(Icons.person, size: 100, color: Colors.white))
            : Align( /* ... (オンライン表示) ... */ ),
      ),
    );
  }

  /// 名前のエリア
  Widget _buildNameAndLocation(String nickname, String age, String location, String teachSkill, String learnSkill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$nickname $age歳 $location',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Chip(
              label: Text('Partner'), // (ダミー)
              backgroundColor: Colors.blueAccent,
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Chip(
              label: Text('教えるよ: $teachSkill'),
              backgroundColor: Colors.cyan[100],
              labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('学びたい: $learnSkill'),
              backgroundColor: Colors.cyan[100],
              labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  /// 自己紹介カード
  Widget _buildSelfIntroductionCard(String selfIntroduction) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '自己紹介文',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              selfIntroduction,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// 基本情報カード (まだダミー)
  Widget _buildBasicInfoCard() {
    return Card(/* ... */);
  }
  /// 興味・関心カード (まだダミー)
  Widget _buildInterestsCard() {
    return Card(/* ... */);
  }
  /// 基本情報カード内の一行 (まだダミー)
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(/* ... */);
  }
}