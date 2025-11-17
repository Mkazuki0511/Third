import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ← Step1で追加したパッケージ
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Page_Evaluation_Receiver extends StatefulWidget {
  // page_schedule から渡される情報
  final String scheduleId; // どの「予定」を評価するか
  final String opponentId; // 誰（提供者）を評価するか

  const Page_Evaluation_Receiver({
    super.key,
    required this.scheduleId,
    required this.opponentId,
  });

  @override
  State<Page_Evaluation_Receiver> createState() => _Page_Evaluation_ReceiverState();
}

class _Page_Evaluation_ReceiverState extends State<Page_Evaluation_Receiver> {
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
      final providerUserDocRef = _firestore.collection('users').doc(widget.opponentId);
      final receiverUserDocRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
      final scheduleDocRef = _firestore.collection('schedules').doc(widget.scheduleId);
      final evalDocRef = _firestore.collection('evaluations').doc();

      await _firestore.runTransaction((transaction) async {
        // (トランザクション内でランク計算のためのデータを先に取得しても良いが、
        //  まずはシンプルに「書き込み」だけを実行します)

        // 3a. 提供者の 'users' ドキュメントを更新
        transaction.update(providerUserDocRef, {
          'tickets': FieldValue.increment(1), // スキル提供でチケットを1枚獲得
          'experiencePoints': FieldValue.increment(100), // 経験値を100獲得 (仮)
          'servicesProvidedCount': FieldValue.increment(1), // 「提供回数」を +1
          // TODO: 経験値(exp)に応じて 'rank' も 'Learner' に更新するロジック
        });
        
        // 3b. 利用者(自分)の 'users' ドキュメントを更新
        transaction.update(receiverUserDocRef, {
          'servicesUsedCount': FieldValue.increment(1), // 「利用回数」を +1
        });

        // 3b. 'schedules' ドキュメントに「利用者側の評価が完了した」フラグを立てる
        transaction.update(scheduleDocRef, {
          'isEvaluatedByReceiver': true,
        });

        // 3c. (オプション) 評価自体も 'evaluations' コレクションに保存する
        // (これにより「平均満足度」などを計算できるようになります)
        transaction.set(evalDocRef, {
          'scheduleId': widget.scheduleId,
          'evaluatorId': _auth.currentUser!.uid, // 評価者 (自分)
          'targetId': widget.opponentId,       // 被評価者 (提供者)
          'type': 'receiver_to_provider',    // 評価のタイプ
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
      backgroundColor: Colors.cyan[50], // review.png の背景色
      appBar: AppBar(
        title: const Text('スキルを習得しました！'),
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
              '今回の相手に感謝の気持ちを伝えよう',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // Q1. サービス内容
            _buildRatingQuestion(
              question: 'Q1. サービス内容に満足しましたか？',
              rating: _ratingQ1,
              onRatingUpdate: (rating) => setState(() => _ratingQ1 = rating),
            ),
            const SizedBox(height: 24),

            // Q2. 説明
            _buildRatingQuestion(
              question: 'Q2. 説明は分かりやすかったですか？',
              rating: _ratingQ2,
              onRatingUpdate: (rating) => setState(() => _ratingQ2 = rating),
            ),
            const SizedBox(height: 24),

            // Q3. 対応
            _buildRatingQuestion(
              question: 'Q3. 対応は丁寧でしたか？',
              rating: _ratingQ3,
              onRatingUpdate: (rating) => setState(() => _ratingQ3 = rating),
            ),
            const SizedBox(height: 32),

            // Q4. また受けたいか (はい/いいえ)
            _buildYesNoQuestion(
              question: 'Q4. またサービスを受けたいですか？',
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
                hintText: '（任意）相手への感謝のメッセージなど',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
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
                  backgroundColor: Colors.cyan,
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
            allowHalfRating: false, // (星半分を許すなら true)
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.cyan, // review.png の色
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
              selectedColor: Colors.cyan[100],
            ),
          ],
        ),
      ],
    );
  }
}