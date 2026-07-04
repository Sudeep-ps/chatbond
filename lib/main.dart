import 'package:chatbond/config/theme.dart';
import 'package:chatbond/core/utils/firebase_utils.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/auth/presentation/pages/login_page.dart';
import 'package:chatbond/features/auth/presentation/pages/register_page.dart';
import 'package:chatbond/features/chat/presentation/pages/chat_page.dart';
import 'package:chatbond/features/home/presentation/pages/home_page.dart';
import 'package:chatbond/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/data/datasources/auth_remote_data_source_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthRemoteDataSourceImpl.bootstrap();
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
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}
