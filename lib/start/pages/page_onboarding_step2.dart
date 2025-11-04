import 'package:flutter/material.dart';
// import 'page_onboarding_step3.dart'; // ← 次のステップで作成するメイン写真ページ

class Page_onboarding_step2 extends StatefulWidget {
  // Step1から渡されたデータを保持するための変数
  final String nickname;
  final String email;
  // TODO: final String gender;
  // TODO: final DateTime birthday;
  // TODO: final String location;

  const Page_onboarding_step2({
    super.key,
    required this.nickname,
    required this.email,
    // TODO: 他のデータも受け取る
  });

  @override
  State<Page_onboarding_step2> createState() => _Page_onboarding_step2State();
}

class _Page_onboarding_step2State extends State<Page_onboarding_step2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 「次へ」ボタンが押されたときの処理
  void _goToNextStep() {
    // バリデーション（入力チェック）が通ったら
    if (_formKey.currentState!.validate()) {
      // 【フェーズ4.4】
      // ここで、Step1からのデータと、今入力されたパスワードを使って
      // Firebase Auth に「ユーザー登録」のロジックを（将来）呼び出します。

      // そして、次の「メイン写真」ページに遷移します
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (context) => Page_onboarding_step3(),
      // ));
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
      body: SingleChildScrollView(
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
                onPressed: _goToNextStep,
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