import 'package:flutter/material.dart';

// このページは今のところ StatefulWidget である必要はありません
class Page_message extends StatelessWidget {
  const Page_message({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Talk.png は背景が白です
      appBar: AppBar(
        // ↓↓↓↓ 【修正②】true を追加してタイトルを中央揃えに ↓↓↓↓
        centerTitle: true,

        title: const Text('トーク',
          style: TextStyle(
            fontSize: 18.0, // (お好みで 17.0 などに調整してください)
            fontWeight: FontWeight.bold, // (Talk.png のデザインに合わせて太字に)
            color: Colors.black, // (foregroundColor があるので不要かもですが念のため)
          ),
        ),

        backgroundColor: Colors.white, // AppBarの背景も白
        foregroundColor: Colors.black, // タイトルの文字色を黒に
        elevation: 0, // AppBarの影をなくし、ボディと一体化
      ),
      body: ListView.builder(
        itemCount: 7, // Talk.png に合わせてダミーで7人表示
        itemBuilder: (context, index) {
          // 実際はここでマッチした相手の(user)データを渡す
          return _buildTalkListItem(
            name: '名前',
            age: '年齢',
            location: '愛知',
          );
        },
      ),
    );
  }

  /// トーク一覧のリストアイテム（共通ウィジェット）
  Widget _buildTalkListItem({
    required String name,
    required String age,
    required String location,
  }) {
    // ↓↓↓↓ 【修正】Paddingウィジェットで全体を囲む ↓↓↓↓
    return Padding(
      // 8.0 の余白を上下に追加します（合計で16.0の間隔が空きます）
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            // 1. 左側の丸いアイコン
            leading: const CircleAvatar(
              radius: 30, // Talk.png の画像は大きめ
              backgroundColor: Colors.grey, // ダミーの背景色
              child: Center(
                  child: Icon(Icons.person, size: 30, color: Colors.white)),
            ),

            // 2. 中央のテキスト
            title: Text(
              '$name $age $location',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            // 3. (オプション) 最後のメッセージのプレビュー
            // subtitle: Text(
            //   'こんにちは！よろしくお願いします...',
            //   overflow: TextOverflow.ellipsis,
            // ),

            // 4. タップ動作
            onTap: () {
              // ここに個別のチャットルーム(page_chat_room.dartなど)への遷移を書く
              // Navigator.push(context, MaterialPageRoute(builder: (context) => Page_ChatRoom(...)));
            },
          ),
          // 5. 区切り線
          const Divider(
            height: 1,
            indent: 80, // アイコンの幅＋余白 (72+8)
            endIndent: 16, // 右側の余白
          ),
        ],
      ),
    );
  }
}