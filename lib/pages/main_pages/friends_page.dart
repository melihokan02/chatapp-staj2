import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/main_pages/chat_conversation_page.dart';
import 'package:chatapp/pages/main_pages/page_components.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:chatapp/widget/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserEmail;
  String? _currentUserName;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userEmail = await HelperFunction.getUserEmailSF();
    final userName = await HelperFunction.getUserNameSF();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userEmail;
      _currentUserName = userName;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF1A1513), const Color(0xFF121212)]
                : [const Color(0xFFFFF8F5), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  children: [
                    const _FriendHeader(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'İsim veya e-posta ara',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2D7CE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2D7CE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFFE46D4E), width: 1.2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFFE46D4E),
                      unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF8B8B8B),
                      indicatorColor: const Color(0xFFE46D4E),
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Arkadaşlar'),
                        Tab(text: 'İstekler'),
                        Tab(text: 'Keşfet'),
                      ],
                    ),
                  ],
                ),
              ),
              // Tab içerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(),
                    _buildRequestsTab(),
                    _buildDiscoverTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sendFriendRequest,
        backgroundColor: const Color(0xFFE46D4E),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Arkadaş Ekle'),
      ),
    );
  }

  // ── Mevcut arkadaşlar sekmesi ──
  Widget _buildFriendsTab() {
    final currentEmail = _currentUserEmail;
    if (currentEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getFriendsStream(currentEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Arkadaşlar yüklenemedi.'));
        }

        final docs = snapshot.data?.docs ?? [];
        final friends = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'accepted';
        }).toList();

        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? friends
            : friends.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final names =
                    Map<String, String>.from(data['names'] as Map);
                final peerEmail = (data['users'] as List)
                    .cast<String>()
                    .firstWhere((e) => e != currentEmail,
                        orElse: () => '');
                final peerName = names[peerEmail] ?? '';
                return peerEmail.contains(query) ||
                    peerName.toLowerCase().contains(query);
              }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz arkadaşın yok.\n"Keşfet" sekmesinden yeni arkadaşlar ekle!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B8B8B)),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final names = Map<String, String>.from(data['names'] as Map);
            final peerEmail = (data['users'] as List)
                .cast<String>()
                .firstWhere((e) => e != currentEmail, orElse: () => '');
            final peerName = names[peerEmail] ?? peerEmail;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                title: peerName,
                subtitle: peerEmail,
                leadingIcon: Icons.account_circle_outlined,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFFE46D4E), size: 20),
                      onPressed: () =>
                          _openDirectChat(peerEmail, peerName),
                      tooltip: 'Mesaj gönder',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_remove_outlined,
                          color: Colors.red, size: 20),
                      onPressed: () =>
                          _confirmRemoveFriend(peerEmail, peerName),
                      tooltip: 'Arkadaşlıktan çıkar',
                    ),
                  ],
                ),
                onTap: () => _openDirectChat(peerEmail, peerName),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Gelen istekler sekmesi ──
  Widget _buildRequestsTab() {
    final currentEmail = _currentUserEmail;
    if (currentEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getFriendsStream(currentEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final pending = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending' &&
              data['requestedBy'] != currentEmail;
        }).toList();

        if (pending.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bekleyen arkadaşlık isteğin yok.',
                style: TextStyle(color: Color(0xFF8B8B8B)),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: pending.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final names = Map<String, String>.from(data['names'] as Map);
            final senderEmail = data['requestedBy'] as String;
            final senderName = names[senderEmail] ?? senderEmail;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF2D7CE)),
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
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          senderName.isNotEmpty
                              ? senderName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE46D4E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(senderName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF24354E))),
                          Text(senderEmail,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B8B8B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green),
                      onPressed: () => _acceptRequest(
                          senderEmail, currentEmail),
                      tooltip: 'Kabul et',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          _databaseService.removeFriend(
                              senderEmail, currentEmail),
                      tooltip: 'Reddet',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Keşfet sekmesi — tüm kullanıcılar ──
  Widget _buildDiscoverTab() {
    final currentEmail = _currentUserEmail;
    if (currentEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final query = _searchController.text.trim().toLowerCase();

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = (data['email'] as String? ?? '').toLowerCase();
          final name = (data['fullName'] as String? ?? '').toLowerCase();
          if (email == currentEmail.toLowerCase()) return false;
          return query.isEmpty ||
              email.contains(query) ||
              name.contains(query);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
              child: Text('Kullanıcı bulunamadı.',
                  style: TextStyle(color: Color(0xFF8B8B8B))));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _databaseService.getFriendsStream(currentEmail),
          builder: (context, friendsSnapshot) {
            final friendDocs = friendsSnapshot.data?.docs ?? [];
            final Set<String> pendingOrFriends = {};
            for (final doc in friendDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final users =
                  (data['users'] as List).cast<String>();
              for (final u in users) {
                if (u != currentEmail) pendingOrFriends.add(u);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(18),
              children: filtered.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fullName =
                    data['fullName'] as String? ?? 'Kullanıcı';
                final email = data['email'] as String? ?? '';
                final isAlreadyFriend =
                    pendingOrFriends.contains(email);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FeatureCard(
                    title: fullName,
                    subtitle: email,
                    leadingIcon: Icons.account_circle_outlined,
                    trailing: isAlreadyFriend
                        ? const Icon(Icons.check,
                            color: Colors.green, size: 20)
                        : IconButton(
                            icon: const Icon(
                                Icons.person_add_outlined,
                                color: Color(0xFFE46D4E),
                                size: 20),
                            onPressed: () =>
                                _quickSendRequest(email, fullName),
                            tooltip: 'İstek gönder',
                          ),
                    onTap: null,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ── Arkadaşlık isteği gönder (dialog) ──
  Future<void> _sendFriendRequest() async {
    final emailCtrl = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(FluentIcons.person_add_24_filled, size: 40, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Arkadaşlık İsteği Gönder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF24354E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: modernTextInputDecoration(context).copyWith(
                  labelText: 'E-posta adresi',
                  prefixIcon: const Icon(FluentIcons.mail_24_regular),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
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
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final toEmail = emailCtrl.text.trim();
    final currentEmail = _currentUserEmail;
    final currentName = _currentUserName ?? 'Kullanıcı';

    if (currentEmail == null || toEmail.isEmpty || toEmail == currentEmail) {
      return;
    }

    final userData = await _databaseService.getUserByEmail(toEmail);
    if (!mounted) return;
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bulunamadı.')),
      );
      return;
    }

    await _databaseService.sendFriendRequest(
      fromEmail: currentEmail,
      fromName: currentName,
      toEmail: toEmail,
      toName: userData['fullName'] as String? ?? toEmail,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Arkadaşlık isteği gönderildi!'),
          backgroundColor: Colors.green),
    );
  }

  // ── Keşfet'ten hızlı istek gönder ──
  Future<void> _quickSendRequest(String toEmail, String toName) async {
    final currentEmail = _currentUserEmail;
    final currentName = _currentUserName ?? 'Kullanıcı';
    if (currentEmail == null) return;

    await _databaseService.sendFriendRequest(
      fromEmail: currentEmail,
      fromName: currentName,
      toEmail: toEmail,
      toName: toName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$toName\'e istek gönderildi!'),
          backgroundColor: Colors.green),
    );
  }

  // ── İsteği kabul et ──
  Future<void> _acceptRequest(String senderEmail, String currentEmail) async {
    await _databaseService.acceptFriendRequest(senderEmail, currentEmail);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Arkadaşlık isteği kabul edildi!'),
          backgroundColor: Colors.green),
    );
  }

  // ── Arkadaşlıktan çıkar (onay dialog) ──
  Future<void> _confirmRemoveFriend(
      String peerEmail, String peerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arkadaşlıktan Çıkar'),
        content: Text(
            '$peerName kişisini arkadaş listenden çıkarmak istiyor musun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Çıkar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _databaseService.removeFriend(
        _currentUserEmail!, peerEmail);
  }

  // ── Direkt sohbet aç ──
  Future<void> _openDirectChat(
      String otherUserEmail, String otherUserName) async {
    final currentEmail = _currentUserEmail;
    final currentName = _currentUserName ?? 'Me';
    if (currentEmail == null) return;

    final chatRoomId = await _databaseService.createOrGetDirectChatRoom(
      currentUserEmail: currentEmail,
      currentUserName: currentName,
      otherUserEmail: otherUserEmail,
      otherUserName: otherUserName,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          chatId: chatRoomId,
          title: otherUserName.isNotEmpty ? otherUserName : otherUserEmail,
          subtitle: otherUserEmail,
          avatarLabel: _avatarLabel(
              otherUserName.isNotEmpty ? otherUserName : otherUserEmail),
          isGroupChat: false,
        ),
      ),
    );
  }

  String _avatarLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first[0].toUpperCase();
    final second = parts.length > 1 ? parts.last[0].toUpperCase() : '';
    return '$first$second';
  }
}

// ─── Başlık widget'ı ───
class _FriendHeader extends StatelessWidget {
  const _FriendHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A1C18) : const Color(0xFFFFE2D8),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.people_outline,
              size: 36, color: Color(0xFFE46D4E)),
        ),
        const SizedBox(height: 16),
        Text(
          'Arkadaşlar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24354E),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kullanıcıları keşfet, istek gönder ve sohbet başlat.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8B8B8B)),
        ),
      ],
    );
  }
}
