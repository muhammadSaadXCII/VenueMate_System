import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';

const double _kMsgWebBreak = 950;

class HallAdminMessagingScreen extends StatefulWidget {
  const HallAdminMessagingScreen({super.key});
  @override
  State<HallAdminMessagingScreen> createState() =>
      _HallAdminMessagingScreenState();
}

class _HallAdminMessagingScreenState extends State<HallAdminMessagingScreen> {
  final String _uid = AuthService.currentUid ?? '';
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Web-only: tracks which chat is open in the right panel
  String? _activeChatId;
  String _activeName = '';
  String _activePhoto = '';
  String _activeOtherId = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> get _chatsStream =>
      FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: _uid)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kMsgWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT — two panel: list left, chat right
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          // Top bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            color: Colors.white,
            child: const Row(
              children: [
                Text(
                  'Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // Left — chat list panel
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged:
                                (v) => setState(() => _query = v.toLowerCase()),
                            decoration: const InputDecoration(
                              hintText: 'Search chats...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Divider(color: Colors.grey.shade100, height: 1),
                      Expanded(child: _buildChatList(isWeb: true)),
                    ],
                  ),
                ),

                // Right — chat panel or placeholder
                Expanded(
                  child:
                      _activeChatId != null
                          ? _WebChatPanel(
                            key: ValueKey(_activeChatId),
                            chatId: _activeChatId!,
                            currentUid: _uid,
                            otherName: _activeName,
                            otherPhoto: _activePhoto,
                            otherId: _activeOtherId,
                            onClose: () => setState(() => _activeChatId = null),
                          )
                          : _buildEmptyChatPlaceholder(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatPlaceholder() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF47C20).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 40,
                color: Color(0xFFF47C20),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a chat from the list to start messaging',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (unchanged)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33F59E54),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 26,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: Colors.grey.shade200,
              thickness: 1.5,
              indent: 20,
              endIndent: 20,
            ),
            Expanded(child: _buildChatList(isWeb: false)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  SHARED: chat list builder
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildChatList({required bool isWeb}) {
    if (_uid.isEmpty) return _emptyState('Log in to see your messages.');

    return StreamBuilder<QuerySnapshot>(
      stream: _chatsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF47C20)),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState(
            'No conversations yet.\nCustomers who book will appear here.',
          );
        }

        final filtered =
            _query.isEmpty
                ? docs
                : docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final names = Map<String, dynamic>.from(
                    data['participantNames'] ?? {},
                  );
                  final otherName =
                      names.entries
                              .firstWhere(
                                (e) => e.key != _uid,
                                orElse: () => const MapEntry('', ''),
                              )
                              .value
                          as String;
                  return otherName.toLowerCase().contains(_query);
                }).toList();

        if (filtered.isEmpty) return _emptyState('No chats match your search.');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            final chatId = filtered[i].id;
            final names = Map<String, dynamic>.from(
              data['participantNames'] ?? {},
            );
            final photos = Map<String, dynamic>.from(
              data['participantPhotos'] ?? {},
            );
            final unreadMap = Map<String, dynamic>.from(
              data['unreadCount'] ?? {},
            );

            final otherEntry = names.entries.firstWhere(
              (e) => e.key != _uid,
              orElse: () => const MapEntry('', 'Customer'),
            );
            final otherId = otherEntry.key;
            final otherName = otherEntry.value as String;
            final otherPhoto = photos[otherId] as String? ?? '';
            final unread = (unreadMap[_uid] ?? 0) as int;
            final ts = data['lastMessageTime'] as Timestamp?;
            final timeStr = ts != null ? _formatTime(ts.toDate()) : '';
            final isActiveOnWeb = isWeb && _activeChatId == chatId;

            return _ChatTile(
              chatId: chatId,
              currentUid: _uid,
              otherName: otherName,
              otherPhoto: otherPhoto,
              otherId: otherId,
              lastMessage: data['lastMessage'] as String? ?? '',
              time: timeStr,
              unreadCount: unread,
              isHighlighted: isActiveOnWeb,
              onTap:
                  isWeb
                      ? () {
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .update({'unreadCount.$_uid': 0});
                        setState(() {
                          _activeChatId = chatId;
                          _activeName = otherName;
                          _activePhoto = otherPhoto;
                          _activeOtherId = otherId;
                        });
                      }
                      : () {
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .update({'unreadCount.$_uid': 0});
                        AppNavigation.push(
                          context,
                          _ChattingScreen(
                            chatId: chatId,
                            currentUid: _uid,
                            otherName: otherName,
                            otherPhoto: otherPhoto,
                            otherId: otherId,
                          ),
                        );
                      },
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], height: 1.5),
        ),
      ],
    ),
  );

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WEB CHAT PANEL — inline right-side chat (no push navigation)
// ══════════════════════════════════════════════════════════════════════════════
class _WebChatPanel extends StatefulWidget {
  final String chatId, currentUid, otherName, otherPhoto, otherId;
  final VoidCallback onClose;

