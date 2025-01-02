import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:third/sub/pages/page_follow_users.dart';

class Page_search extends StatelessWidget {
  const Page_search({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('search'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          //ユーザーデータのリストを取得
          List<DocumentSnapshot> users = snapshot.data!.docs;

          return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context,index) {
                var user = users[index];
                String userId = user.id; // ドキュメントID（ユーザーID）
                String username = user['username'];
                String profileImageUrl = user['profileImageUrl'];

                if (userId == FirebaseAuth.instance.currentUser?.uid) {
                  return SizedBox.shrink(); // 自分自身をリストから非表示
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                title: Text(username),
                onTap: (){
                    // プロフィールページに遷移して targetUserId を設定
                    Navigator.push(context,
                    MaterialPageRoute(
                    builder: (context) => PageFollowUsers(targetUserId: userId),
                   ),
                  );
                 },
                );
               },
              );
             },
            ),
           );
          }
         }
