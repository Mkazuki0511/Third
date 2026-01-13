import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = "";
  String password = "";

  // デザイン用のメインカラー
  final Color _primaryColor = const Color(0xFF00BCD4);

  @override
  Widget build(BuildContext context) {
    // 画面サイズを取得
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      // 背景色が漏れないように白を指定（ダークモード対策）
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 背景の装飾（右上の大きな円） ---
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // --- 背景の装飾（左下の大きな円） ---
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- メインコンテンツ（中央のカード） ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    const Center(
                      child: Text(
                        "LOG IN",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- メールアドレス入力欄 ---
                    TextField(
                      // 文字色を黒に固定（ダークモード対策）
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Email address",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                      ),
                      onChanged: (value) {
                        email = value;
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- パスワード入力欄 ---
                    TextField(
                      // 文字色を黒に固定（ダークモード対策）
                      style: const TextStyle(color: Colors.black),
                      obscureText: true, // パスワードを隠す
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _primaryColor),
                        ),
                      ),
                      onChanged: (value) {
                        password = value;
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- ログインボタン ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          // FirebaseAuthでログイン処理
                          try {
                            await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            if (context.mounted) {
                              // ↓↓↓ ここを修正 ↓↓↓
                              // 履歴を全て消してメイン画面へ遷移
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyHomePage(title: "Skill Link"),
                                ),
                                    (route) => false, // 過去のルートを全て無効にする設定
                              );
                            }
                          }  on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              print('No user found for that email.');
                            } else if (e.code == 'wrong-password') {
                              print('Wrong password provided for that user.');
                            } else {
                              print(e);
                            }
                          }
                        },
                        child: const Text(
                          "LOG IN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- その他のリンク（デザインのみ） ---
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forget Password?",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "don't have a account? ",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () {
                            // 新規登録画面への遷移など
                          },
                          child: Text(
                            "SIGN UP",
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}