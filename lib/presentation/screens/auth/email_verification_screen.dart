import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/email_verification_provider.dart';
import '../../widgets/app_logo.dart';

/// Email verification screen shown after registration or when a login is
/// rejected because the account is not verified yet.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.authRepository,
  });

  final String email;

  /// Test seam: overrides the default repository lookup.
  final AuthRepository? authRepository;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify(EmailVerificationProvider provider) async {
    FocusScope.of(context).unfocus();
    final ok = await provider.verify(_codeController.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Email berhasil diverifikasi. Silakan masuk menggunakan akun Anda.',
            ),
            backgroundColor: AppColors.emerald600,
          ),
        );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _resend(EmailVerificationProvider provider) async {
    final ok = await provider.resend();
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Kode verifikasi telah dikirim.'),
          backgroundColor: AppColors.emerald600,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return ChangeNotifierProvider(
      create: (_) => EmailVerificationProvider(
        email: widget.email,
        auth: widget.authRepository,
      ),
      child: Builder(
        builder: (context) {
          final provider = context.watch<EmailVerificationProvider>();
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.deepGradient,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 40,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: AppLogo(size: 64)),
                            const SizedBox(height: 12),
                            Text(
                              'Verifikasi Email',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masukkan kode 6 digit yang dikirim ke',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.maskedEmail,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (provider.error != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.red50,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  border: Border.all(color: AppColors.red200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.red600,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        provider.error!,
                                        style: const TextStyle(
                                          color: AppColors.red700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) => provider.verifying
                                  ? null
                                  : _verify(provider),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 12,
                                color: colors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Kode Verifikasi',
                                counterText: '',
                                prefixIcon: Icon(Icons.pin_outlined),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.emerald600,
                                    AppColors.emerald700,
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x4D059669),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: provider.busy ||
                                        _codeController.text
                                                .trim()
                                                .length !=
                                            6
                                    ? null
                                    : () => _verify(provider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                child: provider.verifying
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('VERIFIKASI'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Belum menerima kode?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                  ),
                                ),
                                if (provider.resendCountdown > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Text(
                                      'Kirim ulang dalam '
                                      '${provider.resendCountdown} detik',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                else
                                  TextButton(
                                    onPressed: provider.resending
                                        ? null
                                        : () => _resend(provider),
                                    child: provider.resending
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : const Text('Kirim Ulang Kode'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}