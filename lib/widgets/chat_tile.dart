import 'package:chatbond/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatTile extends StatelessWidget {
  final UserProfile userProfile;
  final Function onTap;
  const ChatTile({super.key, required this.userProfile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
      tileColor: Colors.blueGrey[100],
      onTap: () {
        onTap();
      },
      dense: false,
      leading: CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(userProfile.pfpURL!),
      ),
      title: Text(
        userProfile.name!,
        style: TextStyle(
            fontFamily: GoogleFonts.montserrat().fontFamily,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
