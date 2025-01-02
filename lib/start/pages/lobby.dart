import 'package:flutter/material.dart';
import 'package:third/start/pages/login.dart';
import 'package:third/start/pages/singup.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const SingUpPage(),
                ),
                );
              },
              child: const Text("新規登録の方はこちら"),
            ),
            const SizedBox(height: 20),

      ElevatedButton(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        },
        child: const Text("ログイン"),
      ),
          ],
        ),
      ),
    );
  }
}
