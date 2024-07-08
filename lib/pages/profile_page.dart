import 'dart:io';

import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/services/database_service.dart';
import 'package:chatbond/services/navigation_service.dart';
import 'package:chatbond/services/storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final AuthService _authService = GetIt.instance.get<AuthService>();
  final StorageService _storageService = GetIt.instance.get<StorageService>();
  final NavigationService _navigationService =
      GetIt.instance.get<NavigationService>();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? oldPfpUrl;

  Future<UserProfile> getCurrentUserProfile() async {
    UserProfile userProfile = await _databaseService.getCurrentUserProfile();
    oldPfpUrl = userProfile.pfpURL;
    return userProfile;
  }

  @override
  Widget build(BuildContext context) {
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
          child: FutureBuilder<UserProfile>(
            future: getCurrentUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                UserProfile userProfile = snapshot.data!;
                return Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: MediaQuery.of(context).size.width * 0.20,
                            backgroundImage: NetworkImage(userProfile.pfpURL!),
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
                      userProfile.name!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          deleteAccount(userProfile.pfpURL!);
                        },
                        child: const Text("Delete account"))
                    // Add more profile details here
                  ],
                );
              } else {
                return const Center(child: Text('No profile data found.'));
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    bool _isLoading = false;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        String uid = _authService.user!.uid;
        String fileName = '$uid${path.extension(image.path)}';
        Reference storageRef = _storage.ref().child('users/pfp/$fileName');

        if (oldPfpUrl != null) {
          Reference oldImageRef = _storage.refFromURL(oldPfpUrl!);
          await oldImageRef.delete();
        }

        await storageRef.putFile(File(image.path));
        String downloadUrl = await storageRef.getDownloadURL();

        await _databaseService.updateUserProfilePicture(downloadUrl);

        setState(() {});
      } catch (e) {
        print(e);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _showDeleteAccountDialog() async {
  // AwesomeDialog(
  //   context: context,
  //   dialogType: DialogType.WARNING,
  //   headerAnimationLoop: false,
  //   animType: AnimType.TOPSLIDE,
  //   title: 'Delete Account',
  //   desc:
  //       'Are you sure you want to delete your account? This action cannot be undone.',
  //   btnCancelOnPress: () {},
  //   btnOkOnPress: () async {
  //     await deleteAccount();
  //   },
  // );
  // }

  Future<void> deleteAccount(String pfpURL) async {
    String uid = _authService.user!.uid;

    try {
      await _databaseService.deleteChats(uid);
      // Delete user data from Firestore
      await _databaseService.deleteUserData(uid);

      // Delete profile picture from Storage if exists

      await _storageService.deleteProfilePicture(pfpURL);

      // Delete user from Firebase Authentication
      await _authService.deleteFirebaseUser();

      // Navigate to login screen or handle post-deletion logic
      // Example:
      _navigationService.pushReplacementNamed('/login');
    } catch (e) {
      print("Error deleting account: $e");
      // Handle errors or show error message to the user
    }
  }
}
