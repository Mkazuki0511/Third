import 'package:flutter/material.dart';

class Page_approval extends StatelessWidget {
  const Page_approval({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('承認'),
      ),
      body: const Center(
        child: Text('承認ページ',style: TextStyle(fontSize: 32.0),),
      ),
    );
  }
}
