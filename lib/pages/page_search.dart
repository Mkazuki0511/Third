import 'package:flutter/material.dart';
// import 'package:third/pages/page_user_profile.dart'; // 将来「詳しく見る」で使います

class Page_search extends StatelessWidget {
  const Page_search({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 画面全体の背景色
      // AppBarは使わず、SafeAreaで安全領域を確保
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(), // 検索バーとフィルターボタン

            // ユーザーカードのリスト（スクロール可能）
            // ↓↓↓↓ ここから変更 ↓↓↓↓
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0), // グリッド全体の余白
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2列
                  crossAxisSpacing: 12.0, // カード間の横スペース
                  mainAxisSpacing: 12.0, // カード間の縦スペース

                  // ↓↓↓↓ 【修正①】カードを正方形にするため 1.0 に変更 ↓↓↓↓
                  childAspectRatio: 1.0, // カードの縦横比 (お好みで調整)
                ),
                itemCount: 6, // ダミーで6人表示
                itemBuilder: (context, index) {
                  // 新しいグリッド用のカードメソッドを呼ぶ
                  return _buildUserGridCard(
                    name: 'Kazu',
                    age: 24,
                    location: '東京',
                    oneLiner: 'ディズニー行きたい',
                    imageUrl: 'https://example.com/grid-image.jpg',
                    commonPoints: 5,
                    photoCount: 6,
                  );
                },
              ),
            ),
            // ↑↑↑↑ ここまで変更 ↑↑↑↑
          ],
        ),
      ),
    );
  }

  /// 「With」風の2列グリッド用ユーザーカード (新しく追加)
  Widget _buildUserGridCard({
    required String name,
    required int age,
    required String location,
    required String oneLiner,
    required String imageUrl,
    int commonPoints = 0,
    int photoCount = 0,
  })
  {return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // 子が角丸をはみ出ないようにする
      elevation: 2.0,
      child: Stack(
        fit: StackFit.expand, // Stackの子をいっぱいに広げる
        children: [
          // 1. メイン画像 (ダミー)
          Container(
            color: Colors.grey[300],
            child: Center(child: Text('[${imageUrl}]')),
            // image: DecorationImage(
            //   image: NetworkImage(imageUrl),
            //   fit: BoxFit.cover,
            // ),
          ),

          // 2. 画像のグラデーションオーバーレイ (文字を読みやすくするため)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100, // グラデーションの高さ
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // 3. 共通点・写真数タグ (With風)
          if (commonPoints > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Chip(
                label: Text('共通点 $commonPoints', style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.orange.withOpacity(0.8),
                padding: EdgeInsets.zero,
              ),
            ),
          if (photoCount > 0)
            Positioned(
              top: 8, // 共通点がない場合はここ
              left: 8,
              child: Chip(
                label: Text('📷 $photoCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.zero,
              ),
            ),

          // 4. メインのテキスト情報
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 縦のサイズを最小に
              children: [
                Text(
                  '$age歳 $location',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // 「心理テスト参加中」などのアイコン
                    Icon(Icons.chat_bubble_outline, color: Colors.yellow[600], size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        oneLiner,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis, // 1行で省略
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// 検索バーとフィルターボタン
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '検索条件を設定する',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none, // 枠線なし
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // フィルター設定画面への遷移
            },
          ),
        ],
      ),
    );
  }


  /// ユーザーカード
  Widget _buildUserCard({
    required String name,
    required int age,
    required String location,
    required String bio,
    required String teachSkill,
    required String learnSkill,
    required String imageUrl,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // 画像の角丸
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // メイン画像
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.grey[300],
              child: Center(child: Text('[${imageUrl}]')), // ダミー画像の代わりにURLを表示
              // image: DecorationImage(
              //   image: NetworkImage(imageUrl), // 将来的にFirebaseから取得
              //   fit: BoxFit.cover,
              // ),
            ),
          ),
          // プロフィール情報
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$name ($age) $location',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.favorite_border, color: Colors.grey), // お気に入りボタン
                  ],
                ),
                const SizedBox(height: 8),
                Text(bio, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('教えるよ:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(teachSkill),
                      backgroundColor: Colors.cyan[100],
                      labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('学びたい:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(learnSkill),
                      backgroundColor: Colors.cyan[100],
                      labelStyle: const TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 詳しく見るボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // ここに「他人のプロフィール」ページへの遷移を書く
                      // Navigator.push(context, MaterialPageRoute(builder: (context) =>  Page_user_profile(userId: ...)),);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('詳しく見る'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

