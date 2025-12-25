import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Page_ChatRoom extends StatefulWidget {
  final String opponentId;       // 相手のUID
  final String opponentNickname; // 相手のニックネーム (AppBar表示用)
  final String opponentImageUrl; // 相手の画像URL (AppBar表示用)

  const Page_ChatRoom({
    super.key,
    required this.opponentId,
    required this.opponentNickname,
    required this.opponentImageUrl,
  });

  @override
  State<Page_ChatRoom> createState() => _Page_ChatRoomState();
}

class _Page_ChatRoomState extends State<Page_ChatRoom> {
  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // メッセージ入力欄のコントローラー
  final TextEditingController _messageController = TextEditingController();

  // 自分のID
  late String _myId;
  // 結合されたチャットルームID
  late String _chatRoomId;

  // 画面を閉じたときに監視を終了するために必要です
  StreamSubscription<QuerySnapshot>? _unreadSubscription;

  @override
  void initState() {
    super.initState();
    _myId = _auth.currentUser!.uid;

    // --- チャットルームIDを生成 ---
    // 2人のIDをリストに入れる
    List<String> ids = [_myId, widget.opponentId];
    // アルファベット順（辞書順）に並び替える
    ids.sort();
    // 2つのIDを '_' で結合して、一意のチャットルームIDを作成
    _chatRoomId = ids.join('_');

    // ↓↓↓↓ 【追加】画面を開いている間、未読メッセージを既読にする処理を開始 ↓↓↓↓
    _startMarkingAsRead();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // ↓↓↓↓ 【追加】未読メッセージを監視して既読にするロジック ↓↓↓↓
  void _startMarkingAsRead() {
    final unreadQuery = _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: _myId) // 自分宛て
        .where('isRead', isEqualTo: false);    // 未読のもの

    _unreadSubscription = unreadQuery.snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        // 1つずつ既読(true)に更新
        doc.reference.update({'isRead': true});
      }
    });
  }

  /// --- メッセージを送信するロジック ---
  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) {
      return; // 入力が空なら何もしない
    }

    // 入力欄をクリア
    _messageController.clear();

    try {
      // 'chat_rooms' -> (チャットルームID) -> 'messages' にドキュメントを追加
      await _firestore
          .collection('chat_rooms')
          .doc(_chatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': _myId, // 送信者 (自分)
        'receiverId': widget.opponentId, // 受信者 (相手)
        'createdAt': FieldValue.serverTimestamp(), // 送信日時
        'isRead': false, // ← 【修正】送信時は「未読」にする
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージの送信に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            // 相手のプロフィール画像
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(widget.opponentImageUrl),
            ),
            const SizedBox(width: 12),
            // 相手のニックネーム
            Text(
              widget.opponentNickname,
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0, // 影を薄くつける
      ),
      body: Column(
        children: [
          // --- 1. メッセージリスト (リアルタイム) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // 'messages' サブコレクションを 'createdAt' (作成日時) で並び替えて監視
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true) // 新しい順
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('メッセージを送信してみましょう'));
                }

                final messagesDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  reverse: true, // ← 必須！下から積み上げる
                  itemCount: messagesDocs.length,
                  itemBuilder: (context, index) {
                    final messageData = messagesDocs[index].data();
                    // 自分が送信したメッセージかどうかを判定
                    final bool isMe = messageData['senderId'] == _myId;
                    return _buildMessageItem(messageData['text'], isMe);
                  },
                );
              },
            ),
          ),

          // --- 2. メッセージ入力欄 ---
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// --- 1件のメッセージ（「自分」か「相手」か）のUI ---
  Widget _buildMessageItem(String text, bool isMe) {
    final double width = MediaQuery.of(context).size.width;
    
    return Container(
      // `Row` を使って、`isMe` なら右寄せ、`isMe` でないなら左寄せ
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
           child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              // `isMe` ならシアン、`isMe` でないならグレー
              color: isMe ? Colors.cyan : Colors.grey[200],
              borderRadius: BorderRadius.circular(20.0),
            ),
              constraints: BoxConstraints(
               maxWidth: width * 0.7, // 画面幅の70%以上には広がらないようにする
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
              softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --- メッセージ入力欄のUI ---
  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(8.0),
      // SafeAreaで、OSのホームバー（iPhoneなど）を避ける
      child: SafeArea(
        child: Row(
          children: [
            // 入力フィールド
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                maxLines: null, // 自動で改行
              ),
            ),
            const SizedBox(width: 8),
            // 送信ボタン
            IconButton(
              icon: const Icon(Icons.send, color: Colors.cyan),
              onPressed: _sendMessage, // 送信ロジックを呼ぶ
            ),
          ],
        ),
      ),
    );
  }
}