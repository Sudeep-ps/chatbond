import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/services/alert_service.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/services/database_service.dart';
import 'package:chatbond/services/navigation_service.dart';
import 'package:chatbond/widgets/chat_tile.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), actions: [
        IconButton(
            color: Colors.red,
            onPressed: () async {
              bool result = await _authService.logout();
              if (result) {
                _alertService.showToast(
                    text: "Successfully logged out", icon: Icons.check);
                _navigationService.pushReplacementNamed("/login");
              }
            },
            icon: const Icon(Icons.logout))
      ]),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
      child: _chatsList(),
    ));
  }

  Widget _chatsList() {
    return StreamBuilder(
        stream: _databaseService.getUserProfiles(),
        builder: (context, snapshots) {
          if (snapshots.hasError) {
            return const Center(
              child: Text("Unable to load data"),
            );
          }
          if (snapshots.hasData && snapshots.data != null) {
            final users = snapshots.data!.docs;
            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  UserProfile user = users[index].data();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ChatTile(userProfile: user, onTap: () {}),
                  );
                });
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
