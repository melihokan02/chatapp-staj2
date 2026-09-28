import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/auth/login_page.dart';
import 'package:chatapp/pages/main_pages/page_components.dart';
import 'package:chatapp/providers/app_provider.dart';
import 'package:chatapp/service/auth_service.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  bool _notificationsEnabled = true;
  bool _showOnlineStatus = true;

  String? _userName;
  String? _userEmail;
  String? _usernameId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await HelperFunction.getUserNameSF();
    final email = await HelperFunction.getUserEmailSF();
    final notifs = await HelperFunction.getNotificationsEnabled();
    final online = await HelperFunction.getShowOnlineStatus();

    String? username;
    if (email != null) {
      final userData = await _databaseService.getUserByEmail(email);
      if (userData != null) {
        username = userData['username'];
      }
    }

    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
      _notificationsEnabled = notifs;
      _showOnlineStatus = online;
      _usernameId = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppProvider>().themeMode;
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isSystemDark);

    return FeaturePageScaffold(
      title: 'Ayarlar',
      subtitle: 'Profil, güvenlik ve uygulama tercihlerini yönet.',
      icon: Icons.settings_outlined,
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2D5F8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [

              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A11CB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 32),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'Kullanıcı',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF24354E),
                      ),
                    ),
                    if (_usernameId != null && _usernameId!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$_usernameId',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _userEmail ?? 'email@example.com',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8B8B8B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFF6A11CB)),
                onPressed: _editName,
                tooltip: 'İsim değiştir',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tercihler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24354E),
          ),
        ),
        const SizedBox(height: 12),

        _SettingSwitchTile(
          title: 'Bildirimler',
          subtitle: 'Yeni mesajlar ve grup aktiviteleri için bildirim al.',
          value: _notificationsEnabled,
          icon: Icons.notifications_none_outlined,
          onChanged: (val) {
            setState(() => _notificationsEnabled = val);
            HelperFunction.saveNotificationsEnabled(val);
          },
        ),
        const SizedBox(height: 12),

        _SettingSwitchTile(
          title: 'Çevrimiçi durumu',
          subtitle: 'Aktiflik durumunu diğer kullanıcılara göster.',
          value: _showOnlineStatus,
          icon: Icons.visibility_outlined,
          onChanged: (val) {
            setState(() => _showOnlineStatus = val);
            HelperFunction.saveShowOnlineStatus(val);
            if (_userEmail != null) {
              _databaseService.setUserOnlineStatus(_userEmail!, val);
            }
          },
        ),
        const SizedBox(height: 12),

        _SettingSwitchTile(
          title: 'Karanlık Mod',
          subtitle: 'Uygulamayı koyu temada kullan.',
          value: isDark,
          icon: Icons.dark_mode_outlined,
          onChanged: (value) {
            context.read<AppProvider>().setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
          },
        ),
        const SizedBox(height: 12),
        FeatureCard(
          title: 'Sohbet geçmişi',
          subtitle: 'Eski mesajları ve arşivleri yönet.',
          leadingIcon: Icons.history_rounded,
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Color(0xFF8B8B8B)),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        FeatureCard(
          title: 'Gizlilik ve güvenlik',
          subtitle: 'Hesap, görünürlük ve güvenlik tercihleri.',
          leadingIcon: Icons.lock_outline,
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Color(0xFF8B8B8B)),
          onTap: () {},
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A11CB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Çıkış Yap',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Profil fotoğrafı yükleme şu an devre dışı.\nFazlasını görmek için Firebase Blaze planına geçin.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF24354E),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _userName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İsim Değiştir'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == _userName) return;

    final userEmail = _userEmail;
    if (userEmail == null) return;

    await _databaseService.updateUserName(userEmail, newName);
    await HelperFunction.saveUserNameSF(newName);

    if (!mounted) return;
    setState(() => _userName = newName);
    if (mounted) {
      context.read<AppProvider>().setUser(userEmail, newName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('İsim güncellendi!'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
    await HelperFunction.clearUserData();

    if (!mounted) return;
    context.read<AppProvider>().clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2D5F8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1528) : const Color(0xFFF4F0FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF6A11CB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF24354E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Color(0xFF8B8B8B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF6A11CB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
