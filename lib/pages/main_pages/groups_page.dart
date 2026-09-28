import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/main_pages/chat_conversation_page.dart';
import 'package:chatapp/pages/main_pages/page_components.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _groupNameController = TextEditingController();
  String? _currentUserEmail;
  String? _currentUserName;

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
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeaturePageScaffold(
      title: 'Gruplar',
      subtitle: 'Topluluklar oluştur, üye ekle ve birlikte sohbet et.',
      icon: Icons.groups_outlined,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        backgroundColor: const Color(0xFF6A11CB),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Yeni Grup', style: TextStyle(color: Colors.white)),
      ),
      children: [
        Text(
          'Aktif Gruplar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24354E),
          ),
        ),
        const SizedBox(height: 12),
        _buildGroupsList(),
      ],
    );
  }

  Widget _buildGroupsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_currentUserEmail == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getGroupsStream(_currentUserEmail!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Gruplar yüklenemedi'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Henüz grup yok. Yeni bir grup oluştur.'),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final groupName = data['groupName'] as String? ?? 'Grup';
            final memberCount = (data['memberCount'] as int?) ?? 1;
            final lastMessage = data['lastMessage'] as String? ?? '';
            final updatedAt = data['updatedAt'] as Timestamp?;
            final timeText = updatedAt == null
                ? ''
                : TimeOfDay.fromDateTime(updatedAt.toDate()).format(context);
            final members =
                (data['members'] as List<dynamic>? ?? []).cast<String>();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureCard(
                title: groupName,
                subtitle: lastMessage.isEmpty
                    ? '$memberCount üye'
                    : '$memberCount üye · $lastMessage',
                leadingIcon: Icons.groups,
                badge: null,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B8B8B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    GestureDetector(
                      onTap: () => _showGroupOptions(doc.id, groupName,
                          members, data['creatorEmail'] as String? ?? ''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E0F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Yönet',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF6A11CB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatConversationPage(
                        chatId: doc.id,
                        title: groupName,
                        subtitle: '$memberCount üye',
                        avatarLabel: _avatarLabel(groupName),
                        isGroupChat: true,
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

  void _showGroupOptions(String groupId, String groupName,
      List<String> members, String creatorEmail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF24354E),
                      ),
                    ),
                  ),
                  _currentUserEmail == creatorEmail
                      ? TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addMemberDialog(groupId);
                          },
                          icon: const Icon(Icons.person_add_outlined, color: Color(0xFF6A11CB)),
                          label: const Text('Üye Ekle', style: TextStyle(color: Color(0xFF6A11CB))),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final memberEmail = members[i];
                  final isCreator = memberEmail == creatorEmail;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE9E0F8),
                      child: Text(
                        memberEmail.isNotEmpty
                            ? memberEmail[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Color(0xFF6A11CB)),
                      ),
                    ),
                    title: Text(memberEmail),
                    subtitle: isCreator
                        ? const Text('Kurucu',
                            style: TextStyle(color: Color(0xFF6A11CB)))
                        : null,
                    trailing: (_currentUserEmail == creatorEmail && !isCreator)
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _databaseService.removeMemberFromGroup(
                                groupId: groupId,
                                memberEmail: memberEmail,
                              );
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMemberDialog(String groupId) async {
    final usernameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üye Ekle'),
        content: TextField(
          controller: usernameCtrl,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı adı (@olmadan)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ekle')),
        ],
      ),
    );

    if (confirmed != true) return;
    final targetUsername = usernameCtrl.text.trim();
    if (targetUsername.isEmpty) return;

    final userData = await _databaseService.getUserByUsername(targetUsername);
    if (!mounted) return;
    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bulunamadı.')),
      );
      return;
    }

    final targetEmail = userData['email'] as String;

    await _databaseService.addMemberToGroup(
      groupId: groupId,
      memberEmail: targetEmail,
      memberName: targetUsername,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('@$targetUsername gruba eklendi!'),
          backgroundColor: Colors.green),
    );
  }

  Future<void> _createGroup() async {
    _groupNameController.clear();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Grup Oluştur'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Grup Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oluştur')),
        ],
      ),
    );

    if (result != true) return;

    final groupName = _groupNameController.text.trim();
    final currentUserEmail = _currentUserEmail;
    final currentUserName = _currentUserName ?? 'Me';

    if (groupName.isEmpty || currentUserEmail == null) return;

    await _databaseService.createGroup(
      groupName: groupName,
      creatorEmail: currentUserEmail,
      creatorName: currentUserName,
    );

    _groupNameController.clear();
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
