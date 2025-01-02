import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class SingUpPage extends StatefulWidget {
  const SingUpPage({super.key});

  @override
  State<SingUpPage> createState() => _SingUpPageState();
}

class _SingUpPageState extends State<SingUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();// AuthServiceをインスタンス化

  bool _isLoding = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoding = true;
      });

      try {
        //入力データをAuthserviceに渡して登録処理を依頼
        await _authService.registerUser(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );

        //登録成功時にメッセージを表示し画面遷移
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザー登録が完了しました。')),
        );
        Navigator.pop(context);
      } catch (e) {
        //エラー時にメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー：$e')),
        );
      } finally {
        setState(() {
          _isLoding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新規登録"),
      ),
      body: _isLoding
          ? Center(child: CircularProgressIndicator())
          :Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
                key: _formKey,
                child: Column(
                  children: [
                     TextFormField(
                       controller: _usernameController,
                       decoration: const InputDecoration(labelText: "ユーザー名"),
                       validator: (value) {
                       if (value == null || value.isEmpty) {
                        return 'ユーザー名を入力してください';
                       }
                      return null;
                       },
                     ),
                     TextFormField(
                       controller: _emailController,
                       decoration: const InputDecoration(labelText: "メールアドレス"),
                       validator: (value) {
                       if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return '正しいメールアドレスを入力してください';
                        }
                        return null;
                        },
                      ),
                     TextFormField(
                       controller: _passwordController,
                       decoration: InputDecoration(labelText: 'パスワード'),
                       obscureText: true,
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'パスワードを入力してください';
                         } else if (value.length < 6) {
                           return 'パスワードは6文字以上で入力してください';
                         }
                         return null;
                       },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                      onPressed: _registerUser,
                      child: Text('登録'),
                      ),
                   ],
                 ),
               ),
              ),
            );
           }
          }
