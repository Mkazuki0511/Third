import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート

// これは「他人の」プロフィール詳細を表示するページです
class Page_user_profile extends StatelessWidget {

  // ↓↓↓↓ 【ここから修正】 ↓↓↓↓
  // どのユーザーのプロフィールを表示するか、IDを受け取る
  final String userId;

  const Page_user_profile({
    super.key,
    required this.userId, // ← 必須の引数として追加
  });
  // ↑↑↑↑ 【ここまで修正】 ↑↑↑↑


  /// --- birthday(Timestamp) から年齢を計算するロジック ---
  /// (page_profile_edit からコピー)
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
    return Scaffold(
      backgroundColor: Colors.grey[100],

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 「いいね！」ボタンを画面下部に固定
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingLikeButton(context, userId), // ← userId を渡す

      // ↓↓↓↓ 【ここから StreamBuilder に変更】 ↓↓↓↓
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // --- 1. Stream（データの流れ）を定義 ---
        // ログイン中のユーザーではなく、
        // 渡された 'widget.userId' のユーザー情報を監視する
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId) // ← ここが最重要！
            .snapshots(),

        builder: (context, snapshot) {

          // --- 2. 読み込み中/エラーのUI ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ユーザーデータが見つかりません'));
          }

          // --- 3. 成功！データを取得 ---
          final userData = snapshot.data!.data()!;
          final String nickname = userData['nickname'] ?? '名前なし';
          final String? profileImageUrl = userData['profileImageUrl'];
          final String location = userData['location'] ?? '未設定';
          final Timestamp? birthdayTimestamp = userData['birthday'];
          final String age = _calculateAge(birthdayTimestamp);
          final String selfIntroduction = userData['selfIntroduction'] ?? '自己紹介がありません';
          final String teachSkill = userData['teachSkill'] ?? '未設定';
          final String learnSkill = userData['learnSkill'] ?? '未設定';

          // TODO: 他のデータもすべて取得...

          // --- 4. データを使ってUIを構築 ---
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
                      // ↓↓↓↓ 【本物のデータに差し替え】 ↓↓↓↓
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
      // ↑↑↑↑ 【StreamBuilder ここまで】 ↑↑↑↑
    );
  }

  /// 2層目：画面下部に固定される「いいね！」ボタン
  Widget _buildFloatingLikeButton(BuildContext context, String targetUserId) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // 【フェーズ5.3】
                // ここに「いいね！」（リクエスト）のロジックを実装
                // 1. 自分のID (currentUser.uid) を取得
                // 2. 相手のID (targetUserId) を取得
                // 3. Firestore に「リクエスト」を送信する
                print("「いいね！」しました -> $targetUserId");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: const Text(
                'いいね！',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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