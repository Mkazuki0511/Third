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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ログイン"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "メールアドレス",
              ),
              onChanged: (value) {
                email = value;
              },
            ),
            TextField(
              decoration: const InputDecoration(
                hintText: "パスワード",
              ),
              onChanged: (value) {
                password = value;
              },
              obscureText: true,
            ),

            ElevatedButton(
              onPressed:() async{
                //FirebaseAuthでログイン
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(
                        title:'home',
                      ),
                    ),
                        (Route<dynamic> route) => false,
                  );
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'user-not-found') {
                    print('No user found for that email.');
                  } else if (e.code == 'wrong-password') {
                    print('Wrong password provided for that user.');
                  } else{
                    print(e);
                  }
                }
              },
              child: Text("login"),
            ),
          ],
        ),
      ),
    );
  }
}
