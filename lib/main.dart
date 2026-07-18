import 'dart:io';

import 'package:chatbond/config/theme.dart';
import 'package:chatbond/core/utils/firebase_utils.dart';
import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:chatbond/features/auth/presentation/pages/login_page.dart';
import 'package:chatbond/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:chatbond/features/auth/presentation/pages/register_page.dart';
import 'package:chatbond/features/auth/presentation/pages/reset_password_page.dart';
import 'package:chatbond/features/chat/presentation/pages/chat_page.dart';
import 'package:chatbond/features/home/presentation/pages/home_page.dart';
import 'package:chatbond/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/data/datasources/auth_remote_data_source_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthRemoteDataSourceImpl.bootstrap();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChatBond',
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (authUser) {
          return authUser != null ? const HomePage() : const LoginPage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) {
          return const LoginPage();
        },
      ),
      routes: {
        AppConstants.loginRoute: (context) => const LoginPage(),
        AppConstants.registerRoute: (context) => const RegisterPage(),
        AppConstants.verifyOtpRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return OtpVerificationPage(
            purpose: args?['purpose']?.toString() ?? 'signup',
            email: args?['email']?.toString(),
            pendingImage: args?['pendingImage'] as File?,
            pendingName: args?['pendingName']?.toString(),
          );
        },
        AppConstants.forgotPasswordRoute: (context) =>
            const ForgotPasswordPage(),
        AppConstants.resetPasswordRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ResetPasswordPage(
            resetToken: args?['resetToken']?.toString() ?? '',
          );
        },
        AppConstants.homeRoute: (context) => const HomePage(),
        AppConstants.profileRoute: (context) => const ProfilePage(),
        AppConstants.chatRoute: (context) => const ChatPage(),
      },
    );
  }
}
