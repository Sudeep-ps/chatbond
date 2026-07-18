import 'dart:io';

import 'package:chatbond/core/constants/app_constants.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatbond/features/profile/presentation/providers/profile_provider.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.purpose,
    this.email,
    this.pendingImage,
    this.pendingName,
  });

  final String purpose;
  final String? email;

  // Only used when purpose == 'signup': the profile picture/name picked on
  // the register page, carried here since signup() has no uid yet — the
  // profile can only be created once verifyOtp() returns a real uid.
  final File? pendingImage;
  final String? pendingName;

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  String _otp = '';
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
  void initState() {
    super.initState();
    _email = widget.email;
  }

  Future<void> _uploadProfileAndCreateUser(String uid) async {
    final image = widget.pendingImage;
    if (image == null) return;

    await ref
        .read(uploadProfilePictureProvider.notifier)
        .uploadProfilePicture(image, uid);

    final uploadState = ref.read(uploadProfilePictureProvider);
    uploadState.whenData((url) {
      if (url != null) {
        final userProfile = UserProfileEntity(
          uid: uid,
          name: widget.pendingName ?? '',
          pfpURL: url,
        );
        ref.read(createUserProfileProvider.notifier).createProfile(userProfile);
      } else {
        _showToast('Failed to upload profile picture', Icons.error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(verifyOtpProvider);
    final resendState = ref.watch(resendOtpProvider);

    ref.listen(resendOtpProvider, (previous, state) {
      state.when(
          data: (_) {
            if (previous is AsyncLoading || previous?.isLoading == true) {
              _showToast('Code resent. Check your email.', Icons.check);
            }
          },
          error: (error, _) {
            _showToast(error.toString(), Icons.error);
          },
          loading: () {});
    });

    ref.listen(verifyOtpProvider, (previous, state) {
      state.when(
          data: (result) {
            if (widget.purpose == 'RESET_PASSWORD') {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.resetPasswordRoute,
                (route) => false,
                arguments: {'resetToken': result?.resetToken ?? ''},
              );
              return;
            }

            final authUser = result?.user;

            // Signup flow
            if (authUser != null) {
              if (widget.pendingImage != null) {
                _uploadProfileAndCreateUser(authUser.uid);
              } else {
                _showToast('Email verified. Please sign in.', Icons.check);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppConstants.loginRoute,
                  (route) => false,
                );
              }
            }
          },
          error: (error, _) {
            _showToast(error.toString(), Icons.error);
          },
          loading: () {});
    });

    ref.listen(createUserProfileProvider, (previous, state) {
      state.when(
          data: (_) {
            ref.invalidate(authRemoteDataSourceProvider);
            ref.invalidate(chatRemoteDataSourceProvider);
            _showToast('Account created and verified!', Icons.check);
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppConstants.homeRoute,
              (route) => false,
            );
          },
          error: (error, _) {
            _showToast(
                'Verified, but profile setup failed: $error', Icons.error);
          },
          loading: () {});
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.purpose == 'RESET_PASSWORD'
                      ? 'Reset your password'
                      : 'Verify your email',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.purpose == 'RESET_PASSWORD'
                      ? 'Enter the 6-digit code sent to your email.'
                      : 'Enter the 6-digit code we sent to ${_email ?? 'your email'}.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '6-digit code',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length != 6) {
                      return 'Enter a valid 6-digit code';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _otp = value?.trim() ?? '';
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    onPressed: verifyState.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _formKey.currentState?.save();
                              ref.read(verifyOtpProvider.notifier).verifyOtp(
                                    _email ?? '',
                                    _otp,
                                    widget.purpose,
                                  );
                            }
                          },
                    color: Theme.of(context).colorScheme.primary,
                    child: verifyState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: resendState.isLoading
                        ? null
                        : () {
                            ref
                                .read(resendOtpProvider.notifier)
                                .resendOtp(_email ?? '', widget.purpose);
                          },
                    child: resendState.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Didn't get a code? Resend"),
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
