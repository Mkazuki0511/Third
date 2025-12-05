import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Page_user_profile extends StatefulWidget {
  // どのユーザーのプロフィールを表示するか、IDを受け取る
  final String userId;

  const Page_user_profile({
    super.key,
    required this.userId,
  });

  @override
  State<Page_user_profile> createState() => _Page_user_profileState();
}

class _Page_user_profileState extends State<Page_user_profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;


  @override
  void dispose() {
    super.dispose();
  }

  // ランク画像判定
  String _getRankImagePath(int exp) {
    if (exp >= 3500) {
      return 'assets/images/Lank_Legend.png';
    } else if (exp >= 1800) {
      return 'assets/images/Lank_Mentor.png';
    } else if (exp >= 900) {
      return 'assets/images/Lank_Partner.png';
    } else if (exp >= 300) {
      return 'assets/images/Lank_Learner.png';
    } else {
      return 'assets/images/Lank_Beginner.png';
    }
  }

  // 年齢計算
  String _calculateAge(Timestamp? birthdayTimestamp) {
    if (birthdayTimestamp == null) return '?';
    final DateTime birthday = birthdayTimestamp.toDate();
    final DateTime today = DateTime.now();
    int age = today.year - birthday.year;
    if (today.month < birthday.month ||
        (today.month == birthday.month && today.day < birthday.day)) {
      age--;
    }
    return age.toString();
  }

  // 「いいね！」送信ロジック
  Future<void> _sendRequest() async {
    final String? myId = _auth.currentUser?.uid;
    final String targetUserId = widget.userId;

    if (myId == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラー: ログインしていません')),
        );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('requests').add({
        'fromId': myId,
        'toId': targetUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('「いいね！」を送信しました！')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リクエストの送信に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 足あとロジック
  @override
  void initState() {
    super.initState();
    _addFootprint();
  }

  Future<void> _addFootprint() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final String visitorId = currentUser.uid;
      final String profileOwnerId = widget.userId;

      if (visitorId == profileOwnerId) return;

      final CollectionReference footprintsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(profileOwnerId)
          .collection('footprints');

      await footprintsRef.doc(visitorId).set({
        'visitorId': visitorId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('足あとの書き込みに失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // ベース背景色
      // extendBodyBehindAppBar: true, // ← 削除（カードがヘッダーに被らないようにするため）
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5), // 背景色と合わせる
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      // 「いいね！」ボタン
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingLikeButton(context, _isLoading),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ユーザーデータが見つかりません'));
          }

          final userData = snapshot.data!.data()!;
          final String nickname = userData['nickname'] ?? '名前なし';
          final String? profileImageUrl = userData['profileImageUrl'];

          final List<
              dynamic> subImagesDynamic = userData['subProfileImageUrls'] ?? [];
          final List<String> subImageUrls = subImagesDynamic.cast<String>();

          final List<String> rawImages = [];
          if (profileImageUrl != null) rawImages.add(profileImageUrl);
          rawImages.addAll(subImageUrls);

          final List<String> allImages = rawImages.toSet().toList();

          print('画像の枚数: ${allImages.length}');
          print('画像リスト: $allImages');

          final String location = userData['location'] ?? '未設定';
          final Timestamp? birthdayTimestamp = userData['birthday'];
          final String age = _calculateAge(birthdayTimestamp);
          final String selfIntroduction =
              userData['selfIntroduction'] ?? '自己紹介がありません';
          final String teachSkill = userData['teachSkill'] ?? '未設定';
          // final String learnSkill = userData['learnSkill'] ?? '未設定'; // 今回は使わない
          final int experiencePoints = userData['experiencePoints'] ?? 0;

          return SingleChildScrollView(
            // 下部にボタン用の余白を確保
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Padding(
                  // AppBarの下からスタートさせるため top は少なめでOK
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. 写真（カード内）
                        PhotoSlider(images: allImages),

                        // 2. 詳細情報
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNameAndLocation(
                                nickname,
                                age,
                                location,
                                teachSkill,
                                experiencePoints,
                              ),
                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 24),
                              const Text(
                                '自己紹介',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                selfIntroduction,
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 「いいね！」ボタン
  Widget _buildFloatingLikeButton(BuildContext context, bool isLoading) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                disabledBackgroundColor: Colors.grey[400],
              ),
              icon: isLoading
                  ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
              )
                  : const Icon(Icons.thumb_up_alt_outlined),
              label: Text(
                isLoading ? '送信中...' : 'いいね！',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 名前・ランク・オンライン・スキル表示
  Widget _buildNameAndLocation(String nickname, String age, String location,
      String teachSkill, int exp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$nickname $age歳 $location',
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              _getRankImagePath(exp),
              height: 24,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.circle, size: 10, color: Colors.green),
            SizedBox(width: 6),
            Text(
              'オンライン',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 「教えるよ」スキルのみ表示（改行許可）
        _buildSkillItem(label: '教えるよ: ', skill: teachSkill),
      ],
    );
  }

  /// スキルバッジ（改行対応・省略なし）
  Widget _buildSkillItem({required String label, required String skill}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 複数行になったときに上揃え
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0), // ラベル位置調整
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(width: 4),
        // Flexibleで横幅に収めつつ、ContainerとTextで改行させる
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              skill,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}


// 画像スライダー
class PhotoSlider extends StatefulWidget {
  final List<String> images;

  const PhotoSlider({super.key, required this.images});

  @override
  State<PhotoSlider> createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<PhotoSlider> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 画像がない場合の処理
    if (widget.images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(
                child: Icon(Icons.person, size: 80, color: Colors.grey)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.images[index],
                    // 重要: Keyを追加して、Flutterに別の画像であることを認識させる
                    key: ValueKey(widget.images[index]),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.error)),
                  );
                },
              ),
              // インジケーター
              if (widget.images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (index) {
                      final bool isActive = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}