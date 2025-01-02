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
     const Page_home(),
     const Page_search(),
     const Page_message(),
     Page_profile(),
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
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home),label:'home'),
            BottomNavigationBarItem(icon: Icon(Icons.search),label: 'search'),
            BottomNavigationBarItem(icon: Icon(Icons.message),label: 'message'),
            BottomNavigationBarItem(icon: Icon(Icons.person),label: 'profile'),
            ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}




