import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PageFavorites extends StatefulWidget {
  const PageFavorites({super.key});

  @override
  _PageFavoritesState createState() => _PageFavoritesState();
}

class _PageFavoritesState extends State<PageFavorites> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り'),
      ),
      body: currentUser == null
          ? const Center(child: Text('ログインしていません'))
          : _buildFavoritesList(),
    );
  }

  /// いいね！履歴リストの本体
  Widget _buildFavoritesList() {
    return StreamBuilder<QuerySnapshot>(
      // 1. 'requests' コレクションを stream で取得
      stream: FirebaseFirestore.instance
          .collection('requests')
      // ★条件1: 自分が送った (fromId が自分)
          .where('fromId', isEqualTo: currentUser!.uid)
      // ★条件2: まだ承認待ち (status が 'pending')
          .where('status', isEqualTo: 'pending')
      // ★新しい順に並び替え
          .orderBy('createdAt', descending: true)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('いいね！した履歴はありません'));
        }

        // 取得した「リクエスト」のドキュメントリスト
        final requestDocs = snapshot.data!.docs;

        // 2. ListView.builder でリストを表示
        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            // ひとつのリクエストデータ
            final requestData = requestDocs[index].data() as Map<String, dynamic>;

            // 3. ★「いいね！した相手」のID (toId) を取得
            final String targetUserId = requestData['toId'];

            // 4. 'toId' を使って、ユーザー情報を別途取得する (専用ウィジェット)
            return FavoriteUserTile(targetUserId: targetUserId);
          },
        );
      },
    );
  }
}


/// targetUserId からユーザー情報を取得して ListTile を表示する専用ウィジェット
/// (FootprintUserTile とほぼ同じです)
class FavoriteUserTile extends StatelessWidget {
  final String targetUserId;

  const FavoriteUserTile({super.key, required this.targetUserId});

  @override
  Widget build(BuildContext context) {
    // 5. FutureBuilder で users コレクションから単発で情報を取得
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const ListTile(title: Text('（不明なユーザー）'));
        }

        // 相手のユーザー情報を取得
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
          subtitle: const Text('承認待ち'), // 'pending' 状態であることがわかる
          onTap: () {
            // TODO: タップしたら、その人のプロフィールページ (page_user_profile) に遷移
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => Page_user_profile(userId: targetUserId),
            // ));
          },
        );
      },
    );
  }
}