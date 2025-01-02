import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:third/sub/pages/page_profile.edit.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../services/follow_service.dart';

class Page_profile extends StatefulWidget {
  Page_profile({super.key});

  @override
  _Page_profileState createState() => _Page_profileState();
}

  class _Page_profileState extends State<Page_profile> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FollowService _followService = FollowService();
  bool isFollowing = false;


  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context).profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('profile'),
          backgroundColor:Colors.blue
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.person,size: 100,),
              ElevatedButton(onPressed:(){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  Page_profile_edit()),);
              },

                child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.edit),
                  Text(' edit profile',style: TextStyle(
                    fontSize: 30
                  ),
                  ),
                ],
              ),
              ),
            ],
          ),

          FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                String username = userData['username'];
                int followersCount = userData['followersCount'] ?? 0;
                int followingCount = userData['followingCount'] ?? 0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    Text(username, style: TextStyle(fontSize: 24)),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(followersCount.toString(),
                                style: TextStyle(fontSize: 18)),
                            Text('フォロワー'),
                          ],
                        ),
                        SizedBox(width: 20),
                        Column(
                          children: [
                            Text(followingCount.toString(),
                                style: TextStyle(fontSize: 18)),
                            Text('フォロー中'),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [
              Text('name: ${profile.name}', style: TextStyle(fontSize: 18)),
              Text('gender: ${profile.gender}',style: TextStyle(fontSize: 18)),
              Text('age: ${profile.age}',style: TextStyle(fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }
}
