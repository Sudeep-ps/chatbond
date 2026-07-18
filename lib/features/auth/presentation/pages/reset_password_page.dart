import 'package:chatbond/core/widgets/custom_formfield.dart';
import 'package:chatbond/consts.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.resetToken});

  final String resetToken;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  String? _password;

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
    final state = ref.watch(resetPasswordProvider);

    ref.listen(resetPasswordProvider, (previous, next) {
      next.when(
          data: (_) {
            _showToast('Password reset successfully.', Icons.check);
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppConstants.loginRoute,
              (route) => false,
            );
          },
          error: (error, _) {
            _showToast(error.toString(), Icons.error);
          },
          loading: () {});
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a new password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a strong password for your account.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                CustomFormfield(
                  hintText: 'New Password',
                  height: 70,
                  validateRegEx: PASSWORD_VALIDATION_REGEX,
                  obscureText: true,
                  onSaved: (value) {
                    _password = value;
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
                                  .read(resetPasswordProvider.notifier)
                                  .resetPassword(widget.resetToken, _password!);
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
                            'Reset Password',
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
