import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String verifyOtpRoute = '/verify-otp';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String chatRoute = '/chat';

  static final navigatorKeyProvider =
      Provider<GlobalKey<NavigatorState>>((ref) {
    return GlobalKey<NavigatorState>();
  });
}
