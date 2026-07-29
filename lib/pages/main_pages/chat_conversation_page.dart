import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:chatapp/widget/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.subtitle,
    required this.avatarLabel,
    required this.isGroupChat,
  });

  final String chatId;
  final String title;
  final String subtitle;
  final String avatarLabel;
  final bool isGroupChat;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserEmail;
  String? _currentUserName;
  bool _isTyping = false;
  final Set<String> _locallyMarkedAsRead = {};
  
  String? _replyToText;
  String? _replyToSender;

  void _cancelReply() {
    setState(() {
      _replyToText = null;
      _replyToSender = null;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final currentUserEmail = await HelperFunction.getUserEmailSF();
    final currentUserName = await HelperFunction.getUserNameSF();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = currentUserEmail;
      _currentUserName = currentUserName ?? 'Me';
    });
    if (_currentUserEmail != null) {
      await _databaseService.setUserOnlineStatus(_currentUserEmail!, true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    if (_currentUserEmail != null) {
      _databaseService.setUserOnlineStatus(_currentUserEmail!, false);
      if (_isTyping) {
        _databaseService.setUserTypingStatus(widget.chatId, _currentUserEmail!, false);
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _setTypingStatus(false);
      if (_currentUserEmail != null) {
        _databaseService.setUserOnlineStatus(_currentUserEmail!, false);
      }
    } else {
      if (_currentUserEmail != null) {
        _databaseService.setUserOnlineStatus(_currentUserEmail!, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF24354E),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFE2D8),
              child: Text(
                widget.avatarLabel,
                style: const TextStyle(
                  color: Color(0xFFE46D4E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (widget.isGroupChat)
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8B8B8B)),
                      )
                    else
                      StreamBuilder<QuerySnapshot>(
                        stream: _databaseService.getUserStreamByEmail(widget.subtitle),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                            final userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                            final isOnline = userData['isOnline'] ?? false;
                            final lastSeen = userData['lastSeen'];
                            
                            String statusText = widget.subtitle; // Varsayılan: email
                            
                            if (isOnline) {
                              statusText = 'Çevrimiçi';
                            } else if (lastSeen != null) {
                              // Tarih hesaplama
                              final date = lastSeen.toDate();
                              final now = DateTime.now();
                              final difference = now.difference(date);
                              
                              if (difference.inMinutes < 1) {
                                statusText = 'Az önce görüldü';
                              } else if (difference.inMinutes < 60) {
                                statusText = 'Son görülme: ${difference.inMinutes} dakika önce';
                              } else if (difference.inHours < 24 && now.day == date.day) {
                                final timeStr = TimeOfDay.fromDateTime(date).format(context);
                                statusText = 'Son görülme: bugün $timeStr';
                              } else {
                                final timeStr = TimeOfDay.fromDateTime(date).format(context);
                                statusText = 'Son görülme: ${date.day}/${date.month}/${date.year} $timeStr';
                              }
                            }
                            
                            return Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12, 
                                color: isOnline ? Colors.green : const Color(0xFF8B8B8B),
                                fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }
                          return Text(
                            widget.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8B8B8B)),
                          );
                        },
                      ),
                  ],
                ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _showCallDialog(context, false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _showCallDialog(context, true),
          ),
        ],
      ),
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
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.isGroupChat
                    ? _databaseService.getGroupMessages(widget.chatId)
                    : _databaseService.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Mesajlar yüklenemedi'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz mesaj yok.\nİlk mesajı sen gönder!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8B8B8B)),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final messageId = messageDoc.id;
                      final data =
                          messageDoc.data() as Map<String, dynamic>;
                      final senderEmail =
                          data['senderEmail'] as String? ?? '';
                      final senderName =
                          data['senderName'] as String? ?? '';
                      final message = data['message'] as String? ?? '';
                      final fileUrl = data['fileUrl'] as String?;
                      final replyToText = data['replyToText'] as String?;
                      final replyToSender = data['replyToSender'] as String?;
                      final timestamp = data['timestamp'];
                      final readBy = (data['readBy'] as List<dynamic>? ?? [])
                          .cast<String>();
                      final reactions =
                          (data['reactions'] as Map<String, dynamic>? ?? {});
                      final edited = data['edited'] as bool? ?? false;
                      final timeText = timestamp is Timestamp
                          ? TimeOfDay.fromDateTime(timestamp.toDate())
                              .format(context)
                          : '';
                      final isMe = senderEmail == _currentUserEmail;

                      if (!isMe &&
                          !readBy.contains(_currentUserEmail) &&
                          !_locallyMarkedAsRead.contains(messageId)) {
                        _locallyMarkedAsRead.add(messageId);
                        _databaseService.markMessageAsRead(
                            widget.chatId,
                            messageId,
                            _currentUserEmail ?? '');
                      }

                      DateTime? currentDate = timestamp is Timestamp ? timestamp.toDate() : null;
                      DateTime? previousDate;
                      if (index < messages.length - 1) {
                        final prevDoc = messages[index + 1].data() as Map<String, dynamic>;
                        final prevTimestamp = prevDoc['timestamp'];
                        previousDate = prevTimestamp is Timestamp ? prevTimestamp.toDate() : null;
                      }

                      bool showDateSeparator = false;
                      if (currentDate != null) {
                        if (previousDate == null) {
                          showDateSeparator = true;
                        } else {
                          if (currentDate.year != previousDate.year ||
                              currentDate.month != previousDate.month ||
                              currentDate.day != previousDate.day) {
                            showDateSeparator = true;
                          }
                        }
                      }

                      Widget messageBubble = _MessageBubble(
                        text: message,
                        isMe: isMe,
                        time: timeText,
                        senderName: isMe ? 'Sen' : senderName,
                        fileUrl: fileUrl,
                        replyToText: replyToText,
                        replyToSender: replyToSender,
                        reactions: reactions,
                        messageId: messageId,
                        chatId: widget.chatId,
                        currentUserEmail: _currentUserEmail ?? '',
                        readBy: readBy,
                        edited: edited,
                        onReactionTap: (emoji) =>
                            _toggleReaction(messageId, emoji),
                        onDelete: isMe
                            ? () => _deleteMessage(messageId)
                            : null,
                        onEdit: isMe
                            ? () => _editMessage(messageId, message)
                            : null,
                        onSwipeToReply: () {
                          setState(() {
                            _replyToText = message;
                            _replyToSender = isMe ? 'Sen' : senderName;
                          });
                        },
                      );

                      if (showDateSeparator && currentDate != null) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDateSeparator(currentDate),
                                  style: const TextStyle(
                                    color: Color(0xFF8B8B8B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            messageBubble,
                          ],
                        );
                      }
                      return messageBubble;
                    },
                  );
                },
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getTypingUsers(widget.chatId),
              builder: (context, snapshot) {
                final typingUsers = snapshot.data?.docs
                        .map((doc) => doc.id)
                        .toList() ??
                    [];
                typingUsers
                    .removeWhere((email) => email == _currentUserEmail);
                if (typingUsers.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    '${typingUsers.first} yazıyor...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                );
              },
            ),
            if (_replyToText != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2D7CE).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE46D4E).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE46D4E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyToSender ?? '',
                            style: const TextStyle(
                              color: Color(0xFFE46D4E),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _replyToText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _cancelReply,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            _MessageComposer(
              controller: _messageController,
              onSend: _sendMessage,
              onTyping: _setTypingStatus,
              onImagePicked: _sendImageMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Bugün';
    if (checkDate == yesterday) return 'Dün';
    
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${date.day} ${months[date.month - 1]} ${date.year != now.year ? date.year : ''}'.trim();
  }

  // ── Reaksiyon ──
  Future<void> _toggleReaction(String messageId, String emoji) async {
    if (_currentUserEmail == null) return;
    try {
      await _databaseService.addMessageReaction(
          widget.chatId, messageId, _currentUserEmail!, emoji);
    } catch (_) {
      await _databaseService.removeMessageReaction(
          widget.chatId, messageId, _currentUserEmail!, emoji);
    }
  }

  // ── Yazma durumu ──
  Future<void> _setTypingStatus(bool isTyping) async {
    if (_currentUserEmail == null || isTyping == _isTyping) return;
    setState(() => _isTyping = isTyping);
    await _databaseService.setUserTypingStatus(
        widget.chatId, _currentUserEmail!, isTyping);
  }

  // ── Resim gönder (Storage devre dışı — Blaze plan gerekli) ──
  Future<void> _sendImageMessage() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Resim gönderme özelliği şu an devre dışı.\nFazlasını görmek için Firebase Blaze planına geçin.',
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

  // ── Mesaj sil ──
  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700]),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (widget.isGroupChat) {
      await _databaseService.deleteGroupMessage(
          widget.chatId, messageId);
    } else {
      await _databaseService.deleteChatMessage(
          widget.chatId, messageId);
    }
  }

  // ── Mesaj düzenle ──
  Future<void> _editMessage(String messageId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final newText = await showDialog<String>(
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
              Icon(FluentIcons.edit_24_filled, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Mesajı Düzenle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF24354E),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: modernTextInputDecoration(context).copyWith(
                  hintText: 'Yeni mesaj...',
                  prefixIcon: const Icon(FluentIcons.text_align_left_24_regular),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (newText == null || newText.isEmpty) return;
    if (widget.isGroupChat) {
      await _databaseService.editGroupMessage(
          widget.chatId, messageId, newText);
    } else {
      await _databaseService.editChatMessage(
          widget.chatId, messageId, newText);
    }
  }

  // ── Sesli/Görüntülü Arama ──
  void _showCallDialog(BuildContext context, bool isVideo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isVideo ? 'Görüntülü Arama' : 'Sesli Arama'),
        content: Text(
          '${widget.title} ile ${isVideo ? 'görüntülü' : 'sesli'} arama başlasın mı?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${isVideo ? 'Görüntülü' : 'Sesli'} arama başlıyor...'),
                ),
              );
            },
            child: const Text('Başla'),
          ),
        ],
      ),
    );
  }

  // ── Mesaj gönder ──
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final currentUserEmail = _currentUserEmail;
    final currentUserName = _currentUserName ?? 'Me';

    if (message.isEmpty || currentUserEmail == null) return;

    _messageController.clear();
    await _setTypingStatus(false);

    if (widget.isGroupChat) {
      await _databaseService.sendGroupMessage(
        groupId: widget.chatId,
        senderEmail: currentUserEmail,
        senderName: currentUserName,
        message: message,
        replyToText: _replyToText,
        replyToSender: _replyToSender,
      );
    } else {
      await _databaseService.sendChatMessage(
        chatRoomId: widget.chatId,
        senderEmail: currentUserEmail,
        senderName: currentUserName,
        message: message,
        replyToText: _replyToText,
        replyToSender: _replyToSender,
      );
    }
    
    _cancelReply();
  }
}

