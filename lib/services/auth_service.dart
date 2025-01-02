import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(String username, String email, String password) async {
    try {
      //FirebaseAuthでユーザー作成
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? userId = userCredential.user?.uid;

      //デフォルトのプロフィール画像URL
      String defaultProfileImageUrl =
        'https://flutter-image-network.web.app/inu.jpeg';

      //Firestoreのコレクションに登録
      await _firestore.collection('users').doc(userId).set({
        'username': username,
        'profileImageUrl': defaultProfileImageUrl , // 初期値
        'followersCount': 0,
        'followingCount': 0,
      });


    } catch (e) {
      print('Error creating user: $e');
    }
  }
}