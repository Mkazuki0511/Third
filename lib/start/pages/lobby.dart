import 'package:flutter/material.dart';
import 'package:third/start/pages/login.dart';
// import 'package:third/start/pages/page_onboarding_step1.dart'; // ← 次のステップでこれを作成します

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ロゴとボタンを配置するために、画面のサイズを取得
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // 背景は白
      // AppBar は不要
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. ロゴ ---
              // Spacer を使って、ロゴを画面の上半分の中央に配置
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/skill_link_logo.png', // あなたのロゴ
                // ロゴの高さを画面の高さの約1/4に（お好みで調整）
                height: screenHeight * 0.25,
              ),
              const Spacer(flex: 3),

              // --- 2. ボタン ---
              // 「新規登録」ボタン (塗りつぶし)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan, // 画像の通りの塗りつぶし色
                  foregroundColor: Colors.white, // 白文字
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // 角丸
                  ),
                ),
                onPressed: () {
                  // 【次のステップ】
                  // ステップ4.2で作成する page_onboarding_step1.dart に遷移
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (context) => const Page_onboarding_step1(),
                  // ));
                  print("新規登録ボタンが押されました (遷移先は次のステップで作成)");
                },
                child: const Text('新規登録の方はこちら', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // 「ログイン」ボタン (枠線)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyan, // 文字と枠線の色
                  side: const BorderSide(color: Colors.cyan, width: 2), // 枠線
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // 角丸
                  ),
                ),
                onPressed: () {
                  // 既存のLoginPageに遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text('ログイン', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              // 画面下部の余白
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}