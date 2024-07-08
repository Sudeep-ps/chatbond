import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/pages/chat_page.dart';
import 'package:chatbond/services/alert_service.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/services/database_service.dart';
import 'package:chatbond/services/navigation_service.dart';
import 'package:chatbond/widgets/chat_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late Stream<QuerySnapshot<UserProfile>> userProfiles;

  final TextEditingController _searchController = TextEditingController();
  //String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    userProfiles = _databaseService.getUserProfilessearch();

    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.clear();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    // Update userProfiles stream based on search query
    if (_searchController.text.isEmpty) {
      setState(() {
        userProfiles = _databaseService.getUserProfiles();
      });
    } else {
      setState(() {
        userProfiles = _databaseService.getUserProfilessearch(
          query: _searchController.text,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Messages",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          actions: [
            PopupMenuButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: const Text('Profile Details'),
                      onTap: () async {
                        _navigationService.pushNamed('/profile');
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Log out'),
                      onTap: () async {
                        bool result = await _authService.logout();
                        if (result) {
                          _alertService.showToast(
                              text: "Successfully logged out",
                              icon: Icons.check);
                          _navigationService.pushReplacementNamed("/login");
                        }
                      },
                    ),
                  ];
                }),
          ]),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIconColor: Theme.of(context).colorScheme.secondary,
                contentPadding: const EdgeInsets.all(8.0),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(child: _chatsList()),
        ],
      ),
    ));
  }

  Widget _chatsList() {
    return StreamBuilder<QuerySnapshot<UserProfile>>(
      stream: userProfiles,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in StreamBuilder: ${snapshot.error}');
          return const Center(
            child: Text("Unable to load data"),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No users found"),
          );
        }

        final users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            UserProfile user = users[index].data();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              child: ChatTile(
                userProfile: user,
                onTap: () async {
                  final chatExists = await _databaseService.checkChatExist(
                    _authService.user!.uid,
                    user.uid!,
                  );
                  if (!chatExists) {
                    await _databaseService.createNewChat(
                      _authService.user!.uid,
                      user.uid!,
                    );
                  }
                  _navigationService.push(MaterialPageRoute(builder: (context) {
                    return ChatPage(chatUser: user);
                  }));
                },
              ),
            );
          },
        );
      },
    );
  }
}
