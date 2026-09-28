import 'package:chatapp/pages/auth/email_verification_page.dart';
import 'package:chatapp/pages/auth/register_page.dart';
import 'package:chatapp/pages/home_page.dart';
import 'package:chatapp/components/chat_animation.dart';
import 'package:chatapp/service/auth_service.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/widget/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _translateFirebaseError(String? code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Pulse',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                              height: 1,
                              letterSpacing: 1.2,
                            ),
                          ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Giriş yap ve Pulse dünyasına katıl!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : const Color(0xFF6B6B6B),
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: const ChatAnimationWidget(),
                        ),
                        const SizedBox(height: 40),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: modernTextInputDecoration(context).copyWith(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              FluentIcons.mail_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'E-posta adresi boş olamaz.';
                            }
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Geçerli bir e-posta adresi girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: modernTextInputDecoration(context).copyWith(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              FluentIcons.lock_closed_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? FluentIcons.eye_off_24_regular
                                    : FluentIcons.eye_24_regular,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre boş olamaz.';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır.';
                            }
                            return null;
                          },
                        ),
                         Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showResetPasswordDialog,
                            child: Text(
                              'Şifremi Unuttum?',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Giriş Yap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF8B8B8B),
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(text: "Hesabın yok mu? "),
                                TextSpan(
                                  text: 'Kayıt ol',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final result = await _authService.signInWithEmailAndPasswordDetailed(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

      if (result == null) {

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          try {
            final userData = await DatabaseService().getUserByEmail(user.email!);
            if (userData != null) {
              await HelperFunction.saveUserLoggedInStatus(true);
              await HelperFunction.saveUserEmailSF(user.email!);
              await HelperFunction.saveUserNameSF(userData['fullName'] ?? '');
            }
          } catch (e) {
            debugPrint("Kullanıcı verisi çekilirken hata: $e");
          }
        }

        if (user != null && !user.emailVerified) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translateFirebaseError(result)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(FluentIcons.key_reset_24_filled, size: 40, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Şifre Sıfırlama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF24354E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kayıtlı e-posta adresinizi girin. Size bir şifre sıfırlama bağlantısı göndereceğiz.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: modernTextInputDecoration(context).copyWith(
                        labelText: 'E-posta',
                        prefixIcon: Icon(FluentIcons.mail_24_regular, color: Theme.of(context).colorScheme.primary, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'E-posta boş olamaz.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('İptal', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSending
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ?? false) {
                                      setModalState(() => isSending = true);
                                      final messenger = ScaffoldMessenger.of(context);
                                      final result = await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                                      if (!ctx.mounted) return;

                                      Navigator.pop(ctx);
                                      if (result == null) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Şifre sıfırlama bağlantısı gönderildi.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(_translateFirebaseError(result)),
                                            backgroundColor: Colors.red[700],
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSending
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
