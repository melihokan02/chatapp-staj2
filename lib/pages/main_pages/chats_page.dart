import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/main_pages/chat_conversation_page.dart';
import 'package:chatapp/pages/main_pages/page_components.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserEmail;
  String? _currentUserName;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeaturePageScaffold(
      title: 'Sohbet',
      subtitle: 'Mesajların, son konuşmaların ve yeni sohbetler burada.',
      icon: Icons.chat_bubble_outline,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickUserForNewChat,
        backgroundColor: const Color(0xFFE46D4E),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Yeni Sohbet', style: TextStyle(color: Colors.white)),
      ),
      children: [
        TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Sohbet ara',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
            prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.grey[500] : Colors.grey[600]),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2D7CE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2D7CE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE46D4E), width: 1.2),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Text(
          'Son Sohbetler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24354E),
          ),
        ),
        const SizedBox(height: 12),
        _buildChatsList(),
      ],
    );
  }

  Widget _buildChatsList() {
    final currentUserEmail = _currentUserEmail;
    if (currentUserEmail == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getUserChatRooms(currentUserEmail),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Sohbetler yüklenemedi'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final query = _searchController.text.trim().toLowerCase();

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roomName =
              (data['chatRoomName'] as String? ?? '').toLowerCase();
          final lastMessage =
              (data['lastMessage'] as String? ?? '').toLowerCase();
          return query.isEmpty ||
              roomName.contains(query) ||
              lastMessage.contains(query);
        }).toList();

        filteredDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['updatedAt']
              as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['updatedAt']
              as Timestamp?;
          final aMillis = aTime?.millisecondsSinceEpoch ?? 0;
          final bMillis = bTime?.millisecondsSinceEpoch ?? 0;
          return bMillis.compareTo(aMillis);
        });

        if (filteredDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Henüz sohbet yok. Yeni sohbet başlat.'),
          );
        }

        return Column(
          children: filteredDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final roomId = doc.id;
            final roomName = data['chatRoomName'] as String? ?? 'Sohbet';
            final lastMessage =
                data['lastMessage'] as String? ?? 'Mesaj yok';
            final lastSender = data['lastMessageSender'] as String? ?? '';
            final members =
                (data['users'] as List<dynamic>? ?? []).cast<String>();
            final peerEmail = members.firstWhere(
              (email) => email != currentUserEmail,
              orElse: () => roomName,
            );
            final avatarLabel = _avatarLabel(roomName);
            final updatedAt = data['updatedAt'] as Timestamp?;
            final timeText = updatedAt == null
                ? ''
                : TimeOfDay.fromDateTime(updatedAt.toDate()).format(context);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                title: roomName,
                subtitle: lastSender.isEmpty
                    ? lastMessage
                    : '$lastSender: $lastMessage',
                leadingIcon: Icons.person_outline,
                badge: null,
                trailing: Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B8B8B),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatConversationPage(
                        chatId: roomId,
                        title: roomName,
                        subtitle: peerEmail,
                        avatarLabel: avatarLabel,
                        isGroupChat: false,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Kullanıcı listesinden seçerek yeni sohbet başlat.
  Future<void> _pickUserForNewChat() async {
    final currentUserEmail = _currentUserEmail;
    final currentUserName = _currentUserName ?? 'Me';
    if (currentUserEmail == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => _UserPickerSheet(
          scrollController: scrollCtrl,
          currentUserEmail: currentUserEmail,
          currentUserName: currentUserName,
          databaseService: _databaseService,
          onUserSelected: (otherEmail, otherName) async {
            Navigator.pop(ctx);
            // Yükleniyor dialogu
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
            try {
              final chatRoomId = await _databaseService.createOrGetDirectChatRoom(
                currentUserEmail: currentUserEmail,
                currentUserName: currentUserName,
                otherUserEmail: otherEmail,
                otherUserName: otherName,
              );
              if (!mounted) return;
              Navigator.pop(context); // loading dialogunu kapat
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatConversationPage(
                    chatId: chatRoomId,
                    title: otherName.isNotEmpty ? otherName : otherEmail,
                    subtitle: otherEmail,
                    avatarLabel: _avatarLabel(otherName.isNotEmpty ? otherName : otherEmail),
                    isGroupChat: false,
                  ),
                ),
              );
            } catch (e) {
              if (mounted) {
                Navigator.pop(context); // loading dialogunu kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sohbet başlatılamadı: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _avatarLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }
}

/// Kullanıcı seçme bottom sheet
class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet({
    required this.scrollController,
    required this.currentUserEmail,
    required this.currentUserName,
    required this.databaseService,
    required this.onUserSelected,
  });

  final ScrollController scrollController;
  final String currentUserEmail;
  final String currentUserName;
  final DatabaseService databaseService;
  final Function(String email, String name) onUserSelected;

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Text(
            'Sohbet Başlat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF24354E),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'İsim veya e-posta ara',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF9F3F0),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.databaseService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final query = _searchCtrl.text.trim().toLowerCase();

              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final email =
                    (data['email'] as String? ?? '').toLowerCase();
                final name =
                    (data['fullName'] as String? ?? '').toLowerCase();
                if (email ==
                    widget.currentUserEmail.toLowerCase()) {
                  return false;
                }
                return query.isEmpty ||
                    email.contains(query) ||
                    name.contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                    child: Text('Kullanıcı bulunamadı.'));
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final data =
                      filtered[i].data() as Map<String, dynamic>;
                  final name =
                      data['fullName'] as String? ?? 'Kullanıcı';
                  final email = data['email'] as String? ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE2D8),
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFFE46D4E),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(email,
                        style: const TextStyle(fontSize: 12)),
                    onTap: () =>
                        widget.onUserSelected(email, name),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
