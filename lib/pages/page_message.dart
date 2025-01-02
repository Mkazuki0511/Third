import 'package:flutter/material.dart';

class Page_message extends StatelessWidget {
  const Page_message({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('message'),
      ),
      body: const Center(
        child: Text('message',style: TextStyle(fontSize: 32.0),),
      ),
    );
  }
}
