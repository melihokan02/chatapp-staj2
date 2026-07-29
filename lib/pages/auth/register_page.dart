import 'package:chatapp/pages/auth/email_verification_page.dart';
import 'package:chatapp/widget/widgets.dart';
import 'package:chatapp/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  AuthService authService = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _translateFirebaseError(String? code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'operation-not-allowed':
        return 'E-posta/şifre girişi etkin değil.';
      default:
        return 'Kayıt başarısız. Lütfen tekrar deneyin.';
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
                            'Groupie',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                              height: 1,
                            ),
                          ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Hesap oluştur ve sohbete katıl',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : const Color(0xFF8B8B8B),
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Icon(
                              FluentIcons.person_add_24_filled,
                              size: 100,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.easeOutBack),
                        ),
                        const SizedBox(height: 30),
                        // Ad Soyad
                        TextFormField(
                          controller: _fullNameController,
                          keyboardType: TextInputType.name,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: modernTextInputDecoration(context).copyWith(
                            labelText: 'Ad Soyad',
                            prefixIcon: Icon(
                              FluentIcons.person_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ad Soyad boş olamaz.';
                            }
                            if (value.trim().length < 2) {
                              return 'En az 2 karakter girin.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Email
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
                        // Şifre
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: modernTextInputDecoration(context).copyWith(
                            labelText: 'Şifre',
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
                            if (value.length < 8) {
                              return 'Şifre en az 8 karakter olmalıdır.';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Şifre en az 1 büyük harf içermelidir.';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Şifre en az 1 küçük harf içermelidir.';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Şifre en az 1 rakam içermelidir.';
                            }
                            if (!RegExp(r'[!@#\$&*~%^()+={}\[\]|;:"<>,.?/_\-]').hasMatch(value)) {
                              return 'Şifre en az 1 özel karakter içermelidir.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Şifre tekrar
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: modernTextInputDecoration(context).copyWith(
                            labelText: 'Şifre Tekrar',
                            prefixIcon: Icon(
                              FluentIcons.lock_closed_24_regular,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? FluentIcons.eye_off_24_regular
                                    : FluentIcons.eye_24_regular,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre tekrarı boş olamaz.';
                            }
                            if (value != _passwordController.text) {
                              return 'Şifreler uyuşmuyor.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _register,
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
                              'Kayıt Ol',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: isDark ? Colors.white60 : const Color(0xFF8B8B8B),
                                fontSize: 13,
                              ),
                              children: [
                                const TextSpan(text: "Zaten hesabın var mı? "),
                                TextSpan(
                                  text: 'Giriş yap',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pop(context);
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final result = await authService.registerWithEmailAndPasswordDetailed(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Lütfen e-postanızı doğrulayın.'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translateFirebaseError(result)),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}
