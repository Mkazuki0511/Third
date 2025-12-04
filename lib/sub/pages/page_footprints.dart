import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PageFootprints extends StatefulWidget {
  const PageFootprints({super.key});

  @override
  _PageFootprintsState createState() => _PageFootprintsState();
}

class _PageFootprintsState extends State<PageFootprints> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _markAsChecked();
  }

  Future<void> _markAsChecked() async {
    if (currentUser == null) return;
    try {
      // 自分のドキュメントに「最後に足あとを確認した日時」を記録
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'lastCheckedFootprints': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('既読更新エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('足あと'),
      ),
      // ログインしていない場合は何も表示しない
      body: currentUser == null
          ? const Center(child: Text('ログインしていません'))
          : _buildFootprintsList(),
    );
  }

  /// 足あとリストの本体
  Widget _buildFootprintsList() {
    return StreamBuilder<QuerySnapshot>(
      // 1. 自分の 'footprints' サブコレクションを stream で取得
      //    timestamp (訪問日時) の降順 (descending) で並び替える
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('footprints')
          .orderBy('timestamp', descending: true) // ★新しい訪問順に
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('足あとはありません'));
        }

        // 取得したドキュメントのリスト
        final footprintDocs = snapshot.data!.docs;

        // 2. ListView.builder でリストを表示
        return ListView.builder(
          itemCount: footprintDocs.length,
          itemBuilder: (context, index) {
            // ひとつの足あとデータ (中身は 'visitorId' と 'timestamp')
            final footprintData = footprintDocs[index].data() as Map<String, dynamic>;
            final String visitorId = footprintData['visitorId'];

            // 3. ★ visitorId を使って、ユーザー情報を別途取得する
            //    このための専用ウィジェット (↓) を作ると管理しやすい
            return FootprintUserTile(visitorId: visitorId);
          },
        );
      },
    );
  }
}

/// visitorId からユーザー情報を取得して ListTile を表示する専用ウィジェット
class FootprintUserTile extends StatelessWidget {
  final String visitorId;

  const FootprintUserTile({super.key, required this.visitorId});

  @override
  Widget build(BuildContext context) {
    // 4. FutureBuilder で users コレクションから単発で情報を取得
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(visitorId)
          .get(), // ★ .get() で1回だけ取得
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // ユーザーが退会した場合など
          return const ListTile(title: Text('（不明なユーザー）'));
        }

        // 訪問者のユーザー情報を取得
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String nickname = userData['nickname'] ?? '名前なし';
        final String? profileImageUrl = userData['profileImageUrl'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl == null ? const Icon(Icons.person) : null,
          ),
          title: Text(nickname),
          // TODO: 訪問日時 (footprintData['timestamp']) も表示すると、より親切
          // subtitle: Text('xx分前に訪問'),
          onTap: () {
            // TODO: この人をタップしたら、その人のプロフィールページ (page_user_profile) に遷移
          },
        );
      },
    );
  }
}