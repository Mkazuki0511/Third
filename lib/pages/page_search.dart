import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
import 'page_user_profile.dart'; // ← 「詳しく見る」の遷移先

// データを読み込むため StatefulWidget に変更
class Page_search extends StatefulWidget {
  const Page_search({super.key});

  @override
  State<Page_search> createState() => _Page_searchState();
}

class _Page_searchState extends State<Page_search> {
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid; // 現在ログインしているユーザーのID
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ← Firestore インスタンスを追加

  // フィルター条件を保持する状態変数
  String? _selectedRegion; // 地域
  String? _selectedGender; // 性別
  RangeValues? _selectedAgeRange; // 年齢

  String _searchKeyword = '';

  /// --- birthday(Timestamp) から年齢を計算するロジック ---
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) {
      return '?'; // データがなければ '?' を表示
    }
    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age.toString();
  }

  /// --- 自分が既に関わった（送信 or 受信）相手のIDリストを取得する ---
  Future<List<String>> _getInteractedUserIds() async {
    if (_currentUserUid == null) {
      return []; // ログインしてなければ空
    }

    // Set を使うと、IDの重複を自動で防げる
    final Set<String> interactedUserIds = {};

    // 1. 自分が「送信」したリクエスト（いいね！した相手）
    final sentRequestsSnapshot = await _firestore
        .collection('requests')
        .where('fromId', isEqualTo: _currentUserUid)
        .get();

    for (var doc in sentRequestsSnapshot.docs) {
      interactedUserIds.add(doc.data()['toId'] as String);
    }

    // 2. 自分が「受信」したリクエスト（いいね！してくれた相手）
    final receivedRequestsSnapshot = await _firestore
        .collection('requests')
        .where('toId', isEqualTo: _currentUserUid)
        .get();

    for (var doc in receivedRequestsSnapshot.docs) {
      interactedUserIds.add(doc.data()['fromId'] as String);
    }

    // 3. 自分のIDもリストに追加（自分自身を「探す」に表示しないため）
    interactedUserIds.add(_currentUserUid!);

    return interactedUserIds.toList();
  }


  // --- フィルター条件に基づいて Firestore の Stream を構築する ---
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildUserStream() {
    // 1. ベースとなるクエリ
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    // 2. フィルター条件を動的に追加
    // 【地域】
    if (_selectedRegion != null) {
      query = query.where('location', isEqualTo: _selectedRegion);
    }

    // 【性別】
    if (_selectedGender != null) {
      query = query.where('gender', isEqualTo: _selectedGender);
    }

    // 【年齢】（「範囲指定」クエリ）
    if (_selectedAgeRange != null) {
      // 'age' 20〜30歳 は、'birthday' の Timestamp に変換する必要がある

      final int minAge = _selectedAgeRange!.start.round(); // 最小
      final int maxAge = _selectedAgeRange!.end.round();   // 最大

      // (例) 30歳 の誕生日 (これより「後」に生まれている)
      final DateTime minBirthday = DateTime.now().subtract(Duration(days: ((maxAge + 1) * 365.25).round()));
      // (例) 20歳 の誕生日 (これより「前」に生まれている)
      final DateTime maxBirthday = DateTime.now().subtract(Duration(days: (minAge * 365.25).round()));

      query = query
          .where('birthday', isGreaterThanOrEqualTo: Timestamp.fromDate(minBirthday))
          .where('birthday', isLessThanOrEqualTo: Timestamp.fromDate(maxBirthday));
    }

    // 3. 構築したクエリでスナップショットを返す
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(onFilterPressed: _showFilterSheet), // 検索バーとフィルターボタン

            // ユーザーカードのリスト（スクロール可能）
            Expanded(
              child: FutureBuilder<List<String>>(
                  future: _getInteractedUserIds(), // ← 今作ったメソッドを呼ぶ
                  builder: (context, interactionSnapshot) {

                    // 1. IDリストの読み込み中
                    if (interactionSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 2. IDリストの取得に失敗
                    if (interactionSnapshot.hasError) {
                      return Center(child: Text('エラー: ${interactionSnapshot.error}'));
                    }

                    // 3. IDリスト取得成功
                    // (もしリストが空でも、自分のIDは含まれているので 'whereNotIn' はエラーにならない)
                    final List<String> interactedUserIds = interactionSnapshot.data ?? [_currentUserUid!];

                    // 4. IDリストを使って、「ユーザー」のStreamBuilderを構築
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _buildUserStream(),

                      builder: (context, userSnapshot) {
                        // 読み込み中
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // エラー発生
                        if (userSnapshot.hasError) {
                          return Center(child: Text('エラー: ${userSnapshot.error}'));
                        }

                        // データが 0件
                        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('表示できるユーザーがいません'));
                        }

                        // 5. 2段階フィルタリング（アプリ側除外）
                        final usersDocs = userSnapshot.data!.docs;

                        // ここですべてのフィルタリングを行う　(検索フィルタリング)
                        final List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs =
                        usersDocs.where((doc) {
                          final data = doc.data();

                          // 1. 関わったユーザーを除外
                          if (interactedUserIds.contains(data['uid'])) {
                            return false;
                          }

                          // 2. スキル検索（部分一致）
                          // キーワードが入力されている場合のみチェック
                          if (_searchKeyword.isNotEmpty) {
                            final String teachSkill = (data['teachSkill'] ?? '').toString();
                            // 入力されたキーワードが含まれていなければ非表示 (false)
                            if (!teachSkill.contains(_searchKeyword)) {
                              return false;
                            }
                          }
                          return true;
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return const Center(child: Text('条件に合うユーザーがいません'));
                        }

                        // 6. 最終的なリストで GridView を構築
                        return GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final userData = filteredDocs[index].data();
                            return _buildUserGridCard(
                              context: context,
                              userData: userData,
                            );
                          },
                        );
                      },
                    );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 検索バーとフィルターボタン
  Widget _buildSearchBar({required VoidCallback onFilterPressed}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value;
                  });
                },
                style: const TextStyle(
                  fontSize: 13.0, // 例: 14.0 -> 13.0
                  color: Colors.black,
                ),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'スキルで検索',
                  hintStyle: const TextStyle(
                    fontSize: 13.0, // 入力文字と同じサイズに合わせる
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0.0,
                      horizontal: 16.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }

  // フィルター選択UI（ボトムシート）
  /// --- フィルター選択ボトムシートを表示する ---
  void _showFilterSheet() {
    // シート内で一時的に保持する値
    // (StatefulBuilder を使うため、シートが閉じるまで値が保持される)
    String? tempRegion = _selectedRegion;
    String? tempGender = _selectedGender;
    RangeValues tempAgeRange = _selectedAgeRange ?? const RangeValues(20, 50); // デフォルト20-50歳

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 高さを画面の9割に
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // StatefulBuilder を使うと、シート内だけで setState が可能
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ヘッダー ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                          'フィルター',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // --- フィルター項目 ---
                  Expanded(
                    child: ListView(
                      children: [
                        // --- 年齢 ---
                        Text('年齢: ${tempAgeRange.start.round()} - ${tempAgeRange.end.round()} 歳'),
                        RangeSlider(
                          values: tempAgeRange,
                          min: 18,
                          max: 80,
                          divisions: 62,
                          labels: RangeLabels(
                            tempAgeRange.start.round().toString(),
                            tempAgeRange.end.round().toString(),
                          ),
                          onChanged: (values) {
                            setSheetState(() {
                              tempAgeRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- 性別 ---
                        Text('性別'),
                        DropdownButton<String>(
                          value: tempGender,
                          hint: const Text('指定なし'),
                          isExpanded: true,
                          items: ['男性', '女性', 'その他']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              tempGender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // --- 地域 ---
                        Text('地域'),
                        DropdownButton<String>(
                          value: tempRegion,
                          hint: const Text('指定なし'),
                          isExpanded: true,
                          items: [
                            '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
                            '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
                            '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
                            '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
                            '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
                            '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
                            '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'] // リスト
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              tempRegion = value;
                            });
                          },
                        ),
                        // TODO: スキル のドロップダウンも同様に追加

                      ],
                    ),
                  ),

                  // --- 適用・リセットボタン ---
                  Row(
                    children: [
                      TextButton(
                        child: const Text('リセット'),
                        onPressed: () {
                          // メイン画面の状態（State）をリセット
                          setState(() {
                            _selectedRegion = null;
                            _selectedGender = null;
                            _selectedAgeRange = null;
                          });
                          Navigator.pop(sheetContext); // シートを閉じる
                        },
                      ),
                      Expanded(
                        child: ElevatedButton(
                          child: const Text('適用する'),
                          onPressed: () {
                            // メイン画面の状態（State）を更新
                            setState(() {
                              _selectedRegion = tempRegion;
                              _selectedGender = tempGender;
                              _selectedAgeRange = tempAgeRange;
                            });
                            Navigator.pop(sheetContext); // シートを閉じる
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 2列グリッド用ユーザーカード
  Widget _buildUserGridCard({
    required BuildContext context,
    required Map<String, dynamic> userData,
  }) {
    // Firestore のデータを取り出す
    final String nickname = userData['nickname'] ?? '名無し';
    final Timestamp? birthdayTimestamp = userData['birthday'];
    final String age = _calculateAge(birthdayTimestamp); // 年齢を計算
    final String location = userData['location'] ?? '未設定';
    final String? profileImageUrl = userData['profileImageUrl'];
    final String teachSkill = userData['teachSkill'] ?? 'スキル未設定';

    return GestureDetector( // ← カード全体をタップ可能にする
      onTap: () async {
        // 「詳しく見る」のロジック
        // 遷移先の page_user_profile に、タップした人の 'uid' を渡す
        await Navigator.push(context, MaterialPageRoute(
          builder: (context) => Page_user_profile(userId: userData['uid']),
        ));
        setState(() {});
      },

      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. メイン画像
            // profileImageUrl で分岐
            profileImageUrl != null
                ? Image.network(
              profileImageUrl,
              fit: BoxFit.cover,
              // 画像読み込みエラー時のフォールバック
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50, color: Colors.white));
              },
            )
                : Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50, color: Colors.white)),

            // 2. 画像のグラデーション
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 3. 写真数タグ (削除)
            //Positioned(
              //top: 8,
              //left: 8,
              //child: Chip(
              //label: Text('📷 6', style: const TextStyle(color: Colors.white, fontSize: 10)),
              //backgroundColor: Colors.black.withOpacity(0.5),
              //padding: EdgeInsets.zero,),),

            // 4. メインのテキスト情報
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$age歳 $location',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.cyan[200], size: 14), // 「教える」アイコン
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          teachSkill, // 教えるスキル
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}