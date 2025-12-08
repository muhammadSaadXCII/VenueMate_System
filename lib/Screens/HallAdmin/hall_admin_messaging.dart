import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';

class HallAdminMessagingScreen extends StatelessWidget {
  const HallAdminMessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color searchBarColor = Color(0xFFF3F4F6);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    "Messages",
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search chats...",
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: const [
                  ChatTile(
                    name: "Waqar Yunus",
                    message: "Great I will arrive soon...",
                    time: "05:02",
                    unreadCount: 3,
                    avatarUrl:
                        "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80",
                  ),
                  ChatTile(
                    name: "Muhammad Ali",
                    message: "My order has not arrived yet",
                    time: "05:02",
                    unreadCount: 2,
                    avatarUrl:
                        "https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80",
                  ),
                  ChatTile(
                    name: "Arslan Umer",
                    message: "How are you doing?",
                    time: "12/21/2022",
                    unreadCount: 0,
                    avatarUrl:
                        "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String avatarUrl;

  const ChatTile({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    const Color badgeColor = Color(0xFFF47C20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppNavigation.push(
              context,
              ChattingScreen(username: name, avatarUrl: avatarUrl),
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
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        ),
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
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
                    if (unreadCount > 0)
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 22),

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

class ChattingScreen extends StatefulWidget {
  final String username;
  final String avatarUrl;

  const ChattingScreen({
    super.key,
    required this.username,
    required this.avatarUrl,
  });

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final ChatUser _hallAdmin = ChatUser(
    id: '1',
    firstName: 'Rehman',
    lastName: 'Hussain',
  );

  late ChatUser _otherUser;

  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _otherUser = ChatUser(
      id: '2',
      firstName: widget.username,
      profileImage: widget.avatarUrl,
    );

    _messages = [
      ChatMessage(
        text: "Hi! Is the hall available for 25th Nov?",
        user: _otherUser,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        text: "Yes, we have slots available for the evening.",
        user: _hallAdmin,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  void _onSend(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: "Thanks! I will proceed with the booking.",
              user: _otherUser,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    });
  }

  void _handlePhotoUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Photo Picker would open here")),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF47C20);

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
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.avatarUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: DashChat(
        currentUser: _hallAdmin,
        onSend: _onSend,
        messages: _messages,

        inputOptions: InputOptions(
          leading: [
            IconButton(
              icon: const Icon(Icons.photo, color: primaryOrange, size: 28),
              onPressed: _handlePhotoUpload,
            ),
          ],

          inputDecoration: InputDecoration(
            hintText: "Type a message...",
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
          sendButtonBuilder: (send) {
            return IconButton(
              icon: const Icon(Icons.send_rounded),
              color: primaryOrange,
              onPressed: send,
            );
          },
        ),

        messageOptions: MessageOptions(
          showOtherUsersAvatar: false,
          showTime: true,
          containerColor: const Color(0xFFF3F4F6),
          currentUserContainerColor: primaryOrange,
          textColor: Colors.black87,
          currentUserTextColor: Colors.white,
          timeFontSize: 10,
          messagePadding: const EdgeInsets.all(12),
          borderRadius: 16,
        ),
      ),
    );
  }
}
