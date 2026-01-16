import 'package:flutter/material.dart';
import 'package:third/start/pages/lobby.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:third/pages/page_search.dart';
import 'package:third/pages/page_message.dart';
import 'package:third/pages/page_profile.dart';
import 'package:third/pages/page_approval.dart';
import 'package:third/pages/page_schedule.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MyApp(),
  );

  if (kIsWeb) {
    // 画面の描画が終わるのを少しだけ待つ（一瞬チラつくのを防ぐため）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loader = html.document.getElementById('loading-screen');
      if (loader != null) {
        loader.style.opacity = '0'; // ふわっと消す
        // 0.5秒後に完全に削除
        Future.delayed(const Duration(milliseconds: 500), () {
          loader.remove();
        });
      }
    });
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKILL LINK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F7), // 背景色
          elevation: 0,                       // ★影を消してフラットにするなら0、残すなら数値を指定
        ),
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? const MyHomePage(title: 'Skill Link')
          : const LobbyPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  static final _pages = [
     const Page_search(), // 0:探す
     const Page_approval(), // 1: 承認
     const Page_schedule(), // 2: 予定
     const Page_message(), //3:トーク
     Page_profile(), //4:アカウント
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // 2. ライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);
    // 初期化時にステータスを更新
    _updateUserStatus(true);
  }

  @override
  void dispose() {
    // 3. 監視を終了
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. アプリの状態が変わった時に呼ばれる (開いた/閉じた)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // アプリが前面に来た -> オンライン
      _updateUserStatus(true);
    } else {
      // アプリがバックグラウンドに行った -> オフライン扱いに更新（または最終アクセス時刻のみ更新）
      _updateUserStatus(false);
    }
  }

  // 5. Firestoreにステータスを書き込む関数
  Future<void> _updateUserStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': isOnline, // (任意) シンプルなフラグ
        'lastActiveAt': FieldValue.serverTimestamp(), // ★これが重要
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 3.0, bottom: 30.0),

        child:BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,

          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          iconSize: 24.0,

          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal), // 選択中
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal), // 非選択

          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.search),label: '探す'),
            BottomNavigationBarItem(icon: Icon(Icons.thumb_up),label: 'いいね'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today),label: '予定'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined),label: 'トーク'),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: 'アカウント'),
            ],
        type: BottomNavigationBarType.fixed, // 5つのアイテムを均等に配置するために必要
        selectedItemColor: Colors.cyan, // 選択中のアイテムの色
        unselectedItemColor: Colors.grey, // 選択されていないアイテムの色
      ),
    ));
  }
}




