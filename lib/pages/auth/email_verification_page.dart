import 'dart:async';
import 'package:chatapp/pages/home_page.dart';
import 'package:chatapp/pages/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = false;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 30)); 
      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('E-posta Doğrulama'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  FluentIcons.mail_read_24_filled,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms, curve: Curves.easeInOut)
                  .then().scaleXY(begin: 1.05, end: 0.95, duration: 1500.ms, curve: Curves.easeInOut),
              const SizedBox(height: 32),
              Text(
                'Lütfen e-postanızı onaylayın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kayıt olduğunuz adrese bir onay bağlantısı gönderdik. Lütfen gelen kutunuzu (ve gerekiyorsa spam klasörünü) kontrol edin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF8B8B8B),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!canResendEmail) {
                      setState(() => canResendEmail = true); 
                    }
                    sendVerificationEmail();
                  },
                  icon: const Icon(FluentIcons.mail_arrow_up_24_filled),
                  label: const Text('Tekrar Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('İptal et ve Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
