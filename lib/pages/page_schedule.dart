import 'package:flutter/material.dart';

class Page_schedule extends StatelessWidget {
  const Page_schedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定'),
      ),
      body: const Center(
        child: Text('予定ページ',style: TextStyle(fontSize: 32.0),),
      ),
    );
  }
}