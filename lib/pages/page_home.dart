import 'package:flutter/material.dart';

class Page_home extends StatelessWidget {
  const Page_home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('home'),
      ),
      body: const Center(
        child: Text('home',style: TextStyle(fontSize: 32.0),),
      ),
    );
  }
}
