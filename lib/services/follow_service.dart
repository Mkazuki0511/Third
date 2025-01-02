import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

//フォロー機能
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid; //ログインしている人のUID

    try {
      //自分がフォロー中リストに追加
      await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(targetUserId)
          .set({});

      //相手のフォロワーリストに追加
      await _firestore
          .collection('followers')
          .doc(targetUserId)
          .collection('userFollowers')
          .doc(currentUserId)
          .set({});

      //ユーザーのフォロー数とフォロワー数を更新
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });

      await _firestore.collection('users').doc(targetUserId).update({
        'followersCount': FieldValue.increment(1),
      });

      print('フォロー完了');
    } catch (e) {
      print('フォローに失敗しました: $e');
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      //自分のフォロー中リストから削除
      await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('userFollowing')
          .doc(targetUserId)
          .delete();

      //相手のフォロワーリストから削除
      await _firestore
          .collection('followers')
          .doc(targetUserId)
          .collection('userFollowers')
          .doc(currentUserId)
          .delete();

      //ユーザーのフォロー数とフォロワー数を更新
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1),
      });
      await _firestore.collection('users').doc(targetUserId).update({
        'followersCount': FieldValue.increment(-1),
      });
      
      print('アンフォロー完了');
    } catch (e) {
      print('アンフォローに失敗しました: $e');
    }
  }
}