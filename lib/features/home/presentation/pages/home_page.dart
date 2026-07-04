import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/chat/presentation/pages/chat_page.dart';
import 'package:chatbond/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatbond/features/chat/presentation/widgets/chat_tile.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/token_storage.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late TextEditingController _searchController;

  @override
  void initState() async {
    super.initState();
    final apiClient = ref.read(apiClientProvider);
    final token = await TokenStorage.getAccessToken();
    if (token != null) ref.read(socketServiceProvider).connect(token);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _showToast(String text, IconData icon) {
    try {
      DelightToastBar(
        autoDismiss: true,
        position: DelightSnackbarPosition.top,
        builder: (context) {
          return ToastCard(
              color: Colors.grey,
              leading: Icon(icon, size: 20),
              title: Text(
                text,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ));
        },
      ).show(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProfile = ref.watch(currentUserProfileProvider);

    ref.listen(logoutProvider, (previous, state) {
      state.whenData((_) {
        _showToast('Successfully logged out', Icons.check);
        Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
      });
    });

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
                        Navigator.of(context)
                            .pushNamed(AppConstants.profileRoute);
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Log out'),
                      onTap: () async {
                        ref.read(logoutProvider.notifier).logout();
                      },
                    ),
                  ];
                }),
          ]),
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
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
          Expanded(child: _chatsList(context)),
        ],
      ),
    ));
  }

  Widget _chatsList(BuildContext context) {
    final userProfiles = ref.watch(searchedUserProfilesProvider);
    final currentUserProfile = ref.watch(currentUserProfileProvider);

    return userProfiles.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          return const Center(child: Text("No users found"));
        }
        return ListView.builder(
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final userProfile = profiles[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              child: ChatTile(
                userProfile: userProfile,
                onTap: () async {
                  if (currentUserProfile.hasValue &&
                      currentUserProfile.value != null) {
                    final currentUser = currentUserProfile.value!;

                    // Check if chat exists
                    await ref
                        .read(checkChatExistsProvider.notifier)
                        .checkExists(currentUser.uid, userProfile.uid);

                    final checkChatState = ref.read(checkChatExistsProvider);
                    final chatExists = checkChatState.maybeWhen(
                      data: (exists) => exists,
                      orElse: () => false,
                    );

                    if (!chatExists) {
                      await ref
                          .read(createChatProvider.notifier)
                          .createChat(currentUser.uid, userProfile.uid);
                    }

                    if (mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChatPage(chatUser: userProfile),
                      ));
                    }
                  }
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text("Error: $error"),
      ),
    );
  }
}
