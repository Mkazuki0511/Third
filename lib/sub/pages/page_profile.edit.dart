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
        final Timestamp? birthdayTimestamp = userData['birthday'];
        final String age = _calculateAge(birthdayTimestamp);

        // ★修正ポイント: サブ写真のリストを取得
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
                // メイン写真
                _buildMainPhotoCard(profileImageUrl),

                // ★修正ポイント: サブ写真リストを渡して表示
                _buildThumbnails(subImages),

                // プロフィール情報
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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

  /// ★修正: サブ写真のサムネイル表示 (リストを受け取るように変更)
  Widget _buildThumbnails(List<dynamic> subImages) {
    // 写真がない場合は何も表示しない（余白も消す）
    if (subImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: Colors.white,
      // 横スクロール可能なリストにする（中央寄せしたい場合は Center + SingleChildScrollView + Row の構成）
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
                    borderRadius: BorderRadius.circular(8), // 角丸にする
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
            // 「編集フォーム」ページへ遷移
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