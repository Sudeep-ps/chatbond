import 'dart:io';

import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/core/widgets/custom_formfield.dart';
import 'package:chatbond/consts.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatbond/features/profile/presentation/providers/profile_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  File? selectedImage;
  String? name, email, password;
  bool isLoading = false;

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
    final signupState = ref.watch(signupProvider);
    final uploadProfileState = ref.watch(uploadProfilePictureProvider);
    final createUserProfileState = ref.watch(createUserProfileProvider);

    ref.listen(signupProvider, (previous, state) {
      state.whenData((authUser) {
        if (authUser != null && selectedImage != null) {
          _uploadProfileAndCreateUser(authUser.uid);
        }
      });
    });

    ref.listen(createUserProfileProvider, (previous, state) {
      state.whenData((_) {
        _showToast('User registered successfully!', Icons.check);
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      });
    });

    bool isProcessing = uploadProfileState.isLoading ||
        createUserProfileState.isLoading ||
        signupState.isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(child: _buildUI(context, isProcessing)),
    );
  }

  Widget _buildUI(BuildContext context, bool isProcessing) {
    return IntrinsicHeight(
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          children: [
            _headerText(),
            if (!isProcessing) _registerForm(context),
            const Spacer(flex: 7),
            if (!isProcessing) _loginAccountLink(context),
            if (isProcessing)
              const Expanded(child: Center(child: CircularProgressIndicator()))
          ],
        ),
      )),
    );
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's get going",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            "Register an account using the form below",
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _registerForm(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.03),
      child: Form(
          key: _registerFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _pfpSelectionField(),
              CustomFormfield(
                  hintText: "Name",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: NAME_VALIDATION_REGEX,
                  onSaved: (value) {
                    name = value;
                  }),
              CustomFormfield(
                  hintText: "Email",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: EMAIL_VALIDATION_REGEX,
                  onSaved: (value) {
                    email = value;
                  }),
              CustomFormfield(
                  hintText: "Password",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: PASSWORD_VALIDATION_REGEX,
                  obscureText: true,
                  onSaved: (value) {
                    password = value;
                  }),
              _registerButton(context)
            ],
          )),
    );
  }

  Widget _pfpSelectionField() {
    return GestureDetector(
      onTap: () async {
        await ref
            .read(getImageFromGalleryProvider.notifier)
            .getImageFromGallery();
        final imageState = ref.read(getImageFromGalleryProvider);
        imageState.whenData((file) {
          if (file != null) {
            setState(() {
              selectedImage = file;
            });
          }
        });
      },
      child: CircleAvatar(
        radius: MediaQuery.sizeOf(context).width * 0.20,
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : NetworkImage(PLACEHOLDER_PFP, scale: 0.2) as ImageProvider,
      ),
    );
  }

  Widget _registerButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        onPressed: () async {
          if ((_registerFormKey.currentState?.validate() ?? false) &&
              (selectedImage != null)) {
            _registerFormKey.currentState?.save();
            ref.read(signupProvider.notifier).signup(email!, password!, name!);
          } else if (selectedImage == null) {
            _showToast('Please select a profile picture', Icons.warning);
          }
        },
        color: Theme.of(context).colorScheme.primary,
        child: const Text(
          "Register",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _uploadProfileAndCreateUser(String uid) async {
    if (selectedImage == null) return;

    await ref
        .read(uploadProfilePictureProvider.notifier)
        .uploadProfilePicture(selectedImage!, uid);

    final uploadState = ref.read(uploadProfilePictureProvider);
    uploadState.whenData((url) {
      if (url != null) {
        final userProfile = UserProfileEntity(
          uid: uid,
          name: name!,
          pfpURL: url,
        );
        ref.read(createUserProfileProvider.notifier).createProfile(userProfile);
      } else {
        _showToast('Failed to upload profile picture', Icons.error);
      }
    });
  }

  Widget _loginAccountLink(BuildContext context) {
    return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account? "),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              "Sign In",
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
            ),
          )
        ]);
  }
}
