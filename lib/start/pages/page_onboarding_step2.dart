import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← Firebase Auth をインポート
import 'package:cloud_firestore/cloud_firestore.dart'; // ← Firestore をインポート
import 'page_onboarding_step3.dart'; // メイン写真ページ

class Page_onboarding_step2 extends StatefulWidget {
  // Step1から渡されたデータを保持するための変数
  final String nickname;
  final String email;
  final String? gender;
  final DateTime? birthday;
  final String? location;

  const Page_onboarding_step2({
    super.key,
    required this.nickname,
    required this.email,
    this.gender,
    this.birthday,
    this.location,
  });

  @override
  State<Page_onboarding_step2> createState() => _Page_onboarding_step2State();
}

class _Page_onboarding_step2State extends State<Page_onboarding_step2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Firebaseのインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ローディング状態を管理
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 「次へ」ボタンが押されたときの処理
  void _goToNextStep() async {
    // バリデーション（入力チェック）が通ったら
    if (_formKey.currentState!.validate()) {
      // ↓↓↓↓ 【ここからロジック本体】 ↓↓↓↓
      setState(() {
        _isLoading = true; // ローディング開始
      });

      try {
        // --- 1. Firebase Auth にアカウントを作成 ---
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: widget.email, // Step1から渡されたemail
          password: _passwordController.text, // 今入力されたパスワード
        );

        // 登録が成功したら、user情報を取得
        User? newUser = userCredential.user;

        if (newUser != null) {
          // --- 2. Firestore にユーザーの初期情報を保存 ---
          // user.uid をドキュメントIDとして、ユーザーデータを保存
          await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'email': widget.email,
          'nickname': widget.nickname,
          'createdAt': FieldValue.serverTimestamp(), // 作成日時
          'gender': widget.gender,
          'birthday': widget.birthday,
          'location': widget.location,

           // Step3以降で追加される情報（今はまだ null）
          'profileImageUrl': null,
          'teachSkill': null,
          'learnSkill': null,
          'selfIntroduction': null,
          });

          // --- 3. 成功したら次のStep3（メイン写真）へ ---
          if (mounted) { // mounted: 非同期処理の後にUI操作をするためのおまじない
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => const Page_onboarding_step3(),
              // TODO: Step3以降で uid やデータを参照する必要があるなら、渡す
              // builder: (context) => Page_onboarding_step3(uid: newUser.uid),
            ));
          }
        }
      } on FirebaseAuthException catch (e) {
        // Firebase Auth のエラー処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登録エラー: ${e.message}')),
          );
        }
      } catch (e) {
        // その他のエラー処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      } finally {
        // 処理が完了したらローディングを解除
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      // ↑↑↑↑ 【ここまでロジック本体】 ↑↑↑↑

      // そして、次の「メイン写真」ページに遷移します
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => Page_onboarding_step3(),
      ));
      print("次のステップ（メイン写真）へ");
      print("Email: ${widget.email}"); // Step1から渡されたEmail
      print("Nickname: ${widget.nickname}"); // Step1から渡されたNickname
      print("Password: ${_passwordController.text}"); // 今入力されたPassword
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('パスワード設定'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // ローディング中はインジケーターを表示
              )
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'あと少しです！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ログイン用のパスワードを設定してください',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // パスワード入力欄
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true, // パスワードを隠す
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return '6文字以上のパスワードを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 確認用パスワード入力欄
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード（確認用）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true, // パスワードを隠す
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '確認用パスワードを入力してください';
                  }
                  if (value != _passwordController.text) {
                    return 'パスワードが一致しません';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 登録ボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: _isLoading ? null : _goToNextStep,
                child: const Text(
                  '次へ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}