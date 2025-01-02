import 'package:flutter/material.dart';
import '../models/profile.dart';

class ProfileProvider with ChangeNotifier {
  Profile _profile = Profile();

  Profile get profile => _profile;

  void updateProfile(String name, String gender, int age) {
    _profile.name = name;
    _profile.gender = gender;
    _profile.age = age;
    notifyListeners();
  }
}