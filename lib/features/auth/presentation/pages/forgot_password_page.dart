import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/core/widgets/custom_formfield.dart';
import 'package:chatbond/consts.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  String? _email;

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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          );
        },
      ).show(context);
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    ref.listen(forgotPasswordProvider, (previous, next) {
      next.when(
        data: (_) {
          _showToast('OTP sent. Check your email.', Icons.check);
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppConstants.verifyOtpRoute,
            (route) => false,
            arguments: {'purpose': 'RESET_PASSWORD', 'email': _email},
          );
        },
        loading: () {},
        error: (error, stackTrace) {
          _showToast(error.toString(), Icons.error);
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recover your account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email and we will send you an OTP to reset your password.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                CustomFormfield(
                  hintText: 'Email',
                  height: 70,
                  validateRegEx: EMAIL_VALIDATION_REGEX,
                  onSaved: (value) {
                    _email = value;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _formKey.currentState?.save();
                              ref
                                  .read(forgotPasswordProvider.notifier)
                                  .forgotPassword(_email!);
                            }
                          },
                    color: Theme.of(context).colorScheme.primary,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
