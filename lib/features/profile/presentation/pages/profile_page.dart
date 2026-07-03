import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatbond/features/profile/presentation/providers/profile_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontFamily: GoogleFonts.montserrat().fontFamily,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
          child: currentUserProfile.when(
            data: (userProfile) {
              if (userProfile == null) {
                return const Center(child: Text('No profile data found.'));
              }
              return Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.20,
                          backgroundImage: userProfile.pfpURL != null
                              ? NetworkImage(userProfile.pfpURL!)
                              : const NetworkImage(
                                  'https://t3.ftcdn.net/jpg/05/16/27/58/360_F_516275801_f3Fsp17x6HQK0xQgDQEELoTuERO4SsWV.jpg'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userProfile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                      onPressed: () => _deleteAccount(userProfile),
                      child: const Text("Delete account"))
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    await ref.read(getImageFromGalleryProvider.notifier).getImageFromGallery();
    final imageState = ref.read(getImageFromGalleryProvider);

    imageState.whenData((file) async {
      if (file != null) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          // Delete old profile picture if exists
          final userProfile = ref.read(currentUserProfileProvider);
          userProfile.whenData((profile) {
            if (profile?.pfpURL != null) {
              ref
                  .read(deleteProfilePictureProvider.notifier)
                  .deleteProfilePicture(profile!.pfpURL!);
            }
          });

          // Upload new profile picture
          await ref
              .read(uploadProfilePictureProvider.notifier)
              .uploadProfilePicture(file, currentUser.uid);

          // Refresh the current user profile
          ref.refresh(currentUserProfileProvider);
          _showToast('Profile picture updated!', Icons.check);
        }
      }
    });
  }

  Future<void> _deleteAccount(dynamic userProfile) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Delete profile picture if exists
      if (userProfile.pfpURL != null) {
        await ref
            .read(deleteProfilePictureProvider.notifier)
            .deleteProfilePicture(userProfile.pfpURL);
      }

      // Delete Firebase user
      await ref.read(deleteUserProvider.notifier).deleteUser();
      _showToast('Account deleted successfully', Icons.check);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showToast('Failed to delete account', Icons.error);
    }
  }
}
