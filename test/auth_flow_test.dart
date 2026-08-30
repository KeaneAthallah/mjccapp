import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mjcc/core/errors/app_exception.dart';
import 'package:mjcc/core/theme/app_theme.dart';
import 'package:mjcc/data/models/user_model.dart';
import 'package:mjcc/data/repositories/auth_repository.dart';
import 'package:mjcc/presentation/providers/auth_provider.dart';
import 'package:mjcc/presentation/providers/register_provider.dart';
import 'package:mjcc/presentation/providers/theme_provider.dart';
import 'package:mjcc/presentation/screens/auth/email_verification_screen.dart';
import 'package:mjcc/presentation/screens/auth/login_screen.dart';
import 'package:mjcc/presentation/screens/auth/register_screen.dart';

class FakeAuthRepository extends AuthRepository {
  bool unverified = false;
  bool registerFails = false;
  String? registeredName;
  String? registeredEmail;
  String? verifiedEmail;
  String? verifiedCode;
  String? resentEmail;

  @override
  Future<UserModel> login(String email, String password) async {
    if (unverified) {
      throw const EmailNotVerifiedException('Email Anda belum diverifikasi.');
    }
    return UserModel.fromJson(
      {'id': 1, 'name': 'Budi', 'email': email, 'role': 'viewer'},
    );
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    registeredName = name;
    registeredEmail = email;
    if (registerFails) {
      throw const ValidationException('Email terdaftar.', errors: {
        'email': ['Email sudah digunakan.'],
      });
    }
  }

  @override
  Future<void> verifyEmail({required String email, required String code}) async {
    verifiedEmail = email;
    verifiedCode = code;
    if (code == '999999') {
      throw const AppException('Kode verifikasi tidak valid.');
    }
  }

  @override
  Future<void> resendVerification({required String email}) async {
    resentEmail = email;
  }
}

Future<void> pumpAuth(
  WidgetTester tester, {
  required Widget home,
  FakeAuthRepository? auth,
}) async {
  final repo = auth ?? FakeAuthRepository();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(auth: repo)),
        ChangeNotifierProvider(create: (_) => RegisterProvider(auth: repo)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login screen links to the registration screen', (tester) async {
    await pumpAuth(tester, home: const LoginScreen());

    expect(find.text('Belum punya akun?'), findsOneWidget);

    await tester.ensureVisible(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('login routes to email verification when required',
      (tester) async {
    final repo = FakeAuthRepository()..unverified = true;
    await pumpAuth(tester, home: const LoginScreen(), auth: repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'budi@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(EmailVerificationScreen), findsOneWidget);
    expect(find.text('Verifikasi Email'), findsOneWidget);
  });

  testWidgets('register screen validates empty fields', (tester) async {
    await pumpAuth(tester, home: const RegisterScreen());

    await tester.enterText(find.byType(TextFormField).at(3), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('register screen rejects an invalid email and short password',
      (tester) async {
    await pumpAuth(tester, home: const RegisterScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'Budi');
    await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.enterText(find.byType(TextFormField).at(3), 'short');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Email tidak valid'), findsOneWidget);
    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);
  });

  testWidgets('register screen submits and opens email verification',
      (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuth(tester, home: const RegisterScreen(), auth: repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Budi Santoso');
    await tester.enterText(find.byType(TextFormField).at(1), 'budi@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.registeredName, 'Budi Santoso');
    expect(repo.registeredEmail, 'budi@example.com');
    expect(find.byType(EmailVerificationScreen), findsOneWidget);
  });

  testWidgets('register screen shows backend field errors', (tester) async {
    final repo = FakeAuthRepository()..registerFails = true;
    await pumpAuth(tester, home: const RegisterScreen(), auth: repo);

    await tester.enterText(find.byType(TextFormField).at(0), 'Budi Santoso');
    await tester.enterText(find.byType(TextFormField).at(1), 'budi@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Email sudah digunakan.'), findsWidgets);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('register screen requires matching password confirmation',
      (tester) async {
    await pumpAuth(tester, home: const RegisterScreen());

    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia124');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
  });

  testWidgets('verification screen shows the masked email and enables the '
      'button only with six digits', (tester) async {
    await pumpAuth(
      tester,
      home: EmailVerificationScreen(
        email: 'budi@example.com',
        authRepository: FakeAuthRepository(),
      ),
    );

    expect(find.text('b***@example.com'), findsOneWidget);

    ElevatedButton button() => tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('VERIFIKASI'),
            matching: find.byType(ElevatedButton),
          ),
        );

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('verification screen verifies a code and confirms success',
      (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuth(
      tester,
      home: EmailVerificationScreen(
        email: 'budi@example.com',
        authRepository: repo,
      ),
    );

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.ensureVisible(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();

    expect(repo.verifiedEmail, 'budi@example.com');
    expect(repo.verifiedCode, '123456');
    expect(
      find.text('Email berhasil diverifikasi. Silakan masuk menggunakan akun '
          'Anda.'),
      findsOneWidget,
    );
  });

  testWidgets('verification screen shows the backend error for a bad code',
      (tester) async {
    await pumpAuth(
      tester,
      home: EmailVerificationScreen(
        email: 'budi@example.com',
        authRepository: FakeAuthRepository(),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '999999');
    await tester.ensureVisible(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();

    expect(find.text('Kode verifikasi tidak valid.'), findsOneWidget);
  });

  testWidgets('verification screen blocks resend during the countdown then '
      'resends after it expires', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuth(
      tester,
      home: EmailVerificationScreen(
        email: 'budi@example.com',
        authRepository: repo,
      ),
    );

    expect(find.textContaining('Kirim ulang dalam'), findsOneWidget);
    expect(find.text('Kirim Ulang Kode'), findsNothing);

    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kirim ulang dalam'), findsNothing);

    await tester.ensureVisible(find.text('Kirim Ulang Kode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim Ulang Kode'));
    await tester.pumpAndSettle();

    expect(repo.resentEmail, 'budi@example.com');
    expect(find.text('Kode verifikasi telah dikirim.'), findsOneWidget);
  });
}