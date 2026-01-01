import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/user_services.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  Stream<List<AppUser>> getDoctors() {
    return _userService.getDoctors();
  }

  Future<AppUser?> getUserById(String id) {
    return _userService.getUserById(id);
  }
}
