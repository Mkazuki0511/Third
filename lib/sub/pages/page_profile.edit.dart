import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ↑ `page_profile.dart` と同じく、Auth と Firestore をインポートします

class Page_profile_edit extends StatelessWidget {
  const Page_profile_edit({super.key});

  /// --- birthday(Timestamp) から年齢を計算するロジック ---
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) {
      return '?'; // データがなければ '?' を表示
    }

    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();

    int age = today.year - birthday.year;

    // 今年の誕生日がまだ来ていない場合は、年齢を-1する
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }

    return age.toString(); // 計算した年齢を文字列として返す
  }


  @override
  Widget build(BuildContext context) {
    // 1. 現在のユーザーを取得
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // 2. StreamBuilderでFirestoreのデータをリアルタイムで監視
    // (このロジックは、page_profile.dart で実装したものと全く同じです)
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid) // currentUserがnullでもエラーにならないよう ? を追加
          .snapshots(),
      builder: (context, snapshot) {

        // --- 3. 読み込み中/エラーのUI ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('ユーザーデータが見つかりません')));
        }

        // --- 4. 成功！データを取得 ---
        final userData = snapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名前なし';
        final String? profileImageUrl = userData['profileImageUrl'];
        final String location = userData['location'] ?? '未設定';
        final String selfIntroduction = userData['selfIntroduction'] ?? '自己紹介がありません';
        final String teachSkill = userData['teachSkill'] ?? '未設定';
        final String learnSkill = userData['learnSkill'] ?? '未設定';
        // Firestoreから 'birthday' (Timestamp型) を取得
        final Timestamp? birthdayTimestamp = userData['birthday'];
        // _calculateAge メソッドに渡して、年齢（String）を取得
        final String age = _calculateAge(birthdayTimestamp);

        // --- 5. データを使ってUIを構築 ---
        // (with-....-0.webp と page_user_profile.dart の雰囲気を参考に構築)
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 「編集する」ボタンを画面下部に固定
          bottomNavigationBar: _buildFixedEditButton(context),

          body: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // メイン写真
                _buildMainPhotoCard(profileImageUrl),

                // サムネイル (ダミー)
                _buildThumbnails(),

                // プロフィール情報
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // 計算した 'age' をここで表示
                        '$nickname $age歳 $location',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 4),
                          Text('オンライン'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Firestoreから読み込んだ本物のデータを表示 ---
                      _buildInfoCard(
                        title: '自己紹介',
                        content: Text(selfIntroduction, style: const TextStyle(fontSize: 16, height: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: '教えるスキル',
                        content: Text(teachSkill, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: '学びたいスキル',
                        content: Text(learnSkill, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// メインの写真カード
  Widget _buildMainPhotoCard(String? profileImageUrl) {
    return Container(
      height: 400, // 高さを指定
      decoration: BoxDecoration(
        color: Colors.grey[200],
        image: profileImageUrl != null
            ? DecorationImage(
          image: NetworkImage(profileImageUrl),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: profileImageUrl == null
          ? const Center(child: Icon(Icons.person, size: 100, color: Colors.white))
          : null,
    );
  }

  /// サムネイル (with-....-0.webp 参考)
  Widget _buildThumbnails() {
    // (これはまだダミーデータです)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.person)),
          const SizedBox(width: 12),
          Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.photo_camera)),
        ],
      ),
    );
  }

  /// 自己紹介やスキルを表示する共通カード
  Widget _buildInfoCard({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  /// 画面下部に固定される「編集する」ボタン
  Widget _buildFixedEditButton(BuildContext context) {
    return Container(
      color: Colors.white, // 背景色
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: プロフィール「編集」ロジックへ
            // (例: page_onboarding_step4 を再利用して編集させるなど)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan, // with-....-0.webp の色
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          icon: const Icon(Icons.edit),
          label: const Text(
            '編集する',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}