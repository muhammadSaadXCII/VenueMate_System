import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/notification_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Firestore structure:
//
//  chats/{chatId}
//    participants: [uid1, uid2]
//    participantNames: { uid1: "Ali", uid2: "Rehman Hussain" }
//    participantPhotos: { uid1: "https://...", uid2: "https://..." }
//    lastMessage: "Thanks!"
//    lastMessageTime: Timestamp
//    unreadCount: { uid1: 0, uid2: 2 }
//
//  chats/{chatId}/messages/{msgId}
//    text: "Hi there"
//    senderId: uid
//    createdAt: Timestamp
// ═══════════════════════════════════════════════════════════════════════════

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _uid = AuthService.currentUid ?? '';
  final _searchCtrl = TextEditingController();
  String _query = '';

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
    const searchBarColor = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Header ──────────────────────────────────────────────────────
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

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: searchBarColor,
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

            // ── Chat list ────────────────────────────────────────────────────
            Expanded(
              child:
                  _uid.isEmpty
                      ? _emptyState('Log in to see your messages.')
                      : StreamBuilder<QuerySnapshot>(
                        stream: _chatsStream,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF47C20),
                              ),
                            );
                          }
                          final docs = snap.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return _emptyState(
                              'No conversations yet.\nBook a venue to start chatting!',
                            );
                          }

                          // Apply search filter
                          final filtered =
                              _query.isEmpty
                                  ? docs
                                  : docs.where((d) {
                                    final data =
                                        d.data() as Map<String, dynamic>;
                                    final names = Map<String, dynamic>.from(
                                      data['participantNames'] ?? {},
                                    );
                                    final otherName =
                                        names.entries
                                                .firstWhere(
                                                  (e) => e.key != _uid,
                                                  orElse:
                                                      () => const MapEntry(
                                                        '',
                                                        '',
                                                      ),
                                                )
                                                .value
                                            as String;
                                    return otherName.toLowerCase().contains(
                                      _query,
                                    );
                                  }).toList();

                          if (filtered.isEmpty) {
                            return _emptyState('No chats match your search.');
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final data =
                                  filtered[i].data() as Map<String, dynamic>;
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
                                orElse: () => const MapEntry('', 'Unknown'),
                              );
                              final otherId = otherEntry.key;
                              final otherName = otherEntry.value as String;
                              final otherPhoto =
                                  photos[otherId] as String? ?? '';
                              final unread = (unreadMap[_uid] ?? 0) as int;

                              // Format last message time
                              final ts = data['lastMessageTime'] as Timestamp?;
                              final timeStr =
                                  ts != null ? _formatTime(ts.toDate()) : '';

                              return _ChatTile(
                                chatId: chatId,
                                currentUid: _uid,
                                otherName: otherName,
                                otherPhoto: otherPhoto,
                                otherId: otherId,
                                lastMessage:
                                    data['lastMessage'] as String? ?? '',
                                time: timeStr,
                                unreadCount: unread,
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
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
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Chat tile ──────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String chatId, currentUid, otherName, otherPhoto, otherId;
  final String lastMessage, time;
  final int unreadCount;

  const _ChatTile({
    required this.chatId,
    required this.currentUid,
    required this.otherName,
    required this.otherPhoto,
    required this.otherId,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    const badgeColor = Color(0xFFF47C20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Mark as read
            FirebaseFirestore.instance.collection('chats').doc(chatId).update({
              'unreadCount.$currentUid': 0,
            });
            AppNavigation.push(
              context,
              ChattingScreen(
                chatId: chatId,
                currentUid: currentUid,
                otherName: otherName,
                otherPhoto: otherPhoto,
                otherId: otherId,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                _Avatar(photoUrl: otherPhoto, name: otherName),
                const SizedBox(width: 15),
                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                // Time + unread badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    unreadCount > 0
                        ? Container(
                          width: 22,
                          height: 22,
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
                        : const SizedBox(height: 22),
                    const SizedBox(height: 6),
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

// ── Avatar widget ──────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String photoUrl, name;
  const _Avatar({required this.photoUrl, required this.name});

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
      width: 55,
      height: 55,
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
                  errorBuilder: (_, __, ___) => _initials(initials),
                ),
              )
              : _initials(initials),
    );
  }

  Widget _initials(String i) => Center(
    child: Text(
      i,
      style: const TextStyle(
        color: Color(0xFFF47C20),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  CHATTING SCREEN — live Firestore messages
// ══════════════════════════════════════════════════════════════════════════
class ChattingScreen extends StatefulWidget {
  final String chatId, currentUid, otherName, otherPhoto, otherId;

  const ChattingScreen({
    super.key,
    required this.chatId,
    required this.currentUid,
    required this.otherName,
    required this.otherPhoto,
    required this.otherId,
  });
  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
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
    // Mark messages as read when opening
    _db.collection('chats').doc(widget.chatId).update({
      'unreadCount.${widget.currentUid}': 0,
    });
  }

  Future<void> _onSend(ChatMessage message) async {
    final batch = _db.batch();

    // 1. Add message to sub-collection
    final msgRef =
        _db.collection('chats').doc(widget.chatId).collection('messages').doc();
    batch.set(msgRef, {
      'text': message.text,
      'senderId': widget.currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update chat metadata
    final chatRef = _db.collection('chats').doc(widget.chatId);
    batch.update(chatRef, {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      // Increment receiver's unread count
      'unreadCount.${widget.otherId}': FieldValue.increment(1),
      'unreadCount.${widget.currentUid}': 0,
    });

    await batch.commit();
    // Push notification to the other participant
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
            _Avatar(photoUrl: widget.otherPhoto, name: widget.otherName),
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
        builder: (context, snap) {
          final messages = snap.data ?? [];
          return DashChat(
            currentUser: _me,
            onSend: _onSend,
            messages: messages,
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
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  Helper: start or get a chat between two users
//  Call this when a Customer taps "Message" on a VenueDetailScreen
// ══════════════════════════════════════════════════════════════════════════
Future<String> getOrCreateChat({
  required String currentUid,
  required String currentName,
  required String currentPhoto,
  required String otherId,
  required String otherName,
  required String otherPhoto,
}) async {
  final db = FirebaseFirestore.instance;
  // Check if a chat already exists between these two users
  final existing =
      await db
          .collection('chats')
          .where('participants', arrayContains: currentUid)
          .get();

  for (final doc in existing.docs) {
    final participants = List<String>.from(doc.data()['participants'] ?? []);
    if (participants.contains(otherId)) return doc.id;
  }

  // Create a new chat
  final ref = db.collection('chats').doc();
  await ref.set({
    'participants': [currentUid, otherId],
    'participantNames': {currentUid: currentName, otherId: otherName},
    'participantPhotos': {currentUid: currentPhoto, otherId: otherPhoto},
    'lastMessage': '',
    'lastMessageTime': FieldValue.serverTimestamp(),
    'unreadCount': {currentUid: 0, otherId: 0},
  });
  return ref.id;
}
