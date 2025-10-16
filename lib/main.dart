import 'package:flutter/material.dart';
import 'package:third/start/pages/lobby.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:third/pages/page_home.dart';
import 'package:third/pages/page_search.dart';
import 'package:third/pages/page_message.dart';
import 'package:third/pages/page_profile.dart';
import 'firebase_options.dart';
import 'package:third/sub/pages/page_profile.edit.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const LobbyPage(), //最初の画面
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final _pages = [
     const Page_search(), // 0:探す
     Container(color: Colors.white, child: const Center(child: Text('承認ページ', style: TextStyle(fontSize: 32.0)))), // 1: 承認 (仮ページ)
     Container(color: Colors.white, child: const Center(child: Text('予定ページ', style: TextStyle(fontSize: 32.0)))), // 2: 予定 (仮ページ)
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          // 2, 5つのアイテムに変更
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.search),label: '探す'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline),label: '承認'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today),label: '予定'),
            BottomNavigationBarItem(icon: Icon(Icons.message),label: 'トーク'),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: 'アカウント'),
            ],
        type: BottomNavigationBarType.fixed, // 5つのアイテムを均等に配置するために必要
        selectedItemColor: Colors.blue, // 選択中のアイテムの色
        unselectedItemColor: Colors.grey, // 選択されていないアイテムの色
      ),
    );
  }
}




