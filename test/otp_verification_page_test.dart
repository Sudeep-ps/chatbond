import 'package:chatbond/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Otp verification page renders purpose-specific copy',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OtpVerificationPage(
          purpose: 'signup',
          email: 'user@example.com',
        ),
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('Enter the 6-digit code'), findsOneWidget);
  });
}
