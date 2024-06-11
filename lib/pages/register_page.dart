import 'dart:io';

import 'package:chatbond/consts.dart';
import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/services/alert_service.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/services/database_service.dart';
import 'package:chatbond/services/media_service.dart';
import 'package:chatbond/services/navigation_service.dart';
import 'package:chatbond/services/storage_service.dart';
import 'package:chatbond/widgets/custom_formfield.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey();
  final GetIt _getIt = GetIt.instance;
  late MediaService _mediaService;
  late NavigationService _navigationService;
  late AuthService _authService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  late AlertService _alertService;

  File? selectedImage;
  String? name, email, password;
  bool isloading = false;

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _navigationService = _getIt.get<NavigationService>();
    _authService = _getIt.get<AuthService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(child: _buildUI()),
    );
  }

  Widget _buildUI() {
    return IntrinsicHeight(
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          children: [
            _headerText(),
            if (!isloading) _registerForm(),
            // const Spacer(
            //   flex: 7,
            // ),
            if (!isloading) _loginAccountLink(),
            if (isloading)
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
        mainAxisSize: MainAxisSize.max,
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

  Widget _registerForm() {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.03),
      child: Form(
          key: _registerFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _pfpSelectionField(),
              CustomFormfield(
                  hintText: "Name",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: NAME_VALIDATION_REGEX,
                  onSaved: (value) {
                    setState(() {
                      name = value;
                    });
                  }),
              CustomFormfield(
                  hintText: "Email",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: EMAIL_VALIDATION_REGEX,
                  onSaved: (value) {
                    setState(() {
                      email = value;
                    });
                  }),
              CustomFormfield(
                  hintText: "Password",
                  height: MediaQuery.sizeOf(context).height * 0.1,
                  validateRegEx: PASSWORD_VALIDATION_REGEX,
                  obscureText: true,
                  onSaved: (value) {
                    setState(() {
                      password = value;
                    });
                  }),
              _registerButton()
            ],
          )),
    );
  }

  Widget _pfpSelectionField() {
    return GestureDetector(
      onTap: () async {
        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          setState(() {
            selectedImage = file;
          });
        }
      },
      child: CircleAvatar(
        radius: MediaQuery.sizeOf(context).width * 0.20,
        backgroundImage: selectedImage != null
            ? FileImage(selectedImage!)
            : NetworkImage(PLACEHOLDER_PFP, scale: 0.2) as ImageProvider,
      ),
    );
  }

  Widget _registerButton() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        onPressed: () async {
          setState(() {
            isloading = true;
          });
          try {
            if ((_registerFormKey.currentState?.validate() ?? false) &&
                (selectedImage != null)) {
              _registerFormKey.currentState?.save();
              bool result = await _authService.signup(email!, password!);
              if (result) {
                String? pfpURL = await _storageService.uploadUserPfp(
                    file: selectedImage!, uid: _authService.user!.uid);
                if (pfpURL != null) {
                  await _databaseService.createUserProfile(
                      userProfile: UserProfile(
                          uid: _authService.user!.uid,
                          name: name,
                          pfpURL: pfpURL));
                  _alertService.showToast(
                      text: "User registered successfully!", icon: Icons.check);
                  _navigationService.goBack();
                  _navigationService.pushReplacementNamed('/home');
                } else {
                  throw Exception("Unable to upload user profile picture");
                }
              } else {
                throw Exception("Unable to register user");
              }
            }
          } catch (e) {
            print(e);
            _alertService.showToast(
                text: "Failed to register, Please try again!",
                icon: Icons.check);
          }
          setState(() {
            isloading = false;
          });
        },
        color: Theme.of(context).colorScheme.primary,
        child: const Text(
          "Register",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _loginAccountLink() {
    return Expanded(
      child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Already have an account? "),
            GestureDetector(
              onTap: () {
                _navigationService.goBack();
              },
              child: const Text(
                "Login",
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
              ),
            )
          ]),
    );
  }
}
