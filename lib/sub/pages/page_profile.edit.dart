import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'page_profile_editor.dart';

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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
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
        final Timestamp? birthdayTimestamp = userData['birthday'];
        final String age = _calculateAge(birthdayTimestamp);

        // サブ写真のリストを取得
        final List<dynamic> subImages = userData['subProfileImageUrls'] ?? [];

        // --- 5. データを使ってUIを構築 ---
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
                // メイン写真 (正方形・角丸・余白)
                _buildMainPhotoCard(profileImageUrl),

                // サブ写真リスト
                _buildThumbnails(subImages),

                // プロフィール情報
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                       horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                     crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Text(
                        '$nickname $age歳 $location',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),

                        const Spacer(),

                      const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 4),
                          Text('オンライン'),
                         ],
                        ),
                       ],
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        title: '自己紹介',
                        content: Text(selfIntroduction, style: const TextStyle(fontSize: 16, height: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: '教えるスキル',
                        content: Text(teachSkill, style: const TextStyle(fontSize: 16, )),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: '学びたいスキル',
                        content: Text(learnSkill, style: const TextStyle(fontSize: 16, )),
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

  /// メインの写真カード (修正: AspectRatioで正方形にする)
  Widget _buildMainPhotoCard(String? profileImageUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32,0,32,0),
      child: AspectRatio(
        aspectRatio: 1.0, // 1.0 = 正方形 (幅:高さ = 1:1)
        child: Container(
          // height: 400, // ← 高さは自動で決まるので削除
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
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
        ),
      ),
    );
  }

  /// サブ写真のサムネイル表示
  Widget _buildThumbnails(List<dynamic> subImages) {
    if (subImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: subImages.map((imageUrl) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl.toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildFixedEditButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const Page_Profile_Editor(),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
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