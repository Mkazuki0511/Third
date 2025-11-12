import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'page_chat_room.dart'; // チャットルーム

// 状態（読み込みなど）を管理するため StatefulWidget に変更
class Page_message extends StatefulWidget {
  const Page_message({super.key});

  @override
  State<Page_message> createState() => _Page_messageState();
}

class _Page_messageState extends State<Page_message> {
  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 現在のユーザーID
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Center(child: Text('ログインしていません'));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'トーク',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true, // 中央揃え
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      // ↓↓↓↓ 【ここからがロジック本体】 ↓↓↓↓
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // --- 1. Stream（データの流れ）を定義 ---
        // 'requests' コレクションから
        // 'status' が 'approved'（承認済み）で、
        // 'participants'（参加者）に自分のIDが含まれているもの
        stream: _firestore
            .collection('requests')
            .where('status', isEqualTo: 'approved')
            .where('participants', arrayContains: _currentUserUid)
            .snapshots(),

        builder: (context, matchSnapshot) {
          // 読み込み中
          if (matchSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // エラー
          if (matchSnapshot.hasError) {
            return Center(child: Text('エラー: ${matchSnapshot.error}'));
          }
          // マッチ 0件
          if (!matchSnapshot.hasData || matchSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('マッチした相手がいません'));
          }

          // 2. 成功！マッチしたリストを取得
          final matchDocs = matchSnapshot.data!.docs;

          // 3. ListView でマッチ相手を一覧表示
          return ListView.builder(
            itemCount: matchDocs.length,
            itemBuilder: (context, index) {
              final matchData = matchDocs[index].data();
              final List<dynamic> participants = matchData['participants'];

              // 4. participants リストから「相手」のIDを特定する
              final String opponentId = participants.firstWhere(
                    (id) => id != _currentUserUid, // 自分じゃないほうが相手
                orElse: () => '', // (万が一見つからない場合)
              );

              if (opponentId.isEmpty) {
                return const ListTile(title: Text('エラー: 相手が見つかりません'));
              }

              // 5. 「相手のID」を使って、リストアイテムを表示
              return _MatchListItem(opponentId: opponentId);
            },
          );
        },
      ),
      // ↑↑↑↑ 【ロジックここまで】 ↑↑↑↑
    );
  }
}


/// --- マッチ相手の情報を表示するリストアイテム（`Talk.png` のUI） ---
class _MatchListItem extends StatefulWidget {
  final String opponentId;

  const _MatchListItem({required this.opponentId});

  @override
  State<_MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<_MatchListItem> {
  // 相手のユーザーデータを `Future` で1回だけ取得
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // チャットルームID
  late String _chatRoomId;
  late String _myId;

  @override
  void initState() {
    super.initState();
    // 1. `opponentId` を使って、'users' コレクションから相手のデータを取得
    _userDataFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.opponentId)
        .get();

    // 2. チャットルームIDを（page_chat_room と同じロジックで）生成
    _myId = _auth.currentUser!.uid;
    List<String> ids = [_myId, widget.opponentId];
    ids.sort(); // アルファベット順に並び替え
    _chatRoomId = ids.join('_'); // 結合
  }

  @override
  Widget build(BuildContext context) {
    // 7. `FutureBuilder` で相手のユーザーデータの読み込みを待つ
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDataFuture,
      builder: (context, userSnapshot) {

        // ユーザーデータ読み込み中
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(title: Text('読み込み中...'));
        }
        // ユーザーデータエラー
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const ListTile(title: Text('ユーザーが見つかりません'));
        }

        // 8. 成功！相手のデータを取得
        final userData = userSnapshot.data!.data()!;
        final String nickname = userData['nickname'] ?? '名無し';
        final String? profileImageUrl = userData['profileImageUrl'];
        final String location = userData['location'] ?? '未設定';
        // (年齢も計算して表示できますが、Talk.png にはないので省略)

        // 9. 取得したデータを使って「トークUI」を構築
        // (page_approval の _buildTalkListItem を流用)
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),

                title: Text(
                  '$nickname $location', // (Talk.png に合わせて年齢は非表示)
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                // 最後のメッセージをここに表示
                subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // 3. chat_rooms -> (ID) -> messages を監視
                  stream: _firestore
                      .collection('chat_rooms')
                      .doc(_chatRoomId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true) // 新しい順
                      .limit(1) // 最後の1件だけ
                      .snapshots(),

                  builder: (context, messageSnapshot) {
                    // 4. 最後のメッセージを表示
                    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                      final lastMessage = messageSnapshot.data!.docs.first.data();
                      return Text(
                        lastMessage['text'] ?? '', // メッセージ本文
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    // まだメッセージがない場合
                    return const Text(
                      'マッチしました！', // ダミーの代わりに
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),

                onTap: () {
                  // ここに個別のチャットルーム(page_chat_room.dart)への遷移
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => Page_ChatRoom(
                        opponentId: widget.opponentId, // 相手のIDを渡す
                        opponentNickname: nickname, // AppBar表示用に名前を渡す
                        opponentImageUrl: profileImageUrl ?? '', // AppBar表示用に画像URLを渡す
                      )
                  ));
                  print("チャットルームへ遷移 -> ${widget.opponentId}");
                },
              ),
              const Divider(
                height: 1,
                indent: 80,
                endIndent: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}