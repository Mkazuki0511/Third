import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/follow_service.dart';


class PageFollowUsers extends StatefulWidget {
  final String targetUserId;

  PageFollowUsers({required this.targetUserId});

  @override
  _PageFollowUsersState createState() => _PageFollowUsersState();
}

class _PageFollowUsersState extends State<PageFollowUsers> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FollowService _followService = FollowService();
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('following')
        .doc(currentUserId)
        .collection('userFollowing')
        .doc(widget.targetUserId)
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('おすすめプロフィール'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.targetUserId)
                  .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String username = userData['username'];
          String profileImageUrl = userData['profileImageUrl'];
          int followersCount = userData['followersCount'] ?? 0;
          int followingCount = userData['followingCount'] ?? 0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(profileImageUrl),
          ),
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

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (isFollowing) {
                    await _followService.unfollowUser(
                        currentUserId, widget.targetUserId);
                  } else {
                    await _followService.followUser(
                        currentUserId, widget.targetUserId);
                  }
                  _checkIfFollowing();
                },
                child: Text(isFollowing ? 'フォロー解除' : 'フォローする'),
              ),
          ],
          );
          },
      ),
    );
  }
}




