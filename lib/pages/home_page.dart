import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/main_pages/friends_page.dart';
import 'package:chatapp/pages/main_pages/groups_page.dart';
import 'package:chatapp/pages/main_pages/settings_page.dart';
import 'package:chatapp/pages/main_pages/chats_page.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _currentUserEmail;
  final DatabaseService _databaseService = DatabaseService();

  final List<Widget> _pages = const [
    ChatsPage(),
    GroupsPage(),
    FriendsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final email = await HelperFunction.getUserEmailSF();
    if (mounted) setState(() => _currentUserEmail = email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: _currentUserEmail == null 
            ? _buildBottomNav(0) 
            : StreamBuilder<QuerySnapshot>(
                stream: _databaseService.getFriendsStream(_currentUserEmail!),
                builder: (context, snapshot) {
                  int pendingCount = 0;
                  if (snapshot.hasData) {
                    pendingCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'pending' && data['to'] == _currentUserEmail;
                    }).length;
                  }
                  return _buildBottomNav(pendingCount);
                },
              ),
      ),
    );
  }

  Widget _buildBottomNav(int friendRequestsCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? FluentIcons.chat_24_filled : FluentIcons.chat_24_regular
            ), 
            label: 'Sohbet'
        ),
        BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1 ? FluentIcons.people_team_24_filled : FluentIcons.people_team_24_regular
            ), 
            label: 'Grup'
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: friendRequestsCount > 0,
            label: Text(friendRequestsCount.toString()),
            child: Icon(
              _selectedIndex == 2 ? FluentIcons.person_24_filled : FluentIcons.person_24_regular
            ),
          ),
          label: 'Kişiler'
        ),
        BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3 ? FluentIcons.settings_24_filled : FluentIcons.settings_24_regular
            ), 
            label: 'Ayarlar'
        ),
      ],
    );
  }
}
