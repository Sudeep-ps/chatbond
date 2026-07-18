import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/core/widgets/custom_formfield.dart';
import 'package:chatbond/consts.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/providers/chat_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey();
  String? email, password;

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
    ref.listen(loginProvider, (previous, state) {
      state.when(
        data: (authUser) {
          if (authUser == null) return;

          // Clear the provider state before navigating
          ref.read(loginProvider.notifier).reset();

          ref.invalidate(authRemoteDataSourceProvider);
          ref.invalidate(chatRemoteDataSourceProvider);

          _showToast('Login successful!', Icons.check);

          Navigator.of(context).pushNamedAndRemoveUntil(
              AppConstants.homeRoute, (route) => false);
        },
        loading: () {},
        error: (error, stackTrace) {
          _showToast('Failed to login, Please try again', Icons.error);

          // Clear the error state too
          ref.read(loginProvider.notifier).reset();
        },
      );
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _buildUI(context),
    );
  }

  Widget _buildUI(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
      child: Column(
        children: [
          _headerText(),
          _loginForm(context),
          _forgotPasswordLink(context),
          _createAnAccountLink(context),
        ],
      ),
    ));
  }

  Widget _headerText() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, Welcome Back!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            "Hello again, you've been missed",
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.40,
      margin: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).height * 0.05),
      child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomFormfield(
                hintText: 'Email',
                height: MediaQuery.sizeOf(context).height * 0.1,
                validateRegEx: EMAIL_VALIDATION_REGEX,
                onSaved: (value) {
                  email = value;
                },
              ),
              CustomFormfield(
                hintText: 'Password',
                height: MediaQuery.sizeOf(context).height * 0.1,
                validateRegEx: PASSWORD_VALIDATION_REGEX,
                obscureText: true,
                onSaved: (value) {
                  password = value;
                },
              ),
              _loginButton(context)
            ],
          )),
    );
  }

  Widget _loginButton(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.04,
      width: MediaQuery.sizeOf(context).width,
      child: MaterialButton(
        onPressed: loginState.isLoading
            ? null
            : () {
                if (_loginFormKey.currentState?.validate() ?? false) {
                  _loginFormKey.currentState?.save();
                  ref.read(loginProvider.notifier).login(email!, password!);
                }
              },
        color: Theme.of(context).colorScheme.primary,
        child: loginState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                "Login",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _createAnAccountLink(BuildContext context) {
    return Expanded(
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          const Text("Don't have an account? "),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppConstants.registerRoute);
            },
            child: const Text(
              "Sign Up",
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
            ),
          )
        ]));
  }

  Widget _forgotPasswordLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(AppConstants.forgotPasswordRoute);
        },
        child: const Text(
          'Forgot password?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
        ),
      ),
    );
  }
}