// ─────────────────────────────────────────────────────────
// MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderName,
    required this.fileUrl,
    this.replyToText,
    this.replyToSender,
    required this.reactions,
    required this.messageId,
    required this.chatId,
    required this.currentUserEmail,
    required this.readBy,
    required this.edited,
    required this.onReactionTap,
    this.onDelete,
    this.onEdit,
    this.onSwipeToReply,
  });

  final String text;
  final bool isMe;
  final String time;
  final String senderName;
  final String? fileUrl;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, dynamic> reactions;
  final String messageId;
  final String chatId;
  final String currentUserEmail;
  final List<String> readBy;
  final bool edited;
  final Function(String emoji) onReactionTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onSwipeToReply;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showReactions = false;
  final List<String> _emojis = ['👍', '❤️', '😂', '😢', '🔥', '👏'];

  void _showOptions(BuildContext context) {
    final actions = <Widget>[
      if (widget.onEdit != null)
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Düzenle'),
          onTap: () {
            Navigator.pop(context);
            widget.onEdit!();
          },
        ),
      if (widget.onDelete != null)
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Sil', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            widget.onDelete!();
          },
        ),
      ListTile(
        leading: const Icon(Icons.copy_outlined),
        title: const Text('Kopyala'),
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.text));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesaj panoya kopyalandı.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.emoji_emotions_outlined),
        title: const Text('Reaksiyon ekle'),
        onTap: () {
          Navigator.pop(context);
          setState(() => _showReactions = true);
        },
      ),
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: actions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment =
        widget.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = widget.isMe 
        ? Theme.of(context).colorScheme.primary 
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = widget.isMe 
        ? Colors.white 
        : (isDark ? Colors.white : const Color(0xFF24354E));
    final isRead = widget.readBy.isNotEmpty;

    return Align(
      alignment: alignment,
      child: widget.onSwipeToReply != null ? Dismissible(
        key: ValueKey(widget.messageId),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          widget.onSwipeToReply!();
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.reply, color: Colors.grey),
        ),
        child: _buildBubbleContent(isDark, color, textColor, isRead),
      ) : _buildBubbleContent(isDark, color, textColor, isRead),
    );
  }

  Widget _buildBubbleContent(bool isDark, Color color, Color textColor, bool isRead) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Column(
        crossAxisAlignment: widget.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
            if (_showReactions)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _emojis
                      .map((emoji) => GestureDetector(
                            onTap: () {
                              widget.onReactionTap(emoji);
                              setState(() => _showReactions = false);
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                gradient: widget.isMe ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ) : null,
                color: widget.isMe ? null : color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                  bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
                border: widget.isMe
                    ? null
                    : Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE46D4E),
                        ),
                      ),
                    ),
                  if (widget.replyToText != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: 30,
                            decoration: BoxDecoration(
                              color: widget.isMe ? Colors.white : const Color(0xFFE46D4E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.replyToSender ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isMe ? Colors.white : const Color(0xFFE46D4E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.replyToText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Resim
                  if (widget.fileUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.fileUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, e, st) => Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  if (widget.fileUrl != null)
                    const SizedBox(height: 4),
                  // Mesaj metni
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.edited)
                        Text(
                          'düzenlendi · ',
                          style: TextStyle(
                            color: widget.isMe
                                ? Colors.white54
                                : const Color(0xFF8B8B8B),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        widget.time,
                        style: TextStyle(
                          color: widget.isMe
                              ? Colors.white70
                              : const Color(0xFF8B8B8B),
                          fontSize: 11,
                        ),
                      ),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          // Mavi = okundu, gri = iletildi
                          color: isRead
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (widget.reactions.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.reactions.entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              child: Text(
                                '${entry.key} ${(entry.value as List).length}',
                                style:
                                    const TextStyle(fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// MESSAGE COMPOSER
// ─────────────────────────────────────────────────────────

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onTyping,
    required this.onImagePicked,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(bool) onTyping;
  final VoidCallback onImagePicked;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    widget.onTyping(widget.controller.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(FluentIcons.image_24_regular, color: Theme.of(context).colorScheme.primary),
              onPressed: widget.onImagePicked,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Mesaj yaz...',
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(FluentIcons.send_24_filled,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
