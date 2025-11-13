import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Step1で追加したパッケージ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Page_Evaluation_Provider extends StatefulWidget {
  // page_schedule から渡される情報
  final String scheduleId; // どの「予定」を評価するか
  final String opponentId; // 誰（利用者）を評価するか

  const Page_Evaluation_Provider({
    super.key,
    required this.scheduleId,
    required this.opponentId,
  });

  @override
  State<Page_Evaluation_Provider> createState() => _Page_Evaluation_ProviderState();
}

class _Page_Evaluation_ProviderState extends State<Page_Evaluation_Provider> {
  // Firebaseのインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 評価の値を保持する変数
  double _ratingQ1 = 0;
  double _ratingQ2 = 0;
  double _ratingQ3 = 0;
  bool? _wouldRecommend; // Q4. はい/いいえ
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// --- 評価をFirestoreに保存するロジック ---
  Future<void> _saveEvaluation() async {
    // バリデーション
    if (_ratingQ1 == 0 || _ratingQ2 == 0 || _ratingQ3 == 0 || _wouldRecommend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Q1〜Q4のすべてにお答えください')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 【あなたのルール 17:34】
      // 「提供者」が「利用者」を評価しても、チケットや経験値は変動しません。
      // 「評価の記録」と「評価済みフラグ」だけを保存します。

      // 1. 評価した 'schedules' ドキュメントの参照
      final scheduleDocRef = _firestore.collection('schedules').doc(widget.scheduleId);
      // 2. (オプション) 評価を 'evaluations' コレクションに保存
      final evalDocRef = _firestore.collection('evaluations').doc();

      await _firestore.runTransaction((transaction) async {

        // 3a. 'schedules' ドキュメントに「提供者側の評価が完了した」フラグを立てる
        transaction.update(scheduleDocRef, {
          'isEvaluatedByProvider': true,
        });

        // 3b. (オプション) 評価自体も 'evaluations' コレクションに保存する
        transaction.set(evalDocRef, {
          'scheduleId': widget.scheduleId,
          'evaluatorId': _auth.currentUser!.uid, // 評価者 (自分)
          'targetId': widget.opponentId,       // 被評価者 (利用者)
          'type': 'provider_to_receiver',    // 評価のタイプ
          'ratingQ1': _ratingQ1,
          'ratingQ2': _ratingQ2,
          'ratingQ3': _ratingQ3,
          'wouldRecommend': _wouldRecommend,
          'comment': _commentController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // 4. すべて成功
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('評価を送信しました！')),
        );
        Navigator.of(context).pop(); // 成功したら「予定」タブに戻る
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('評価の送信に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ↓↓↓↓ 【UI修正】 iPhone XR...11.png の背景色 ↓↓↓↓
      backgroundColor: const Color(0xFFFFFBEF), // 薄い黄色
      appBar: AppBar(
        title: const Text('スキルを提供しました！'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今回の相手の態度を教えてください。',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // ↓↓↓↓ 【UI修正】 iPhone XR...11.png の質問文と色 ↓↓↓↓

            // Q1. マナー・態度
            _buildRatingQuestion(
              question: 'Q1. 相手のマナー・態度はどうでしたか？',
              rating: _ratingQ1,
              onRatingUpdate: (rating) => setState(() => _ratingQ1 = rating),
            ),
            const SizedBox(height: 24),

            // Q2. 時間・約束
            _buildRatingQuestion(
              question: 'Q2. 時間・約束を守っていましたか？',
              rating: _ratingQ2,
              onRatingUpdate: (rating) => setState(() => _ratingQ2 = rating),
            ),
            const SizedBox(height: 24),

            // Q3. コミュニケーション
            _buildRatingQuestion(
              question: 'Q3. コミュニケーションはどうでしたか？',
              rating: _ratingQ3,
              onRatingUpdate: (rating) => setState(() => _ratingQ3 = rating),
            ),
            const SizedBox(height: 32),

            // Q4. また教えたいか (はい/いいえ)
            _buildYesNoQuestion(
              question: 'Q4. また、この相手に教えたいですか？',
              value: _wouldRecommend,
              onChanged: (bool? newValue) => setState(() => _wouldRecommend = newValue),
            ),
            const SizedBox(height: 32),

            // Q5. コメント
            const Text(
              'Q5. 一言コメントを残そう！',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '（任意）相手へのメッセージなど',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            // 送信ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700], // 黄色
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: _saveEvaluation, // 保存ロジックを呼ぶ
                child: const Text(
                  '評価を送信する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 星評価（Q1-Q3）の共通ウィジェット
  Widget _buildRatingQuestion({
    required String question,
    required double rating,
    required ValueChanged<double> onRatingUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber, // ↓↓↓↓ 【UI修正】 黄色の星 ↓↓↓↓
            ),
            onRatingUpdate: onRatingUpdate,
          ),
        ),
      ],
    );
  }

  /// はい/いいえ（Q4）の共通ウィジェット
  Widget _buildYesNoQuestion({
    required String question,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 「いいえ」ボタン
            ChoiceChip(
              label: const Text('いいえ'),
              selected: value == false,
              onSelected: (selected) => onChanged(false),
              selectedColor: Colors.grey[300],
            ),
            const SizedBox(width: 16),
            // 「はい」ボタン
            ChoiceChip(
              label: const Text('はい'),
              selected: value == true,
              onSelected: (selected) => onChanged(true),
              // ↓↓↓↓ 【UI修正】 黄色の「はい」 ↓↓↓↓
              selectedColor: Colors.amber[100],
            ),
          ],
        ),
      ],
    );
  }
}