  const _WebChatPanel({
    super.key,
    required this.chatId,
    required this.currentUid,
    required this.otherName,
    required this.otherPhoto,
    required this.otherId,
    required this.onClose,
  });

  @override
  State<_WebChatPanel> createState() => _WebChatPanelState();
}

class _WebChatPanelState extends State<_WebChatPanel> {
  late final ChatUser _me;
  late final ChatUser _other;
  final _db = FirebaseFirestore.instance;
  String _senderName = 'VenueMate User';

  Stream<List<ChatMessage>> get _msgStream => _db
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) {
              final data = d.data();
              final isMe = data['senderId'] == widget.currentUid;
              return ChatMessage(
                text: data['text'] ?? '',
                user: isMe ? _me : _other,
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList(),
      );

  @override
  void initState() {
    super.initState();
    _me = ChatUser(id: widget.currentUid);
    _other = ChatUser(
      id: widget.otherId,
      firstName: widget.otherName,
      profileImage: widget.otherPhoto.isNotEmpty ? widget.otherPhoto : null,
    );
    // Fetch sender's display name for notifications
    _db.collection('users').doc(widget.currentUid).get().then((doc) {
      if (doc.exists) {
        final name = (doc.data()?['name'] as String?) ?? '';
        if (name.isNotEmpty && mounted) setState(() => _senderName = name);
      }
    });
    _db.collection('chats').doc(widget.chatId).update({
      'unreadCount.${widget.currentUid}': 0,
    });
  }

  Future<void> _onSend(ChatMessage message) async {
    final batch = _db.batch();
    final msgRef =
        _db.collection('chats').doc(widget.chatId).collection('messages').doc();
    batch.set(msgRef, {
      'text': message.text,
      'senderId': widget.currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final chatRef = _db.collection('chats').doc(widget.chatId);
    batch.update(chatRef, {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.${widget.otherId}': FieldValue.increment(1),
      'unreadCount.${widget.currentUid}': 0,
    });
    await batch.commit();
    unawaited(
      NotificationService.sendNewMessage(
        recipientUid: widget.otherId,
        conversationId: widget.chatId,
        senderName: _senderName,
        messagePreview: message.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFF47C20);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Chat header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                _Avatar(
                  photoUrl: widget.otherPhoto,
                  name: widget.otherName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.otherName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Customer',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onClose,
                  tooltip: 'Close chat',
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _msgStream,
              builder:
                  (context, snap) => DashChat(
                    currentUser: _me,
                    onSend: _onSend,
                    messages: snap.data ?? [],
                    inputOptions: InputOptions(
                      inputDecoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        fillColor: const Color(0xFFF3F4F6),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      alwaysShowSend: true,
                      sendButtonBuilder:
                          (send) => IconButton(
                            icon: const Icon(Icons.send_rounded),
                            color: primaryOrange,
                            onPressed: send,
                          ),
                    ),
                    messageOptions: const MessageOptions(
                      showOtherUsersAvatar: false,
                      showTime: true,
                      containerColor: Color(0xFFF3F4F6),
                      currentUserContainerColor: primaryOrange,
                      textColor: Colors.black87,
                      currentUserTextColor: Colors.white,
                      timeFontSize: 10,
                      messagePadding: EdgeInsets.all(12),
                      borderRadius: 16,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHAT TILE
// ══════════════════════════════════════════════════════════════════════════════
class _ChatTile extends StatelessWidget {
  final String chatId, currentUid, otherName, otherPhoto, otherId;
  final String lastMessage, time;
  final int unreadCount;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ChatTile({
    required this.chatId,
    required this.currentUid,
    required this.otherName,
    required this.otherPhoto,
    required this.otherId,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    const badgeColor = Color(0xFFF47C20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isHighlighted
                      ? const Color(0xFFF47C20).withOpacity(0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isHighlighted
                      ? Border.all(
                        color: const Color(0xFFF47C20).withOpacity(0.2),
                      )
                      : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(photoUrl: otherPhoto, name: otherName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    unreadCount > 0
                        ? Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        : const SizedBox(height: 20),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: unreadCount > 0 ? badgeColor : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MOBILE CHATTING SCREEN (push navigation on mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _ChattingScreen extends StatefulWidget {
  final String chatId, currentUid, otherName, otherPhoto, otherId;
  const _ChattingScreen({
    required this.chatId,
    required this.currentUid,
    required this.otherName,
    required this.otherPhoto,
    required this.otherId,
  });
  @override
  State<_ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<_ChattingScreen> {
  late final ChatUser _me;
  late final ChatUser _other;
  final _db = FirebaseFirestore.instance;
  String _senderName = 'VenueMate User';

  Stream<List<ChatMessage>> get _msgStream => _db
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) {
              final data = d.data();
              final isMe = data['senderId'] == widget.currentUid;
              return ChatMessage(
                text: data['text'] ?? '',
                user: isMe ? _me : _other,
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList(),
      );

  @override
  void initState() {
    super.initState();
    _me = ChatUser(id: widget.currentUid);
    _other = ChatUser(
      id: widget.otherId,
      firstName: widget.otherName,
      profileImage: widget.otherPhoto.isNotEmpty ? widget.otherPhoto : null,
    );
    // Fetch sender's display name for notifications
    _db.collection('users').doc(widget.currentUid).get().then((doc) {
      if (doc.exists) {
        final name = (doc.data()?['name'] as String?) ?? '';
        if (name.isNotEmpty && mounted) setState(() => _senderName = name);
      }
    });
    _db.collection('chats').doc(widget.chatId).update({
      'unreadCount.${widget.currentUid}': 0,
    });
  }

  Future<void> _onSend(ChatMessage message) async {
    final batch = _db.batch();
    final msgRef =
        _db.collection('chats').doc(widget.chatId).collection('messages').doc();
    batch.set(msgRef, {
      'text': message.text,
      'senderId': widget.currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final chatRef = _db.collection('chats').doc(widget.chatId);
    batch.update(chatRef, {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.${widget.otherId}': FieldValue.increment(1),
      'unreadCount.${widget.currentUid}': 0,
    });
    await batch.commit();
    unawaited(
      NotificationService.sendNewMessage(
        recipientUid: widget.otherId,
        conversationId: widget.chatId,
        senderName: _senderName,
        messagePreview: message.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFF47C20);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _Avatar(
              photoUrl: widget.otherPhoto,
              name: widget.otherName,
              size: 38,
            ),
            const SizedBox(width: 12),
            Text(
              widget.otherName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: _msgStream,
        builder:
            (context, snap) => DashChat(
              currentUser: _me,
              onSend: _onSend,
              messages: snap.data ?? [],
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  fillColor: const Color(0xFFF3F4F6),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                alwaysShowSend: true,
                sendButtonBuilder:
                    (send) => IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: primaryOrange,
                      onPressed: send,
                    ),
              ),
              messageOptions: const MessageOptions(
                showOtherUsersAvatar: false,
                showTime: true,
                containerColor: Color(0xFFF3F4F6),
                currentUserContainerColor: primaryOrange,
                textColor: Colors.black87,
                currentUserTextColor: Colors.white,
                timeFontSize: 10,
                messagePadding: EdgeInsets.all(12),
                borderRadius: 16,
              ),
            ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED AVATAR WIDGET
// ══════════════════════════════════════════════════════════════════════════════
class _Avatar extends StatelessWidget {
  final String photoUrl, name;
  final double size;
  const _Avatar({required this.photoUrl, required this.name, this.size = 55});

  @override
  Widget build(BuildContext context) {
    final initials =
        name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .map((w) => w[0].toUpperCase())
                .take(2)
                .join()
            : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.shade50,
      ),
      child:
          photoUrl.isNotEmpty
              ? ClipOval(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials(initials, size),
                ),
              )
              : _initials(initials, size),
    );
  }

  Widget _initials(String i, double sz) => Center(
    child: Text(
      i,
      style: TextStyle(
        color: const Color(0xFFF47C20),
        fontWeight: FontWeight.bold,
        fontSize: sz * 0.32,
      ),
    ),
  );
}
