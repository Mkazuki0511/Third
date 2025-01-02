import 'package:flutter/material.dart';
import 'package:third/pages/page_profile.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';


class Page_profile_edit extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String selectedGender = '男性';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('プロフィール編集'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText:'名前'),
              ),

              DropdownButton<String>(
                  value: selectedGender,
                  items: ['男性','女性']
                  .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                  ))
                  .toList(),
                  onChanged: (value) {
                    selectedGender = value!;
                  },
              ),

              TextField(
                controller: ageController,
                decoration: InputDecoration(labelText:'年齢'),
                keyboardType: TextInputType.number,
              ),
                SizedBox(height: 20),
                ElevatedButton(
                onPressed: () {
                  final name = nameController.text;
                  final age = int.tryParse(ageController.text) ?? 0;
                  Provider.of<ProfileProvider>(context, listen: false)
                      .updateProfile(name, selectedGender, age);
                  Navigator.pop(context);
                },
                  child: Text('保存'),
              ),
            ] ),
      ),
    );
  }
}
